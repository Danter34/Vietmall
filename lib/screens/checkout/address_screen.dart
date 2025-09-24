import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vietmall/services/database_service.dart';

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

  List<dynamic> _allProvincesData = [];
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
    _loadProvinces().then((_) {
      _loadSavedAddress();
    });
  }

  Future<void> _loadProvinces() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json/vietnam-provinces.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        _allProvincesData = data;
        _provinces = _allProvincesData
            .map<String>((province) => province['name'] as String)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu địa chỉ: $e')),
        );
      }
    }
  }

  Future<void> _loadSavedAddress() async {
    final savedAddress = await DatabaseService().getShippingAddress();
    if (savedAddress != null && mounted) {
      setState(() {
        _nameController.text = savedAddress['name'] ?? '';
        _phoneController.text = savedAddress['phone'] ?? '';
        _streetController.text =
            savedAddress['address']?.split(",").first.trim() ?? '';

        // parse tỉnh/huyện/xã từ địa chỉ cũ
        final parts = savedAddress['address']?.split(",") ?? [];
        if (parts.length >= 4) {
          _selectedWard = parts[1].trim();
          _selectedDistrict = parts[2].trim();
          _selectedProvince = parts[3].trim();

          // load danh sách huyện theo tỉnh
          final selectedProvinceData = _allProvincesData.firstWhere(
                (province) => province['name'] == _selectedProvince,
            orElse: () => null,
          );
          if (selectedProvinceData != null) {
            final districtsData =
            selectedProvinceData['districts'] as List<dynamic>;
            _districts = districtsData
                .map<String>((d) => d['name'] as String)
                .toList();

            final selectedDistrictData = districtsData.firstWhere(
                  (d) => d['name'] == _selectedDistrict,
              orElse: () => null,
            );
            if (selectedDistrictData != null) {
              final wardsData = selectedDistrictData['wards'] as List<dynamic>;
              _wards = wardsData.map<String>((w) => w['name'] as String).toList();
            }
          }
        }
      });
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
        title: const Text(
          'Địa chỉ giao hàng',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Họ và tên
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Họ và tên"),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Vui lòng nhập họ tên";
                }
                if (v.trim().length < 3) {
                  return "Họ tên phải ít nhất 3 ký tự";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Số điện thoại
            TextFormField(
              controller: _phoneController,
              decoration:
              const InputDecoration(labelText: "Số điện thoại"),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Vui lòng nhập số điện thoại";
                }
                final regex = RegExp(r'^(0[0-9]{9})$');
                if (!regex.hasMatch(v)) {
                  return "Số điện thoại không hợp lệ";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dropdown Tỉnh/Thành phố
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              isExpanded: true,
              hint: const Text("Tỉnh/Thành phố"),
              items: _provinces.map((String province) {
                return DropdownMenuItem<String>(
                    value: province, child: Text(province));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProvince = newValue;
                  _selectedDistrict = null;
                  _selectedWard = null;
                  _districts = [];
                  _wards = [];

                  if (newValue != null) {
                    final selectedProvinceData = _allProvincesData
                        .firstWhere((province) =>
                    province['name'] == newValue);
                    final districtsData =
                    selectedProvinceData['districts'] as List<dynamic>;
                    _districts = districtsData
                        .map<String>((district) =>
                    district['name'] as String)
                        .toList();
                  }
                });
              },
              validator: (v) =>
              v == null ? "Vui lòng chọn Tỉnh/Thành phố" : null,
            ),
            const SizedBox(height: 16),

            // Dropdown Quận/Huyện
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              isExpanded: true,
              hint: const Text("Quận/Huyện"),
              items: _districts.map((String district) {
                return DropdownMenuItem<String>(
                    value: district, child: Text(district));
              }).toList(),
              onChanged: _selectedProvince == null
                  ? null
                  : (String? newValue) {
                setState(() {
                  _selectedDistrict = newValue;
                  _selectedWard = null;
                  _wards = [];

                  if (newValue != null) {
                    final selectedProvinceData = _allProvincesData
                        .firstWhere((province) =>
                    province['name'] == _selectedProvince);
                    final districtsData =
                    selectedProvinceData['districts']
                    as List<dynamic>;
                    final selectedDistrictData =
                    districtsData.firstWhere(
                          (district) =>
                      district['name'] == newValue,
                      orElse: () => null,
                    );

                    if (selectedDistrictData != null) {
                      final wardsData =
                      selectedDistrictData['wards']
                      as List<dynamic>;
                      _wards = wardsData
                          .map<String>(
                              (ward) => ward['name'] as String)
                          .toList();
                    }
                  }
                });
              },
              validator: (v) =>
              v == null ? "Vui lòng chọn Quận/Huyện" : null,
            ),
            const SizedBox(height: 16),

            // Dropdown Phường/Xã
            DropdownButtonFormField<String>(
              value: _selectedWard,
              isExpanded: true,
              hint: const Text("Phường/Xã"),
              items: _wards.map((String ward) {
                return DropdownMenuItem<String>(
                    value: ward, child: Text(ward));
              }).toList(),
              onChanged: _selectedDistrict == null
                  ? null
                  : (String? newValue) {
                setState(() {
                  _selectedWard = newValue;
                });
              },
              validator: (v) =>
              v == null ? "Vui lòng chọn Phường/Xã" : null,
            ),
            const SizedBox(height: 16),

            // Địa chỉ chi tiết
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                  labelText: "Địa chỉ chi tiết (Số nhà, tên đường...)"),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Vui lòng nhập địa chỉ chi tiết";
                }
                if (v.trim().length < 5) {
                  return "Địa chỉ phải ít nhất 5 ký tự";
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Nút lưu
            ElevatedButton(
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("LƯU ĐỊA CHỈ"),
            ),
          ],
        ),
      ),
    );
  }
}
