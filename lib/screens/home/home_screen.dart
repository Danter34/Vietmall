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




  // 1. Khai báo biến để lưu các stream
  late Stream<QuerySnapshot> _categoryStream;
  late Stream<QuerySnapshot> _recentProductsStream;
  late Stream<DocumentSnapshot> _bannerStream;
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    // 2. Lấy stream một lần duy nhất khi màn hình được khởi tạo
    _categoryStream = _databaseService.getCategories();
    _recentProductsStream = _databaseService.getRecentProducts();
    _bannerStream = FirebaseFirestore.instance
        .collection('banners')
        .doc('main_banners')
        .snapshots();
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // THAY ĐỔI 1: Bọc Scaffold bằng StreamBuilder để lắng nghe trạng thái đăng nhập
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Lấy thông tin người dùng từ snapshot của stream
        final currentUser = snapshot.data;

        return Scaffold(
          // THAY ĐỔI 2: Truyền currentUser xuống AppBar
          appBar: _buildAppBar(currentUser),
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
      },
    );
  }

// THAY ĐỔI 3: Sửa _buildAppBar để nhận currentUser làm tham số
  AppBar _buildAppBar(User? currentUser) {
    // Bỏ dòng này đi vì đã nhận currentUser từ bên ngoài
    // final currentUser = FirebaseAuth.instance.currentUser;

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
                  builder: (context) =>
                      ProductListScreen(searchQuery: value.trim()),
                ),
              );
            }
          },
        ),
      ),
      actions: [
        //  Badge giỏ hàng
        StreamBuilder<QuerySnapshot>(
          key: ValueKey(currentUser?.uid),
          // Giờ đây bạn có thể chắc chắn stream này sẽ được khởi tạo lại khi currentUser thay đổi
          stream: _databaseService.getCartItems(), // Giả sử hàm getCartItems của bạn nhận userId
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
          // Luôn kiểm tra currentUser?.uid có null không trước khi query
          stream: currentUser != null ? FirebaseFirestore.instance
              .collection('chat_rooms')
              .where('users', arrayContains: currentUser.uid)
              .snapshots() : null, // Nếu user null thì không lắng nghe stream nào cả
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['unread'] != null && currentUser != null) {
                  unreadCount += (data['unread'][currentUser.uid] ?? 0) as int;
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
    return StreamBuilder<DocumentSnapshot>(
      stream: _bannerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200, // cao hơn xíu
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text("Không có banner")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final imageUrls = [
          data['link1'],
          data['link2'],
          data['link3'],
          data['link4'],
          data['link5'],
        ]
            .where((link) => link != null && link.toString().isNotEmpty)
            .cast<String>()
            .toList();

        if (imageUrls.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text("Không có banner")),
          );
        }

        // Tính chiều cao “to hơn xíu” theo tỉ lệ 16:9, clamp để cân đối trên mọi máy
        final w = MediaQuery.of(context).size.width;
        final h = 180.0; // min 200, max 320

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: double.infinity,
              height: h,
              // full 2 bên: không padding ngang
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Slider full-bleed
                  CarouselSlider.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index, realIndex) {
                      final url = imageUrls[index];
                      return ClipRRect(
                        // bo nhẹ cho đẹp; nếu muốn thật sự "vuông" sát mép, đổi về Radius.zero
                        borderRadius: BorderRadius.zero,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Ảnh
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loading) {
                                if (loading == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error)),
                            ),
                            // Gradient dưới để dot/ chữ rõ hơn
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: true,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.25),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: h,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: true,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayAnimationDuration: const Duration(milliseconds: 650),
                      onPageChanged: (index, reason) {
                        setState(() => _currentBannerIndex = index);
                      },
                    ),
                  ),

                  // Dots overlay giữa đáy (đẹp, cân đối)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(imageUrls.length, (index) {
                        final isActive = _currentBannerIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isActive ? 28 : 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primaryRed : Colors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isActive
                                ? [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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