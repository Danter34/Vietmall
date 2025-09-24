import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/chat/chat_room_screen.dart';
import 'package:vietmall/screens/home/widgets/product_card.dart';
import 'package:vietmall/screens/profile/edit_product_screen.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/services/database_service.dart';
import 'package:vietmall/widgets/auth_required_dialog.dart';
import 'package:vietmall/widgets/star_rating.dart';
import 'package:vietmall/screens/profile/public_profile_screen.dart';
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final _reviewController = TextEditingController();
  double _userRating = 0;
  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
    }

  ProductModel? _product;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  String _sellerAddress = "Chưa cập nhật";
  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final doc = await _databaseService.getProductById(widget.productId);
      if (doc.exists && mounted) {
        final product = ProductModel.fromFirestore(doc);
        setState(() {
          _product = product;
          _isLoading = false;
        });
        // --- lấy địa chỉ người bán sau khi có product ---
        _fetchSellerInfo(product.sellerId);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --- thêm: fetch địa chỉ người bán ---
  Future<void> _fetchSellerInfo(String sellerId) async {
    try {
      final userDoc = await _databaseService.getUserById(sellerId);
      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _sellerAddress = (userData['address'] as String?)?.trim().isNotEmpty == true
              ? userData['address']
              : "Chưa cập nhật";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _sellerAddress = "Không thể tải địa chỉ");
    }
  }

  // --- thêm: format “đăng X thời gian trước” ---
  String _formatTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final created = timestamp.toDate();
    final difference = now.difference(created);

    if (difference.inDays > 365) {
      return "${(difference.inDays / 365).floor()} năm trước";
    } else if (difference.inDays > 30) {
      return "${(difference.inDays / 30).floor()} tháng trước";
    } else if (difference.inDays > 7) {
      return "${(difference.inDays / 7).floor()} tuần trước";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} ngày trước";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} giờ trước";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} phút trước";
    } else {
      return "Vài giây trước";
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? const Center(child: Text("Không tìm thấy sản phẩm."))
          : CustomScrollView(
        slivers: [
          _buildSliverAppBar(_product!),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfo(_product!),
                const Divider(height: 1),
                _buildSellerInfo(_product!.sellerId, _product!.sellerName),
                const Divider(height: 8, thickness: 8, color: AppColors.greyLight),
                _buildDescription(_product!),
                const Divider(height: 8, thickness: 8, color: AppColors.greyLight),
                _buildReviewsSection(_product!.id), // Thêm mục đánh giá
                const Divider(height: 8, thickness: 8, color: AppColors.greyLight),
                _buildOtherProducts(_product!.sellerId, _product!.id, _product!.sellerName),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _product == null ? null : _buildBottomBar(_product!),
    );
  }
  Widget _buildReviewsSection(String productId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Đánh giá & Bình luận", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildReviewInput(productId),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _databaseService.getReviews(productId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Text("Chưa có đánh giá nào.");

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final review = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildReviewItem(review);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewInput(String productId) {
    final user = AuthService().currentUser;
    if (user == null || user.isAnonymous) {
      return const Text("Vui lòng đăng nhập để để lại đánh giá.");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Đánh giá của bạn:"),
        StarRatingInput(
          rating: _userRating,
          onRatingChanged: (rating) => setState(() => _userRating = rating),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          decoration: const InputDecoration(
            hintText: "Viết bình luận của bạn...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            if (_userRating > 0 && _reviewController.text.isNotEmpty) {
              _databaseService.addReview(
                productId: productId,
                rating: _userRating,
                comment: _reviewController.text,
              );
              _reviewController.clear();
              setState(() => _userRating = 0);
            }
          },
          child: const Text("Gửi đánh giá"),
        ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(review['userName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                StarRating(rating: (review['rating'] as num).toDouble()),
              ],
            ),
            const SizedBox(height: 4),
            Text(review['comment']),
          ],
        ),
      ),
    );
  }
  SliverAppBar _buildSliverAppBar(ProductModel product) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      actions: [
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: product.imageUrls.isNotEmpty ? product.imageUrls.length : 1,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                if (product.imageUrls.isEmpty) {
                  return Container(color: AppColors.greyLight, child: const Icon(Icons.image_not_supported, color: AppColors.grey, size: 100));
                }
                return Image.network(
                  product.imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported, color: AppColors.grey, size: 100),
                );
              },
            ),
            if (product.imageUrls.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(product.imageUrls.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentImageIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<bool>(
                stream: _databaseService.isFavorite(product.id),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border_outlined,
                      color: isFavorite ? AppColors.primaryRed : AppColors.greyDark,
                    ),
                    onPressed: () {
                      final user = AuthService().currentUser;
                      if (user == null || user.isAnonymous) {
                        showAuthRequiredDialog(context);
                      } else {
                        _databaseService.toggleFavoriteStatus(product);
                      }
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(product.price),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 16),
          // --- dùng địa chỉ thật từ _sellerAddress ---
          _infoRow(Icons.location_on_outlined, _sellerAddress),
          const SizedBox(height: 8),
          // --- dùng thời gian thật từ createdAt ---
          _infoRow(
            Icons.timer_outlined,
            (product.createdAt is Timestamp)
                ? _formatTimeAgo(product.createdAt as Timestamp)
                : "Vừa đăng",
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.greyDark, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: const TextStyle(color: AppColors.greyDark))),
      ],
    );
  }

  Widget _buildSellerInfo(String sellerId, String oldSellerName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: DatabaseService().getUserProfile(sellerId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircleAvatar(radius: 24, backgroundColor: AppColors.greyLight);
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final avatarUrl = userData?['avatarUrl'] as String?;
              final displayName =
                  userData?['fullName'] as String? ?? oldSellerName;

              return Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.greyLight,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PublicProfileScreen(userId: sellerId)),
              );
            },
            child: const Text("Xem trang"),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mô tả chi tiết",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherProducts(String sellerId, String currentProductId, String sellerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Tin rao khác của $sellerName",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 250,
          child: StreamBuilder<QuerySnapshot>(
            stream: _databaseService.getOtherProductsFromSeller(sellerId, currentProductId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Người bán không có tin rao nào khác."));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var product = ProductModel.fromFirestore(snapshot.data!.docs[index]);
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(product: product),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    final authService = AuthService();
    final user = authService.currentUser;
    final bool isMyProduct = user?.uid == product.sellerId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: isMyProduct
            ? [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _databaseService.toggleProductVisibility(product.id, product.isHidden);
                Navigator.of(context).pop(); // Quay về trang trước sau khi ẩn
              },
              icon: Icon(product.isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              label: Text(product.isHidden ? "Hiện tin" : "Ẩn tin"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProductScreen(product: product)),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text("Sửa tin"),
            ),
          ),
        ]
            : [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (user == null || user.isAnonymous) {
                  showAuthRequiredDialog(context);
                } else {
                  _databaseService.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã thêm vào giỏ hàng")),
                  );
                }
              },
              child: const Text("Thêm vào giỏ hàng"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (user == null || user.isAnonymous) {
                  showAuthRequiredDialog(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        receiverId: product.sellerId,
                        receiverName: product.sellerName,
                      ),
                    ),
                  );
                }
              },
              child: const Text("Nhắn tin"),
            ),
          ),
        ],
      ),
    );
  }
}