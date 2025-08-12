import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vietmall/models/category_model.dart';
import 'package:vietmall/models/product_model.dart';
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getCategories() {
    return _firestore.collection('categories').orderBy('name').snapshots();
  }

  Stream<QuerySnapshot> getRecentProducts({int limit = 10}) {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<DocumentSnapshot> getProductById(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  Future<List<CategoryModel>> getCategoriesList() async {
    QuerySnapshot snapshot = await _firestore.collection('categories').orderBy('name').get();
    return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
  }

  Stream<QuerySnapshot> getProductsByCategory(String categoryId) {
    return _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Lấy danh sách sản phẩm theo tên (cho chức năng tìm kiếm)
  Stream<QuerySnapshot> searchProductsByName(String query) {
    return _firestore
        .collection('products')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }
  Stream<QuerySnapshot> getOtherProductsFromSeller(String sellerId, String currentProductId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .where(FieldPath.documentId, isNotEqualTo: currentProductId)
        .limit(10)
        .snapshots();
  }
  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final cartItemRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('cart')
        .doc(product.id);

    await cartItemRef.set({
      'productId': product.id,
      'title': product.title,
      'price': product.price,
      'imageUrl': product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
      'sellerName': product.sellerName,
      'quantity': quantity,
      'addedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Lấy các sản phẩm trong giỏ hàng
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

  // Cập nhật số lượng
  Future<void> updateCartItemQuantity(String cartItemId, int newQuantity) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('cart')
        .doc(cartItemId)
        .update({'quantity': newQuantity});
  }

  // Xóa các sản phẩm khỏi giỏ hàng
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
  // Kiểm tra xem sản phẩm có trong danh sách yêu thích không
  Stream<bool> isFavorite(String productId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('favorites')
        .doc(productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Thêm/Xóa sản phẩm khỏi danh sách yêu thích
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
      await favoriteRef.delete();
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
      });
    }
  }

  // Lấy danh sách sản phẩm yêu thích
  Stream<QuerySnapshot> getFavoriteProducts() {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('favorites')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }


  // Lấy danh sách các bài đăng trên feed
  Stream<QuerySnapshot> getFeedPosts() {
    return _firestore
        .collection('feed_posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Hàm đăng sản phẩm mới (ĐÃ CẬP NHẬT)
  Future<String?> createProduct({
    required String title,
    required String description,
    required double price,
    required List<String> imageUrls,
    required String sellerId,
    required String sellerName,
    required String categoryId,
    required String categoryName,
    required bool postToFeed, // Thêm
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
      });

      // Nếu người dùng chọn đăng lên feed
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
        });
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
