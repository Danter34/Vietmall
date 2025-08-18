import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/screens/profile/edit_product_screen.dart';
import 'package:vietmall/services/database_service.dart';
import 'package:intl/intl.dart';
class ManageListingsScreen extends StatefulWidget {
  const ManageListingsScreen({super.key});

  @override
  State<ManageListingsScreen> createState() => _ManageListingsScreenState();
}

class _ManageListingsScreenState extends State<ManageListingsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý tin đăng"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _databaseService.getMyProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Bạn chưa đăng tin nào."));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final product = ProductModel.fromFirestore(snapshot.data!.docs[index]);
              return _buildListingItem(product);
            },
          );
        },
      ),
    );
  }

  Widget _buildListingItem(ProductModel product) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: product.imageUrls.isNotEmpty
              ? Image.network(product.imageUrls.first, fit: BoxFit.cover)
              : Container(color: Colors.grey[200]),
        ),
        title: Text(product.title),
        subtitle: Text(NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(product.price)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProductScreen(product: product)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(product.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa tin đăng này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              _databaseService.deleteProduct(productId);
              Navigator.of(context).pop();
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
