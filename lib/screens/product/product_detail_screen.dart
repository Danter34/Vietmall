import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/chat/chat_room_screen.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/services/database_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: _databaseService.getProductById(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không tìm thấy sản phẩm."));
          }

          final product = ProductModel.fromFirestore(snapshot.data!);

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(product),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildSellerInfo(product.sellerId),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        "Mô tả chi tiết",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<DocumentSnapshot>(
        future: _databaseService.getProductById(widget.productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final product = ProductModel.fromFirestore(snapshot.data!);
          return _buildBottomBar(product);
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(ProductModel product) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      backgroundColor: AppColors.primaryRed,
      flexibleSpace: FlexibleSpaceBar(
        background: product.imageUrls.isNotEmpty
            ? Image.network(
          product.imageUrls.first,
          fit: BoxFit.cover,
          errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported, color: AppColors.grey, size: 100),
        )
            : Container(color: AppColors.greyLight, child: const Icon(Icons.image_not_supported, color: AppColors.grey, size: 100)),
      ),
    );
  }

  Widget _buildSellerInfo(String sellerId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _databaseService.getUserById(sellerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(title: Text("Đang tải thông tin người bán..."));
        }
        final sellerData = snapshot.data!.data() as Map<String, dynamic>;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryRed,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            sellerData['fullName'] ?? 'Người bán',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text("Xem trang"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    final authService = AuthService();
    final bool isMyProduct = authService.currentUser?.uid == product.sellerId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: isMyProduct
            ? [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Ẩn tin
              },
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text("Ẩn tin"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(color: AppColors.primaryRed, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Quản lý tin
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text("Quản lý tin"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]
            : [
          // Đổi vị trí — đưa Nhắn tin lên trước
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (authService.currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vui lòng đăng nhập để nhắn tin.")),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(
                      receiverId: product.sellerId,
                      receiverName: product.sellerName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Nhắn tin"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Thêm vào giỏ hàng
              },
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text("Thêm vào giỏ hàng"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(color: AppColors.primaryRed, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}