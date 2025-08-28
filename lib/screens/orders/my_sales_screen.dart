import 'package:flutter/material.dart';
import 'package:vietmall/screens/orders/widgets/sales_order_list_view.dart';

class MySalesScreen extends StatefulWidget {
  const MySalesScreen({super.key});

  @override
  State<MySalesScreen> createState() => _MySalesScreenState();
}

class _MySalesScreenState extends State<MySalesScreen> with SingleTickerProviderStateMixin {
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
          'Đơn bán',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
        bottom: TabBar(
          controller: _tabController,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: "Hoạt động"),
            Tab(text: "Lịch sử"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SalesOrderListView(statuses: ['Đang xử lý', 'Đang vận chuyển','Đang giao hàng']),
          SalesOrderListView(statuses: ['Đã giao', 'Đã hủy']),
        ],
      ),
    );
  }
}
