import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/home/widgets/product_card.dart';
import 'package:vietmall/services/database_service.dart';

// Enum để định nghĩa các tùy chọn sắp xếp
enum PriceSortOption { none, lowToHigh, highToLow }

class ProductListScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final String? searchQuery;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.searchQuery,
  }) : assert(categoryId != null || searchQuery != null);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseService _databaseService = DatabaseService();

  late Stream<QuerySnapshot> _productStream;
  PriceSortOption _sortOption = PriceSortOption.none;

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _productStream = _databaseService.getFilteredProducts(
        categoryId: widget.categoryId,
        searchQuery: widget.searchQuery,
        sortOption: _sortOption,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.searchQuery != null ? 'Kết quả cho "${widget.searchQuery}"' : widget.categoryName!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          PopupMenuButton<PriceSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (PriceSortOption result) {
              setState(() {
                _sortOption = result;
                _applyFilters();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<PriceSortOption>>[
              const PopupMenuItem<PriceSortOption>(
                value: PriceSortOption.none,
                child: Text('Mặc định'),
              ),
              const PopupMenuItem<PriceSortOption>(
                value: PriceSortOption.lowToHigh,
                child: Text('Giá: Thấp đến Cao'),
              ),
              const PopupMenuItem<PriceSortOption>(
                value: PriceSortOption.highToLow,
                child: Text('Giá: Cao đến Thấp'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Đã có lỗi xảy ra. Vui lòng tạo chỉ mục trên Firebase."));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không tìm thấy sản phẩm nào."));
          }

          return GridView.builder(
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
      ),
    );
  }
}