import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vietmall/models/category_model.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/product/product_list_screen.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy danh mục (real-time)
  Stream<QuerySnapshot> getCategories() {
    return _firestore.collection('categories').orderBy('name').snapshots();
  }

  // Lấy danh mục (một lần)
  Future<List<CategoryModel>> getCategoriesList() async {
    QuerySnapshot snapshot = await _firestore.collection('categories').orderBy(
        'name').get();
    return snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc))
        .toList();
  }

  // Cập nhật các hàm lấy sản phẩm để lọc ra các sản phẩm đã ẩn
  Stream<QuerySnapshot> getRecentProducts({int limit = 10}) {
    return _firestore
        .collection('products')
        .where('isHidden', isEqualTo: false) // Lọc
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Lấy thông tin chi tiết một sản phẩm
  Future<DocumentSnapshot> getProductById(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  // Lấy các sản phẩm khác của cùng người bán
  Stream<QuerySnapshot> getOtherProductsFromSeller(String sellerId,
      String currentProductId) {
    return _firestore
        .collection('products')
        .where('isHidden', isEqualTo: false)
        .where('sellerId', isEqualTo: sellerId)
        .where(FieldPath.documentId, isNotEqualTo: currentProductId)
        .limit(10)
        .snapshots();
  }

  // Lấy thông tin người dùng
  Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  // Lọc và sắp xếp sản phẩm
  Stream<QuerySnapshot> getFilteredProducts({
    String? categoryId,
    String? searchQuery,
    PriceSortOption sortOption = PriceSortOption.none,
  }) {
    Query query = _firestore.collection('products').where('isHidden', isEqualTo: false);

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (searchQuery != null) {
      query = query
          .where('title', isGreaterThanOrEqualTo: searchQuery)
          .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff')
          .orderBy('title');
    }

    switch (sortOption) {
      case PriceSortOption.lowToHigh:
        query = query.orderBy('price', descending: false);
        break;
      case PriceSortOption.highToLow:
        query = query.orderBy('price', descending: true);
        break;
      case PriceSortOption.none:
      default:
        query = query.orderBy('createdAt', descending: true);
        break;
    }

    return query.snapshots();
  }

  // Hàm mới để ẩn/hiện tin
  Future<void> toggleProductVisibility(String productId,
      bool currentStatus) async {
    await _firestore.collection('products').doc(productId).update(
        {'isHidden': !currentStatus});
  }

  // --- Chức năng Giỏ hàng ---
  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final cartItemRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('cart')
        .doc(product.id);

    final doc = await cartItemRef.get();

    if (doc.exists) {
      await cartItemRef.update({'quantity': FieldValue.increment(quantity)});
    } else {
      await cartItemRef.set({
        'productId': product.id,
        'title': product.title,
        'price': product.price,
        'imageUrl': product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        'sellerId': product.sellerId,
        'sellerName': product.sellerName,
        'quantity': quantity,
        'addedAt': Timestamp.now(),
      });
    }
  }

  Stream<QuerySnapshot> getCartItems() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  Future<void> updateCartItemQuantity(String cartItemId,
      int newQuantity) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('cart')
        .doc(cartItemId)
        .update({'quantity': newQuantity});
  }

  Future<void> removeCartItems(List<String> cartItemIds) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final batch = _firestore.batch();
    for (String id in cartItemIds) {
      final docRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('cart')
          .doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  // Tạo đơn hàng mới
  Future<void> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required Map<String, String> shippingAddress,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Lấy danh sách ID của tất cả người bán trong đơn hàng
    final sellerIds = items.map((item) => item['sellerId'] as String).toSet().toList();

    final orderRef = _firestore.collection('orders').doc();

    await orderRef.set({
      'orderId': orderRef.id,
      'userId': currentUser.uid, // ID người mua
      'sellerIds': sellerIds, // Danh sách ID người bán
      'items': items,
      'totalPrice': totalPrice,
      'shippingAddress': shippingAddress,
      'status': 'Đang xử lý',
      'createdAt': Timestamp.now(),
    });

    final cartItemIds = items.map((item) => item['productId'] as String).toList();
    await removeCartItems(cartItemIds);
  }
  // Lấy danh sách đơn bán của bạn
  Stream<QuerySnapshot> getSalesOrders(List<String> statuses) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('orders')
        .where('sellerIds', arrayContains: currentUser.uid)
        .where('status', whereIn: statuses)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Lấy danh sách đơn hàng theo trạng thái
  Stream<QuerySnapshot> getOrders(List<String> statuses) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    Query query = _firestore
        .collection('orders')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true);

    // Chỉ filter status nếu có truyền
    if (statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }

    return query.snapshots();
  }

  // Hủy đơn hàng
  Future<void> cancelOrder(String orderId) async {
    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Đã hủy'});
  }

  // Lấy danh sách sản phẩm của người dùng hiện tại
  Stream<QuerySnapshot> getMyProducts() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Cập nhật sản phẩm
  Future<String?> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'title': title,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'isHidden': false,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Xóa sản phẩm
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    // Tùy chọn: Xóa cả bài đăng trên feed nếu có
    QuerySnapshot feedPost = await _firestore.collection('feed_posts').where(
        'productId', isEqualTo: productId).get();
    for (var doc in feedPost.docs) {
      await doc.reference.delete();
    }
  }

  // --- Chức năng Yêu thích ---
  Stream<bool> isFavorite(String productId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('favorites')
        .doc(productId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      // nếu document tồn tại và không bị ẩn thì mới coi là favorite
      return snapshot.exists && (data?['isHidden'] == false);
    });
  }

  Future<void> toggleFavoriteStatus(ProductModel product) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) return;

    final favoriteRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('favorites')
        .doc(product.id);

    final doc = await favoriteRef.get();

    if (doc.exists) {
      // toggle trạng thái isHidden
      final currentHidden = doc.data()?['isHidden'] ?? false;
      await favoriteRef.update({
        'isHidden': !currentHidden,
        'savedAt': Timestamp.now(),
      });
    } else {
      await favoriteRef.set({
        'title': product.title,
        'price': product.price,
        'imageUrls': product.imageUrls,
        'sellerId': product.sellerId,
        'sellerName': product.sellerName,
        'description': product.description,
        'createdAt': product.createdAt,
        'savedAt': Timestamp.now(),
        'isHidden': false, // mặc định chưa ẩn
      });
    }
  }

  Stream<QuerySnapshot> getFavoriteProducts() {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('favorites')
        .where('isHidden', isEqualTo: false)
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  // Lấy danh sách đánh giá của một sản phẩm
  Stream<QuerySnapshot> getReviews(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Thêm một đánh giá mới
  Future<void> addReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) return;

    await _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .add({
      'rating': rating,
      'comment': comment,
      'userId': currentUser.uid,
      'userName': currentUser.displayName ?? 'Người dùng',
      'createdAt': Timestamp.now(),
    });
  }
  // --- Chức năng Hồ sơ Công khai & Theo dõi ---
  Future<void> updateUserProfile({
    required String fullName,
    required DateTime birthDate,
    required String address,
    required String avatarUrl,
    required String coverUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await currentUser.updateDisplayName(fullName);
    await _firestore.collection('users').doc(currentUser.uid).update({
      'fullName': fullName,
      'birthDate': Timestamp.fromDate(birthDate),
      'address': address,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
    });
  }
  // Lấy thông tin chi tiết của một người dùng
  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Stream<QuerySnapshot> getProductsBySeller(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<int> getFollowerCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<int> getFollowingCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<bool> isFollowing(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(otherUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> toggleFollowStatus(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) return;

    final followingRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(otherUserId);

    final followerRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('followers')
        .doc(currentUser.uid);

    final doc = await followingRef.get();
    final batch = _firestore.batch();

    if (doc.exists) {
      batch.delete(followingRef);
      batch.delete(followerRef);
    } else {
      batch.set(followingRef, {'followedAt': Timestamp.now()});
      batch.set(followerRef, {'followedAt': Timestamp.now()});
    }

    await batch.commit();
  }
  //xoa
  Future<void> deleteAllUserData(String userId) async {
    final batch = _firestore.batch();

    // 1️⃣ Xóa document chính của user
    final userDoc = _firestore.collection('users').doc(userId);
    batch.delete(userDoc);

    // 2️⃣ Xóa giỏ hàng
    final cartSnapshot = await userDoc.collection('cart').get();
    for (var doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3️⃣ Xóa favorites
    final favSnapshot = await userDoc.collection('favorites').get();
    for (var doc in favSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 4️⃣ Xóa followers
    final followersSnapshot = await userDoc.collection('followers').get();
    for (var doc in followersSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 5️⃣ Xóa following
    final followingSnapshot = await userDoc.collection('following').get();
    for (var doc in followingSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 6️⃣ Xóa products của user
    final productsSnapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: userId)
        .get();
    for (var doc in productsSnapshot.docs) {
      // Xóa sản phẩm trên feed_posts nếu có
      final feedSnapshot = await _firestore
          .collection('feed_posts')
          .where('productId', isEqualTo: doc.id)
          .get();
      for (var feedDoc in feedSnapshot.docs) {
        batch.delete(feedDoc.reference);
      }
      batch.delete(doc.reference);
    }

    // 7️⃣ Xóa đơn hàng của user
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in ordersSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Commit batch
    await batch.commit();

    // 8️⃣ Xóa user trên Authentication
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      await currentUser.delete();
    }
  }
// --- Chức năng Dạo (Feed) ---
  Stream<QuerySnapshot> getFeedPosts() {
    return _firestore
        .collection('feed_posts')
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- Chức năng Đăng tin ---
  Future<String?> createProduct({
    required String title,
    required String description,
    required double price,
    required List<String> imageUrls,
    required String sellerId,
    required String sellerName,
    required String categoryId,
    required String categoryName,
    required bool postToFeed,
  }) async {
    try {
      final newProductRef = _firestore.collection('products').doc();

      await newProductRef.set({
        'title': title,
        'description': description,
        'price': price,
        'imageUrls': imageUrls,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'createdAt': Timestamp.now(),
        'isHidden': false, // ✅ thêm mặc định
      });

      if (postToFeed) {
        await _firestore.collection('feed_posts').add({
          'productId': newProductRef.id,
          'title': title,
          'description': description,
          'price': price,
          'imageUrls': imageUrls,
          'sellerId': sellerId,
          'sellerName': sellerName,
          'createdAt': Timestamp.now(),
          'isHidden': false, // ✅ thêm mặc định
        });
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
