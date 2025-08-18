import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/services/database_service.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn hàng #${orderId.substring(0, 6)}..."),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = data['items'] as List;
          final address = data['shippingAddress'] as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Trạng thái: ${data['status']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
              const Divider(height: 32),
              const Text("Địa chỉ giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(address['name'] ?? ''),
              Text(address['phone'] ?? ''),
              Text(address['address'] ?? ''),
              const Divider(height: 32),
              const Text("Sản phẩm đã đặt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...items.map((item) {
                return ListTile(
                  leading: SizedBox(width: 50, height: 50, child: Image.network(item['imageUrl'])),
                  title: Text(item['title']),
                  subtitle: Text("${formatter.format(item['price'])} x ${item['quantity']}"),
                );
              }).toList(),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tổng tiền:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(formatter.format(data['totalPrice']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                ],
              ),
              const SizedBox(height: 32),
              if (data['status'] == 'Đang xử lý')
                ElevatedButton(
                  onPressed: () {
                    DatabaseService().cancelOrder(orderId);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Hủy đơn"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
            ],
          );
        },
      ),
    );
  }
}