import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/checkout/address_screen.dart';
import 'package:vietmall/screens/orders/my_orders_screen.dart';
import 'package:vietmall/services/database_service.dart';

// Enum để định nghĩa các tùy chọn vận chuyển
enum ShippingOption { fast, economy }

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  Map<String, String> _shippingAddress = {
    'name': '',
    'phone': '',
    'address': '',
  };
  ShippingOption _selectedShipping = ShippingOption.fast; // Mặc định là Nhanh

  @override
  Widget build(BuildContext context) {
    double shippingFee = _selectedShipping == ShippingOption.fast
        ? 50000
        : 30000;
    double finalTotal = widget.totalPrice + shippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
      ),
      body: ListView(
        children: [
          _buildAddressSection(),
          const Divider(height: 8, thickness: 8, color: AppColors.greyLight),
          _buildOrderItems(),
          const Divider(height: 8, thickness: 8, color: AppColors.greyLight),
          _buildShippingOptions(),
          const Divider(height: 8, thickness: 8, color: AppColors.greyLight),
          _buildPaymentDetails(finalTotal, shippingFee),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(finalTotal),
    );
  }

  Widget _buildAddressSection() {
    return ListTile(
      leading: const Icon(
          Icons.location_on_outlined, color: AppColors.primaryRed),
      title: Text("${_shippingAddress['name']} | ${_shippingAddress['phone']}"),
      subtitle: Text(_shippingAddress['address']!),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        final result = await Navigator.push<Map<String, String>>(
          context,
          MaterialPageRoute(builder: (context) => const AddressScreen()),
        );
        if (result != null && mounted) {
          setState(() {
            _shippingAddress = result;
          });
        }
      },
    );
  }

  Widget _buildOrderItems() {
    return Column(
      children: widget.cartItems.map((item) {
        final imageUrl = item['imageUrl'] as String?;
        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) =>
                          Container(color: AppColors.greyLight),
                    )
                        : Container(color: AppColors.greyLight),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['sellerName'], style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                      Text(item['title']),
                      Text(formatter.format(item['price'])),
                    ],
                  ),
                ),
                Text("x${item['quantity']}"),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShippingOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Phương thức vận chuyển",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          RadioListTile<ShippingOption>(
            title: const Text('Nhanh'),
            subtitle: Text(formatter.format(50000)),
            value: ShippingOption.fast,
            groupValue: _selectedShipping,
            onChanged: (ShippingOption? value) {
              if (value != null) {
                setState(() {
                  _selectedShipping = value;
                });
              }
            },
          ),
          RadioListTile<ShippingOption>(
            title: const Text('Tiết kiệm'),
            subtitle: Text(formatter.format(30000)),
            value: ShippingOption.economy,
            groupValue: _selectedShipping,
            onChanged: (ShippingOption? value) {
              if (value != null) {
                setState(() {
                  _selectedShipping = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(double finalTotal, double shippingFee) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Chi tiết thanh toán",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng tiền hàng"),
              Text(formatter.format(widget.totalPrice)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng tiền vận chuyển"),
              Text(formatter.format(shippingFee)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng thanh toán",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(formatter.format(finalTotal), style: const TextStyle(
                  color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double finalTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Tổng cộng: ${formatter.format(finalTotal)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              // ✅ Check địa chỉ trước khi cho đặt hàng
              if (_shippingAddress['name']!.isEmpty ||
                  _shippingAddress['phone']!.isEmpty ||
                  _shippingAddress['address']!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        "Vui lòng chọn địa chỉ giao hàng trước khi thanh toán."),
                    backgroundColor: Colors.red,
                  ),
                );
                return; // ❌ Không cho chạy tiếp
              }

              // ✅ Có địa chỉ thì mới tạo đơn hàng
              await DatabaseService().createOrder(
                items: widget.cartItems,
                totalPrice: finalTotal,
                shippingAddress: _shippingAddress,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đặt hàng thành công!")),
                );

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const MyOrdersScreen()),
                      (Route<dynamic> route) => route.isFirst,
                );
              }
            },
            child: const Text("Đặt hàng"),
          ),
        ],
      ),
    );
  }
}
