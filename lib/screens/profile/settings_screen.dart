import 'package:flutter/material.dart';
import 'package:vietmall/screens/profile/account_info_screen.dart';
import 'package:vietmall/screens/profile/change_password_screen.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/main_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            // user đã xóa hoặc logout → quay về HomeScreen
            Future.microtask(() {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
              );
            });
            return const SizedBox();
          }
          return _buildScaffold(context);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
      ),
      body: ListView(
        children: [
          _buildSectionTitle("Cài Đặt Tài Khoản"),
          _buildOptionTile(
            context,
            Icons.person_outline,
            "Thông tin tài khoản",
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountInfoScreen()),
            ),
          ),
          _buildOptionTile(
            context,
            Icons.delete_outline,
            "Xóa tài khoản",
                () => _showDeleteConfirmation(context),
          ),
          _buildSectionTitle("Bảo mật"),
          _buildOptionTile(
            context,
            Icons.lock_outline,
            "Thay đổi mật khẩu",
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
            ),
          ),
        ],
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

  Widget _buildOptionTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryRed),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa tài khoản"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Hành động này không thể hoàn tác. Vui lòng nhập mật khẩu để xác nhận."
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              final result = await AuthService().deleteUserAccount(passwordController.text);
              if (result == null) {
                // Xóa thành công → đóng dialog
                Navigator.of(context).pop();
                // StreamBuilder sẽ tự điều hướng về HomeScreen
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result))
                );
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
