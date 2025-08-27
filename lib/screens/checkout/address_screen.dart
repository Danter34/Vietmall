import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Biến để lưu toàn bộ dữ liệu gốc từ JSON
  List<dynamic> _allProvincesData = [];

  // Các biến để quản lý danh sách hiển thị trên Dropdown
  List<String> _provinces = [];
  List<String> _districts = [];
  List<String> _wards = [];

  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  // Hàm đọc và xử lý file JSON có cấu trúc mới
  Future<void> _loadProvinces() async {
    try {
      final String response = await rootBundle.loadString('assets/json/vietnam-provinces.json');
      final List<dynamic> data = await json.decode(response);
      setState(() {
        _allProvincesData = data;
        // Trích xuất danh sách tên tỉnh/thành phố
        _provinces = _allProvincesData.map<String>((province) => province['name'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu địa chỉ: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final fullAddress =
          "${_streetController.text}, ${_selectedWard!}, ${_selectedDistrict!}, ${_selectedProvince!}";
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Các TextFormField không thay đổi
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Họ và tên"),
              validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập họ tên" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Số điện thoại"),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập số điện thoại" : null,
            ),
            const SizedBox(height: 16),

            // Dropdown Tỉnh/Thành phố
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              isExpanded: true,
              hint: const Text("Tỉnh/Thành phố"),
              items: _provinces.map((String province) {
                return DropdownMenuItem<String>(value: province, child: Text(province));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProvince = newValue;
                  _selectedDistrict = null;
                  _selectedWard = null;
                  _districts = [];
                  _wards = [];

                  if (newValue != null) {
                    // Tìm tỉnh/thành phố được chọn trong dữ liệu gốc
                    final selectedProvinceData = _allProvincesData.firstWhere(
                          (province) => province['name'] == newValue,
                      orElse: () => null,
                    );
                    if (selectedProvinceData != null) {
                      // Lấy danh sách quận/huyện từ tỉnh/thành phố đó
                      final districtsData = selectedProvinceData['districts'] as List<dynamic>;
                      _districts = districtsData.map<String>((district) => district['name'] as String).toList();
                    }
                  }
                });
              },
              validator: (v) => v == null ? "Vui lòng chọn Tỉnh/Thành" : null,
            ),
            const SizedBox(height: 16),

            // Dropdown Quận/Huyện
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              isExpanded: true,
              hint: const Text("Quận/Huyện"),
              items: _districts.map((String district) {
                return DropdownMenuItem<String>(value: district, child: Text(district));
              }).toList(),
              onChanged: _selectedProvince == null ? null : (String? newValue) {
                setState(() {
                  _selectedDistrict = newValue;
                  _selectedWard = null;
                  _wards = [];

                  if (newValue != null) {
                    // Tìm tỉnh/thành phố đang được chọn
                    final selectedProvinceData = _allProvincesData.firstWhere((province) => province['name'] == _selectedProvince);
                    // Tìm quận/huyện được chọn trong tỉnh/thành phố đó
                    final districtsData = selectedProvinceData['districts'] as List<dynamic>;
                    final selectedDistrictData = districtsData.firstWhere(
                          (district) => district['name'] == newValue,
                      orElse: () => null,
                    );

                    if (selectedDistrictData != null) {
                      // Lấy danh sách phường/xã từ quận/huyện đó
                      final wardsData = selectedDistrictData['wards'] as List<dynamic>;
                      _wards = wardsData.map<String>((ward) => ward['name'] as String).toList();
                    }
                  }
                });
              },
              validator: (v) => v == null ? "Vui lòng chọn Quận/Huyện" : null,
            ),
            const SizedBox(height: 16),

            // Dropdown Phường/Xã
            DropdownButtonFormField<String>(
              value: _selectedWard,
              isExpanded: true,
              hint: const Text("Phường/Xã"),
              items: _wards.map((String ward) {
                return DropdownMenuItem<String>(value: ward, child: Text(ward));
              }).toList(),
              onChanged: _selectedDistrict == null ? null : (String? newValue) {
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
              validator: (v) => v == null || v.isEmpty ? "Vui lòng nhập địa chỉ chi tiết" : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("LƯU ĐỊA CHỈ"),
            ),
          ],
        ),
      ),
    );
  }
}