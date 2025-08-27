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
    const ProfileScreen(),
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
      // Giữ thuộc tính này, nó vẫn hữu ích
      resizeToAvoidBottomInset: false,
      // Bỏ floatingActionButton và floatingActionButtonLocation
      // Thay vào đó, body sẽ là một Stack
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: kBottomNavigationBarHeight + 24 + MediaQuery.of(context).padding.bottom,
            ),
            child: IndexedStack(
              index: _selectedIndex,
              children: _widgetOptions,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavWithFab(),
          ),
        ],
      ),
    );
  }

  // Widget mới để chứa cả BottomAppBar và nút FAB
  Widget _buildBottomNavWithFab() {
    return Stack(
      // Cho phép nút FAB vẽ ra ngoài phạm vi của BottomAppBar
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Lớp nền: BottomAppBar của bạn
        BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem("assets/main/home.png", "Trang chủ", 0),
              _buildNavItem("assets/main/daoviet.png", "Dạo VietMall", 1),
              const SizedBox(width: 40), // chừa chỗ cho nút đăng tin
              _buildNavItem("assets/main/Group.png", "Thông báo", 2),
              _buildNavItem("assets/main/user.png", "Tài khoản", 3),
            ],
          ),
        ),
        // Lớp trên: Nút Đăng tin (giữ nguyên Transform của bạn)
        Transform(
          transform: Matrix4.translationValues(5, -15, 0),
          child: GestureDetector(
            onTap: _navigateToPostScreen,
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ClipOval(
                  child: Image.asset(
                    "assets/main/dt.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(String assetPath, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: 24,
              height: 24,
              color: isSelected ? AppColors.primaryRed : AppColors.greyDark,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryRed : AppColors.greyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}