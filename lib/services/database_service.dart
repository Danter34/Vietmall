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
    QuerySnapshot snapshot = await _firestore.collection('categories').orderBy('name').get();
    return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
  }

  // Lấy sản phẩm mới nhất
  Stream<QuerySnapshot> getRecentProducts({int limit = 10}) {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Lấy thông tin chi tiết một sản phẩm
  Future<DocumentSnapshot> getProductById(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  // Lấy các sản phẩm khác của cùng người bán
  Stream<QuerySnapshot> getOtherProductsFromSeller(String sellerId, String currentProductId) {
    return _firestore
        .collection('products')
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
    Query query = _firestore.collection('products');

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

  // --- Chức năng Yêu thích ---
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

  // --- Chức năng Dạo (Feed) ---
  Stream<QuerySnapshot> getFeedPosts() {
    return _firestore
        .collection('feed_posts')
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
        });
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
