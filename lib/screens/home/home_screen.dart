import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/models/category_model.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/cart/cart_screen.dart';
import 'package:vietmall/screens/chat/chat_list_screen.dart';
import 'package:vietmall/screens/home/widgets/category_card.dart';
import 'package:vietmall/screens/home/widgets/product_card.dart';
import 'package:vietmall/screens/product/product_list_screen.dart';
import 'package:vietmall/services/database_service.dart';
import 'package:vietmall/widgets/auth_required_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  int _currentBannerIndex = 0;

  final List<String> _bannerImages = [
    'https://via.placeholder.com/600x250/FF0000/FFFFFF?text=Banner+1',
    'https://via.placeholder.com/600x250/0000FF/FFFFFF?text=Banner+2',
    'https://via.placeholder.com/600x250/00FF00/FFFFFF?text=Banner+3',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        color: AppColors.white,
        child: ListView(
          children: [
            _buildBanner(),
            _buildQuickActions(),
            const Divider(height: 8, thickness: 8, color: AppColors.greyLight),
            _buildSectionTitle('Khám phá danh mục'),
            _buildCategoryGrid(),
            const Divider(height: 8, thickness: 8, color: AppColors.greyLight),
            _buildSectionTitle('Tin đăng mới'),
            _buildRecentProductsGrid(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm trên VietMall',
            prefixIcon: Icon(Icons.search, color: AppColors.greyDark),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductListScreen(
                    searchQuery: value.trim(),
                  ),
                ),
              );
            }
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.greyDark),
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null || user.isAnonymous) {
              showAuthRequiredDialog(context);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: AppColors.greyDark),
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null || user.isAnonymous) {
              showAuthRequiredDialog(context);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _bannerImages.length,
          itemBuilder: (context, index, realIndex) {
            return Image.network(_bannerImages[index], fit: BoxFit.cover, width: double.infinity);
          },
          options: CarouselOptions(
            height: 150,
            autoPlay: true,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_bannerImages.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentBannerIndex == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index ? AppColors.primaryRed : AppColors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionButton(Icons.camera_alt_outlined, "Đăng bán\nbằng AI"),
          _quickActionButton(Icons.phone_android_outlined, "Nạp ĐT"),
          _quickActionButton(Icons.star_border_outlined, "Gói Pro"),
          _quickActionButton(Icons.live_tv_outlined, "VietMall\nLivestream"),
          _quickActionButton(Icons.motorcycle_outlined, "Đặt xe\nchính hãng"),
        ],
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 28),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var category = CategoryModel.fromFirestore(snapshot.data!.docs[index]);
            return CategoryCard(category: category);
          },
        );
      },
    );
  }

  Widget _buildRecentProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getRecentProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var product = ProductModel.fromFirestore(snapshot.data!.docs[index]);
            return ProductCard(product: product);
          },
        );
      },
    );
  }
}