import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vietmall/models/category_model.dart';
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Hàm đăng sản phẩm mới (ĐÃ CẬP NHẬT)
  Future<String?> createProduct({
    required String title,
    required String description,
    required double price,
    required List<String> imageUrls,
    required String sellerId,
    required String sellerName,
    required String categoryId, // Thêm
    required String categoryName, // Thêm
  }) async {
    try {
      await _firestore.collection('products').add({
        'title': title,
        'description': description,
        'price': price,
        'imageUrls': imageUrls,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'categoryId': categoryId, // Thêm
        'categoryName': categoryName, // Thêm
        'createdAt': Timestamp.now(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
