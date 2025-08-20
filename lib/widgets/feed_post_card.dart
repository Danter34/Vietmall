import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/chat/chat_room_screen.dart';
import 'package:vietmall/screens/product/product_detail_screen.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/services/database_service.dart';
import 'package:vietmall/widgets/auth_required_dialog.dart';
import 'package:vietmall/screens/profile/public_profile_screen.dart';
class FeedPostCard extends StatelessWidget {
  final Map<String, dynamic> postData;
  const FeedPostCard({super.key, required this.postData});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final product = ProductModel.fromMap(postData);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildImage(context, product.id),
          _buildProductInfo(context, formatter, product.id),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(postData['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          _buildActionButtons(context, product),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) { // Thêm context
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: AppColors.greyLight),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PublicProfileScreen(userId: postData['sellerId'])),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(postData['sellerName'] ?? 'Người bán', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("21 giờ trước", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {},
            child: const Text("Theo dõi"),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, String productId) {
    final imageUrls = postData['imageUrls'] as List?;
    if (imageUrls == null || imageUrls.isEmpty) {
      return Container(height: 250, color: AppColors.greyLight);
    }
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: productId)));
      },
      child: Image.network(imageUrls.first, height: 250, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _buildProductInfo(BuildContext context, NumberFormat formatter, String productId) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: productId)));
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Thông tin sản phẩm", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Giá tiền sản phẩm: ${formatter.format(postData['price'] ?? 0)}"),
              ],
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProductModel product) {
    final databaseService = DatabaseService();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StreamBuilder<bool>(
            stream: databaseService.isFavorite(product.id),
            builder: (context, snapshot) {
              final isFavorite = snapshot.data ?? false;
              return TextButton.icon(
                onPressed: () {
                  final user = AuthService().currentUser;
                  if (user == null || user.isAnonymous) {
                    showAuthRequiredDialog(context);
                  } else {
                    databaseService.toggleFavoriteStatus(product);
                  }
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.primaryRed : Colors.grey.shade700,
                ),
                label: Text("Lưu tin", style: TextStyle(color: Colors.grey.shade700)),
              );
            },
          ),
          TextButton.icon(
            onPressed: () {
              final user = AuthService().currentUser;
              if (user == null || user.isAnonymous) {
                showAuthRequiredDialog(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(
                      receiverId: product.sellerId,
                      receiverName: product.sellerName,
                    ),
                  ),
                );
              }
            },
            icon: Icon(Icons.chat_bubble_outline, color: Colors.grey.shade700),
            label: Text("Chat", style: TextStyle(color: Colors.grey.shade700)),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.share_outlined, color: Colors.grey.shade700),
            label: Text("Chia sẻ", style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}
