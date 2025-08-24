import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/auth/auth_page.dart';
import 'package:vietmall/screens/profile/saved_products_screen.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/widgets/auth_required_dialog.dart';
import 'package:vietmall/screens/orders/my_orders_screen.dart';
import 'package:vietmall/screens/profile/manage_listings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vietmall/screens/profile/settings_screen.dart';
import 'package:vietmall/screens/orders/my_sales_screen.dart';
import 'package:vietmall/screens/profile/public_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài khoản"),
      ),
      body: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          final bool isLoggedIn = user != null && !user.isAnonymous;

          return ListView(
            children: [
              isLoggedIn
                  ? _buildUserInfo(context, user!)
                  : _buildLoginPrompt(context),

              _buildSectionTitle("Quản lý đơn hàng"),
              _buildOptionCard(
                Icons.shopping_basket_outlined,
                "Đơn mua",
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersScreen(),
                      ),
                    );
                  } else {
                    showAuthRequiredDialog(context);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildOptionCard(
                Icons.storefront_outlined,
                "Đơn bán",
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MySalesScreen()),
                    );
                  } else {
                    showAuthRequiredDialog(context);
                  }
                },
              ),

              _buildSectionTitle("Tiện ích"),
              _buildOptionTile(
                Icons.article_outlined,
                "Quản lý tin",
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const ManageListingsScreen()));
                  } else {
                    showAuthRequiredDialog(context);
                  }
                },
              ),
              _buildOptionTile(
                Icons.favorite_border,
                "Tin đăng đã lưu",
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedProductsScreen(),
                      ),
                    );
                  } else {
                    showAuthRequiredDialog(context);
                  }
                },
              ),

              _buildSectionTitle("Khác"),
              _buildOptionTile(
                Icons.settings_outlined,
                "Cài đặt tài khoản",
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()));
                  } else {
                    showAuthRequiredDialog(context);
                  }
                },
              ),
              _buildOptionTile(Icons.help_outline, "Trợ giúp"),
              _buildOptionTile(Icons.feedback_outlined, "Đóng góp ý kiến"),

              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Xác nhận"),
                          content:
                          const Text("Bạn có chắc chắn muốn đăng xuất không?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Hủy"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed),
                              child: const Text("Đăng xuất"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await AuthService().signOut();
                      }
                    },
                    child: const Text("Đăng xuất"),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final avatarUrl = userData?['avatarUrl'] ?? user.photoURL;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PublicProfileScreen(userId: user.uid)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.greyLight,
                  backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 30, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData?['fullName'] ??
                          user.displayName ??
                          "Người dùng",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(user.email ?? "Chưa có email"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.greyLight,
              child: const Icon(
                Icons.person,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              "Đăng nhập / Đăng ký",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOptionCard(IconData icon, String title, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryRed),
        title: Text(title),
        onTap: onTap,
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.greyDark),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
