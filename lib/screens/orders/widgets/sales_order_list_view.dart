import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vietmall/services/database_service.dart';
import 'package:vietmall/screens/orders/order_detail_screen.dart';

class SalesOrderListView extends StatelessWidget {
  final List<String> statuses;
  const SalesOrderListView({super.key, required this.statuses});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getSalesOrders(statuses),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Không có đơn hàng nào."));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final order = snapshot.data!.docs[index];
            final data = order.data() as Map<String, dynamic>;
            final firstItem = (data['items'] as List).first;
            final imageUrl = firstItem['imageUrl'] as String?;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: SizedBox(
                  width: 60,
                  height: 60,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200]),
                ),
                title: Text("Đơn hàng #${order.id.substring(0, 6)}..."),
                subtitle: Text("Trạng thái: ${data['status']}"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderDetailScreen(orderId: order.id)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
