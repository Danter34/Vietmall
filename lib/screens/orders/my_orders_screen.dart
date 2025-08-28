import 'package:flutter/material.dart';
import 'package:vietmall/screens/orders/widgets/order_list_view.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đơn mua',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
        bottom: TabBar(
          controller: _tabController,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: "Hoạt động", ),
            Tab(text: "Lịch sử"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrderListView(statuses: ['Đang xử lý', 'Đang vận chuyển','Đang giao hàng']),
          OrderListView(statuses: ['Đã giao', 'Đã hủy']),
        ],
      ),
    );
  }
}