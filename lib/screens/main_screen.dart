import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/home/home_screen.dart';
import 'package:vietmall/screens/post/post_item_screen.dart';
import 'package:vietmall/screens/profile/profile_screen.dart';
import 'package:vietmall/widgets/auth_required_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vietmall/screens/feed/feed_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const FeedScreen(),
    const Center(child: Text('Thông báo')),
    const ProfileScreen(), // Sử dụng ProfileScreen mới
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPostScreen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      showAuthRequiredDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PostItemScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(icon: Icons.home_outlined, label: 'Trang chủ', index: 0),
            _buildNavItem(icon: Icons.shopping_bag_outlined, label: 'Dạo', index: 1),
            const SizedBox(width: 40),
            _buildNavItem(icon: Icons.notifications_none_outlined, label: 'Thông báo', index: 2),
            _buildNavItem(icon: Icons.person_outline, label: 'Tài khoản', index: 3),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 65,
        height: 65,
        child: FloatingActionButton(
          onPressed: _navigateToPostScreen,
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 2.0,
          shape: const CircleBorder(),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 28),
              Text("Đăng tin", style: TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryRed : AppColors.greyDark),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? AppColors.primaryRed : AppColors.greyDark, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}