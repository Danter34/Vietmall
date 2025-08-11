import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/home/home_screen.dart';
import 'package:vietmall/screens/post/post_item_screen.dart';
import 'package:vietmall/services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const Center(child: Text('Dạo VietMall')),
    const Center(child: Text('Thông báo')),
    Scaffold(appBar: AppBar(title: const Text("Tài khoản")), body: Center(child: ElevatedButton(onPressed: () => AuthService().signOut(), child: const Text("Đăng xuất")))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostItemScreen()),
    );
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
            _buildNavItem(icon: Icons.shopping_bag_outlined, label: 'Dạo', index: 1), // Rút gọn label
            const SizedBox(width: 40),
            _buildNavItem(icon: Icons.notifications_none_outlined, label: 'Thông báo', index: 2),
            _buildNavItem(icon: Icons.person_outline, label: 'Tài khoản', index: 3),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 65, // Giảm kích thước nút
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
              Text("Đăng tin", style: TextStyle(fontSize: 9)), // Giảm cỡ chữ
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
            Text(label, style: TextStyle(color: isSelected ? AppColors.primaryRed : AppColors.greyDark, fontSize: 11)), // Giảm cỡ chữ
          ],
        ),
      ),
    );
  }
}
