import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final List<String> imageUrls;
  final Timestamp createdAt;
  final String sellerId;
  final String sellerName;

  final String categoryId;
  final String categoryName;
  final bool isHidden;
  final String status;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.createdAt,
    required this.sellerId,
    required this.sellerName,
    required this.categoryId,
    required this.categoryName,
    required this.isHidden,
    required this.status,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? 'Không có mô tả chi tiết.',
      price: (data['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      isHidden: data['isHidden'] ?? false,
        status: data['status'] ?? 'approved'
    );
  }

  // Factory mới để chuyển đổi từ Map (dữ liệu của feed post)
  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      id: data['productId'] ?? '', // Feed post dùng 'productId'
      title: data['title'] ?? '',
      description: data['description'] ?? 'Không có mô tả chi tiết.',
      price: (data['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      isHidden: data['isHidden'] ?? false,
        status: data['status'] ?? 'approved'
    );
  }
}