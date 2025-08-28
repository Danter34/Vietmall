import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vietmall/models/category_model.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/product/product_list_screen.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==== THÊM HÀM THÔNG BÁO MỚI ====
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'type': type,
      'data': data ?? {},
    });
  }

  // Stream đếm số thông báo chưa đọc
  Stream<int> getUnreadNotificationCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Đánh dấu tất cả thông báo chưa đọc là đã đọc
  Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final unreadDocs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in unreadDocs.docs) {
      // Sử dụng try-catch để cập nhật từng tài liệu
      try {
        await doc.reference.update({'read': true});
      } catch (e) {
        // In lỗi ra để kiểm tra
        print('Lỗi khi cập nhật tài liệu ${doc.id}: $e');
      }
    }
  }
  // ==== KẾT THÚC THÊM HÀM THÔNG BÁO MỚI ====

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
        .where('status', isEqualTo: 'approved')
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
        .where('status', isEqualTo: 'approved')
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
    Query query = _firestore.collection('products').where('status', isEqualTo: 'approved').where('isHidden', isEqualTo: false);

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

    // ==== THÊM LOGIC TẠO THÔNG BÁO CHO ĐƠN HÀNG MỚI ====
    // Tạo thông báo cho người mua
    await createNotification(
      userId: currentUser.uid,
      title: '🛒 Đơn hàng đã đặt thành công!',
      body: 'Đơn hàng của bạn đã được ghi nhận. Chúng tôi sẽ xử lý sớm.',
      type: 'order',
      data: {'orderId': orderRef.id},
    );

    // Tạo thông báo cho từng người bán
    final Map<String, List<String>> sellerProductMap = {};
    for (var item in items) {
      final sellerId = item['sellerId'] as String;
      if (!sellerProductMap.containsKey(sellerId)) {
        sellerProductMap[sellerId] = [];
      }
      sellerProductMap[sellerId]!.add(item['title'] as String);
    }

    for (var sellerId in sellerProductMap.keys) {
      await createNotification(
        userId: sellerId,
        title: '🔔 Có đơn hàng mới!',
        body: 'Bạn có một đơn hàng mới từ khách hàng.',
        type: 'order',
        data: {'orderId': orderRef.id},
      );
    }
    const adminId = 'O83stqwhkOee5NebIGjqFlRCoAh1';

    await createNotification(
      userId: adminId,
      title: '📦 Đơn hàng mới!',
      body: 'Một đơn hàng mới #${orderRef.id} đã được đặt.',
      type: 'admin_action',
      data: {'orderId': orderRef.id, 'userId': currentUser.uid},
    );
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
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    final orderData = orderDoc.data() as Map<String, dynamic>;
    final userId = orderData['userId'] as String;
    final sellerIds = List<String>.from(orderData['sellerIds']);

    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Đã hủy'});

    // ==== THÊM LOGIC TẠO THÔNG BÁO CHO ĐƠN HÀNG BỊ HỦY ====
    // Tạo thông báo cho người mua (người hủy)
    await createNotification(
      userId: userId,
      title: '💔 Đơn hàng đã hủy thành công!',
      body: 'Đơn hàng #${orderId} của bạn đã được hủy.',
      type: 'order',
      data: {'orderId': orderId},
    );

    // Tạo thông báo cho người bán
    for (var sellerId in sellerIds) {
      await createNotification(
        userId: sellerId,
        title: '💔 Đơn hàng đã bị hủy!',
        body: 'Khách hàng đã hủy đơn hàng #${orderId} của bạn.',
        type: 'order',
        data: {'orderId': orderId},
      );
    }
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
  //Banner
  Stream<QuerySnapshot<Map<String, dynamic>>> streamBanners() {
    return _firestore
        .collection('banners')
        .orderBy('createdAt', descending: true)
        .snapshots();
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

    // ==== THÊM LOGIC TẠO THÔNG BÁO KHI LƯU TIN ====
    if (!doc.exists) {
      await createNotification(
        userId: currentUser.uid,
        title: '⭐️ Đã lưu tin thành công!',
        body: 'Tin đăng "${product.title}" đã được lưu vào danh sách yêu thích của bạn.',
        type: 'favorite',
        data: {'productId': product.id},
      );
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
    // Các tham số cũ
    required String fullName,
    required DateTime birthDate,
    required String address, // Giữ lại để lưu địa chỉ đầy đủ
    required String avatarUrl,
    required String coverUrl,

    // Các tham số mới cho địa chỉ chi tiết
    required String province,
    required String district,
    required String ward,
    required String street,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Cập nhật tên hiển thị trong Authentication
    await currentUser.updateDisplayName(fullName);

    // Cập nhật tất cả các trường trong document Firestore
    await _firestore.collection('users').doc(currentUser.uid).update({
      'fullName': fullName,
      'birthDate': Timestamp.fromDate(birthDate),
      'address': address, // Địa chỉ đầy đủ
      'province': province, // Tỉnh/Thành
      'district': district, // Quận/Huyện
      'ward': ward,         // Phường/Xã
      'street': street,     // Đường/Số nhà
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
        .where('status', isEqualTo: 'approved')
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

    // 8️⃣ Xóa notifications của user
    final notificationsSnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in notificationsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Commit batch
    await batch.commit();

    // 9️⃣ Xóa user trên Authentication
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      await currentUser.delete();
    }
  }
// --- Chức năng Dạo (Feed) ---
  Stream<QuerySnapshot> getFeedPosts() {
    return _firestore
        .collection('feed_posts')
        .where('status', isEqualTo: 'approved')
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
        'isHidden': false,
        'status': 'pending',
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
          'isHidden': false,
          'status': 'pending',
        });
      }


      const adminId = 'O83stqwhkOee5NebIGjqFlRCoAh1'; // Replace with the actual Admin's UID

      await createNotification(
        userId: adminId,
        title: '📝 Có Đơn hàng mới cần được duyệt',
        body: 'A new post titled "${title}" has been submitted and is pending review.',
        type: 'admin_action',
        data: {'productId': newProductRef.id},
      );


      return null;
    } catch (e) {
      // It's good practice to log the error to the console
      print('Error creating product: $e');
      return e.toString();
    }
  }
}