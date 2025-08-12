import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/auth/auth_page.dart';
import 'package:vietmall/screens/profile/saved_products_screen.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/widgets/auth_required_dialog.dart';

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
              isLoggedIn ? _buildUserInfo(context, user!) : _buildLoginPrompt(context),
              _buildSectionTitle("Quản lý đơn hàng"),
              _buildOptionCard(Icons.shopping_basket_outlined, "Đơn mua"),
              _buildSectionTitle("Tiện ích"),
              _buildOptionTile(
                Icons.favorite_border,
                "Tin đăng đã lưu",
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedProductsScreen()));
                  } else {
                    showAuthRequiredDialog(context);
                  }
                },
              ),
              _buildOptionTile(Icons.search, "Tìm kiếm đã lưu"),
              _buildOptionTile(Icons.star_border, "Đánh giá từ tôi"),
              _buildOptionTile(Icons.local_offer_outlined, "Khuyến mãi của tôi"),
              _buildSectionTitle("Khác"),
              _buildOptionTile(Icons.settings_outlined, "Cài đặt tài khoản"),
              _buildOptionTile(Icons.help_outline, "Trợ giúp"),
              _buildOptionTile(Icons.feedback_outlined, "Đóng góp ý kiến"),
              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton(
                    onPressed: () => AuthService().signOut(),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: AppColors.greyLight),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName ?? "Người dùng", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(user.email ?? "Chưa có email"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthPage()));
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, backgroundColor: AppColors.greyLight),
            const SizedBox(width: 16),
            const Text("Đăng nhập / Đăng ký", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOptionCard(IconData icon, String title) {
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
        onTap: () {},
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
