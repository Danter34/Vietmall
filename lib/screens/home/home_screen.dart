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
import 'package:vietmall/widgets/badge_icon_button.dart';
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
    'https://intphcm.com/data/upload/mau-banner-hinh-anh.jpg',
    'https://img.freepik.com/free-psd/horizontal-banner-template-big-sale-with-woman-shopping-bags_23-2148786755.jpg',
    'https://intphcm.com/data/upload/banner-la-gi.jpg',
    'https://file.hstatic.net/1000190106/file/banner_52c7c95bfca340a39340178942e19f70_1024x1024.jpg',
    'https://i.ytimg.com/vi/YzRkoQFjrM8/sddefault.jpg',
  ];

  // ----- BẮT ĐẦU FIX LỖI CHỚP-LOAD LẠI -----

  // 1. Khai báo biến để lưu các stream
  late Stream<QuerySnapshot> _categoryStream;
  late Stream<QuerySnapshot> _recentProductsStream;

  @override
  void initState() {
    super.initState();
    // 2. Lấy stream một lần duy nhất khi màn hình được khởi tạo
    _categoryStream = _databaseService.getCategories();
    _recentProductsStream = _databaseService.getRecentProducts();
  }

  // ----- KẾT THÚC FIX LỖI CHỚP-LOAD LẠI -----

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
    final currentUser = FirebaseAuth.instance.currentUser;

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
                  builder: (context) => ProductListScreen(searchQuery: value.trim()),
                ),
              );
            }
          },
        ),
      ),
      actions: [
        // 🛒 Badge giỏ hàng
        StreamBuilder<QuerySnapshot>(
          stream: _databaseService.getCartItems(),
          builder: (context, snapshot) {
            int cartCount = 0;
            if (snapshot.hasData) {
              cartCount = snapshot.data!.docs.length;
            }

            return BadgeIconButton(
              icon: Image.asset(
                'assets/icon/cart.png',
                width: 26,
                height: 26,
                color: AppColors.greyDark,
              ),
              badgeCount: cartCount,
              onPressed: () {
                if (currentUser == null || currentUser.isAnonymous) {
                  showAuthRequiredDialog(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                }
              },
            );
          },
        ),

        // 💬 Badge tin nhắn chưa đọc
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chat_rooms')
              .where('users', arrayContains: currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['unread'] != null) {
                  unreadCount += (data['unread'][currentUser?.uid] ?? 0) as int;
                }
              }
            }

            return BadgeIconButton(
              icon: Image.asset(
                'assets/icon/message.png',
                width: 26,
                height: 26,
                color: AppColors.greyDark,
              ),
              badgeCount: unreadCount,
              onPressed: () {
                if (currentUser == null || currentUser.isAnonymous) {
                  showAuthRequiredDialog(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatListScreen()),
                  );
                }
              },
            );
          },
        )
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
      // 3. Sử dụng biến stream đã được khởi tạo
      stream: _categoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(height: 240, child: Center(child: Text("Không có danh mục.")));
        }

        return SizedBox(
          height: 240,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              childAspectRatio: 1.25,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var category = CategoryModel.fromFirestore(snapshot.data!.docs[index]);
              return CategoryCard(category: category);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      // 3. Sử dụng biến stream đã được khởi tạo
      stream: _recentProductsStream,
      builder: (context, snapshot) {
        // Thay !snapshot.hasData bằng kiểm tra chi tiết hơn để tránh lỗi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Đã có lỗi xảy ra"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Chưa có sản phẩm nào."));
        }

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