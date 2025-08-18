import 'package:flutter/material.dart';
import 'package:vietmall/common/vietnam_provinces.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;
  List<String> _districts = [];
  List<String> _wards = [];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final fullAddress = "${_streetController.text}, ${_selectedWard!}, ${_selectedDistrict!}, ${_selectedProvince!}";
      final addressData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': fullAddress,
      };
      Navigator.of(context).pop(addressData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Địa chỉ giao hàng"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Họ và tên"),
              validator: (v) => v!.isEmpty ? "Vui lòng nhập họ tên" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Số điện thoại"),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? "Vui lòng nhập số điện thoại" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              hint: const Text("Tỉnh/Thành phố"),
              items: vietnamProvinces.keys.map((String province) {
                return DropdownMenuItem<String>(
                  value: province,
                  child: Text(province),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProvince = newValue;
                  _selectedDistrict = null;
                  _selectedWard = null;
                  _districts = vietnamProvinces[newValue!]?.keys.toList() ?? [];
                  _wards = [];
                });
              },
              validator: (v) => v == null ? "Vui lòng chọn Tỉnh/Thành" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              hint: const Text("Quận/Huyện"),
              items: _districts.map((String district) {
                return DropdownMenuItem<String>(
                  value: district,
                  child: Text(district),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDistrict = newValue;
                  _selectedWard = null;
                  _wards = vietnamProvinces[_selectedProvince!]?[newValue!] ?? [];
                });
              },
              validator: (v) => v == null ? "Vui lòng chọn Quận/Huyện" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedWard,
              hint: const Text("Phường/Xã"),
              items: _wards.map((String ward) {
                return DropdownMenuItem<String>(
                  value: ward,
                  child: Text(ward),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedWard = newValue;
                });
              },
              validator: (v) => v == null ? "Vui lòng chọn Phường/Xã" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: "Địa chỉ chi tiết (Số nhà, tên đường...)"),
              validator: (v) => v!.isEmpty ? "Vui lòng nhập địa chỉ chi tiết" : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveAddress,
              child: const Text("LƯU ĐỊA CHỈ"),
            ),
          ],
        ),
      ),
    );
  }
}