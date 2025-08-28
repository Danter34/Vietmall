import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/home/home_screen.dart';
import 'package:vietmall/screens/post/post_item_screen.dart';
import 'package:vietmall/screens/profile/profile_screen.dart';
import 'package:vietmall/widgets/auth_required_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vietmall/screens/feed/feed_screen.dart';
import 'package:vietmall/nofication/notification_screen.dart'; // Import the notification screen
import 'package:badges/badges.dart' as badges; // Import the badges library
import 'package:vietmall/services/database_service.dart'; // Import your DatabaseService

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService(); // Add an instance of your service

  // Keep the list as is, it's just a placeholder for the notification tab
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const FeedScreen(),
    const NotificationScreen(),
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
      resizeToAvoidBottomInset: false,
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

  Widget _buildBottomNavWithFab() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem("assets/main/home.png", "Trang chủ", 0),
              _buildNavItem("assets/main/daoviet.png", "Dạo VietMall", 1),
              const SizedBox(width: 40),
              _buildNavItem("assets/main/Group.png", "Thông báo", 2),
              _buildNavItem("assets/main/user.png", "Tài khoản", 3),
            ],
          ),
        ),
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

    if (index == 2) { // Logic for the "Thông báo" tab
      return InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: StreamBuilder<int>(
            stream: _dbService.getUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return badges.Badge(
                showBadge: unreadCount > 0,
                position: badges.BadgePosition.topEnd(top: 0, end: 10),
                badgeContent: const SizedBox(
                  width: 2,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
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
              );
            },
          ),
        ),
      );
    }

    // Logic for other tabs
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