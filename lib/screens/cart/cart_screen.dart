import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/services/database_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  final Set<String> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng"),
        actions: [
          if (_selectedItems.isNotEmpty)
            TextButton(
              onPressed: () {
                _databaseService.removeCartItems(_selectedItems.toList());
                setState(() {
                  _selectedItems.clear();
                });
              },
              child: const Text("Xóa", style: TextStyle(color: AppColors.primaryRed)),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _databaseService.getCartItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Giỏ hàng của bạn đang trống."));

          final cartDocs = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    final doc = cartDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCartItem(doc.id, data);
                  },
                ),
              ),
              _buildBottomBar(cartDocs),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(String docId, Map<String, dynamic> data) {
    final isSelected = _selectedItems.contains(docId);
    final imageUrl = data['imageUrl'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedItems.add(docId);
                } else {
                  _selectedItems.remove(docId);
                }
              });
            },
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(color: AppColors.greyLight),
              )
                  : Container(color: AppColors.greyLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['sellerName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(data['title']),
                Text(formatter.format(data['price']), style: const TextStyle(color: AppColors.primaryRed)),
              ],
            ),
          ),
          _buildQuantityStepper(docId, data['quantity']),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(String docId, int quantity) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: quantity > 1 ? () => _databaseService.updateCartItemQuantity(docId, quantity - 1) : null,
        ),
        Text(quantity.toString()),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _databaseService.updateCartItemQuantity(docId, quantity + 1),
        ),
      ],
    );
  }

  Widget _buildBottomBar(List<QueryDocumentSnapshot> cartDocs) {
    bool isAllSelected = cartDocs.isNotEmpty && _selectedItems.length == cartDocs.length;

    double totalPrice = 0;
    for (var doc in cartDocs) {
      if (_selectedItems.contains(doc.id)) {
        final data = doc.data() as Map<String, dynamic>;
        totalPrice += (data['price'] * data['quantity']);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Checkbox(
                value: isAllSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedItems.addAll(cartDocs.map((doc) => doc.id));
                    } else {
                      _selectedItems.clear();
                    }
                  });
                },
              ),
              const Text("Tất cả"),
            ],
          ),
          Row(
            children: [
              Text("Tổng: ${formatter.format(totalPrice)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _selectedItems.isEmpty ? null : () {},
                child: const Text("Mua hàng"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
