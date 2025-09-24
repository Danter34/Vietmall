import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // thêm dòng này
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

  String timeAgoFromTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Vừa xong"; // fallback khi không có timestamp

    final now = DateTime.now();
    final ts = (timestamp as Timestamp).toDate();
    final difference = now.difference(ts);

    if (difference.inDays > 365) {
      return "${(difference.inDays / 365).floor()} năm trước";
    } else if (difference.inDays > 30) {
      return "${(difference.inDays / 30).floor()} tháng trước";
    } else if (difference.inDays > 7) {
      return "${(difference.inDays / 7).floor()} tuần trước";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} ngày trước";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} giờ trước";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} phút trước";
    } else {
      return "Vài giây trước";
    }
  }

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
          _buildImageGrid(context, product.id),
          _buildProductInfo(context, formatter, product.id),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              postData['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildActionButtons(context, product),
        ],
      ),
    );
  }

  /// --- Header với avatar, tên, thời gian, nút theo dõi ---
  Widget _buildHeader(BuildContext context) {
    final databaseService = DatabaseService();
    final currentUser = AuthService().currentUser;
    final sellerId = postData['sellerId'];
    final oldSellerName = postData['sellerName'] ?? "Người bán";
    final isMyPost = currentUser != null && currentUser.uid == sellerId;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Avatar + tên từ Firestore
          StreamBuilder<DocumentSnapshot>(
            stream: databaseService.getUserProfile(sellerId),
            builder: (context, snapshot) {
              final userData =
              snapshot.hasData && snapshot.data!.exists
                  ? snapshot.data!.data() as Map<String, dynamic>
                  : null;
              final avatarUrl = userData?['avatarUrl'] as String?;
              final displayName =
                  userData?['fullName'] as String? ?? oldSellerName;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PublicProfileScreen(userId: sellerId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      backgroundColor: avatarUrl == null || avatarUrl.isEmpty
                          ? AppColors.greyLight
                          : Colors.transparent,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          timeAgoFromTimestamp(postData['createdAt']),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const Spacer(),

          // Nút theo dõi
          if (!isMyPost)
            StreamBuilder<bool>(
              stream: databaseService.isFollowing(sellerId),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;
                return OutlinedButton(
                  onPressed: () {
                    final user = AuthService().currentUser;
                    if (user == null || user.isAnonymous) {
                      showAuthRequiredDialog(context);
                    } else {
                      databaseService.toggleFollowStatus(sellerId);
                    }
                  },
                  child: Text(isFollowing ? "Hủy theo dõi" : "Theo dõi"),
                );
              },
            ),
        ],
      ),
    );
  }

  /// --- Hiển thị tối đa 4 ảnh dạng grid ---
  Widget _buildImageGrid(BuildContext context, String productId) {
    final imageUrls = postData['imageUrls'] as List?;
    if (imageUrls == null || imageUrls.isEmpty) {
      return Container(height: 250, color: AppColors.greyLight);
    }

    final images = imageUrls.take(4).toList();
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: productId),
          ),
        );
      },
      child: _buildGridLayout(images),
    );
  }

  Widget _buildGridLayout(List images) {
    if (images.length == 1) {
      return Image.network(images[0],
          height: 250, width: double.infinity, fit: BoxFit.cover);
    } else if (images.length == 2) {
      return Row(
        children: images
            .map((url) => Expanded(
          child: Image.network(url,
              height: 250, fit: BoxFit.cover),
        ))
            .toList(),
      );
    } else if (images.length == 3) {
      return Row(
        children: [
          Expanded(
            child: Image.network(images[0],
                height: 250, fit: BoxFit.cover),
          ),
          Expanded(
            child: Column(
              children: [
                Image.network(images[1],
                    height: 125, fit: BoxFit.cover),
                Image.network(images[2],
                    height: 125, fit: BoxFit.cover),
              ],
            ),
          ),
        ],
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        children: images
            .map((url) =>
            Image.network(url, height: 125, fit: BoxFit.cover))
            .toList(),
      );
    }
  }

  /// --- Thông tin sản phẩm ---
  Widget _buildProductInfo(
      BuildContext context, NumberFormat formatter, String productId) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: productId)),
        );
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
                const Text("Thông tin sản phẩm",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Giá tiền sản phẩm: ${formatter.format(postData['price'] ?? 0)}"),
              ],
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  /// --- Các nút hành động (Lưu tin, Chat, Share) ---
  Widget _buildActionButtons(BuildContext context, ProductModel product) {
    final databaseService = DatabaseService();
    final currentUser = AuthService().currentUser;
    final isMyPost = currentUser != null && currentUser.uid == product.sellerId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Lưu tin
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
          // Chat (ẩn nếu là bài mình)
          if (!isMyPost)
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
          // Share
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
