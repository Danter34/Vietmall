import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/home/widgets/product_card.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/services/database_service.dart';
import 'package:vietmall/widgets/auth_required_dialog.dart';
import 'package:vietmall/screens/profile/edit_profile_screen.dart';
class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final isMyProfile = _authService.currentUser?.uid == widget.userId;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _databaseService.getUserProfile(widget.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return DefaultTabController(
            length: 1, // Chỉ có 1 tab "Đang hiển thị"
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(userData),
                  SliverToBoxAdapter(
                    child: _buildProfileInfo(userData, isMyProfile),
                  ),
                  const SliverPersistentHeader(
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        tabs: [
                          Tab(text: "Sản phẩm đang bán"),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildUserProducts(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(Map<String, dynamic> userData) {
    final coverUrl = userData['coverUrl'] as String?;
    return SliverAppBar(
      backgroundColor: AppColors.primaryRed,
      foregroundColor: Colors.white,
      expandedHeight: 150.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: (coverUrl != null && coverUrl.isNotEmpty)
            ? Image.network(coverUrl, fit: BoxFit.cover)
            : Container(color: AppColors.primaryRed),
        title: Text(userData['fullName'] ?? 'Người dùng'),
        centerTitle: false,
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData, bool isMyProfile) {
    final avatarUrl = userData['avatarUrl'] as String?;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               CircleAvatar(
                radius: 30,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              const Spacer(),
              if (isMyProfile)
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                  child: const Text("Chỉnh sửa thông tin"),
                )
              else
                StreamBuilder<bool>(
                  stream: _databaseService.isFollowing(widget.userId),
                  builder: (context, snapshot) {
                    final isFollowing = snapshot.data ?? false;
                    return ElevatedButton(
                      onPressed: () {
                        final user = _authService.currentUser;
                        if (user == null || user.isAnonymous) {
                          showAuthRequiredDialog(context);
                        } else {
                          _databaseService.toggleFollowStatus(widget.userId);
                        }
                      },
                      child: Text(isFollowing ? "Hủy theo dõi" : "Theo dõi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.grey : AppColors.primaryRed,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(userData['fullName'] ?? 'Người dùng', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              StreamBuilder<int>(
                stream: _databaseService.getFollowerCount(widget.userId),
                builder: (context, snapshot) => _buildStat("Người theo dõi", snapshot.data ?? 0),
              ),
              const SizedBox(width: 16),
              StreamBuilder<int>(
                stream: _databaseService.getFollowingCount(widget.userId),
                builder: (context, snapshot) => _buildStat("Đang theo dõi", snapshot.data ?? 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Row(
      children: [
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildUserProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getProductsBySeller(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Người dùng này chưa đăng bán sản phẩm nào."));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final product = ProductModel.fromFirestore(snapshot.data!.docs[index]);
            return ProductCard(product: product);
          },
        );
      },
    );
  }
}

// Lớp helper để giữ TabBar cố định khi cuộn
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _SliverTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
