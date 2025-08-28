import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // --- Keys and Controllers ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _streetController = TextEditingController();

  // --- Services ---
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  // --- UI State Management ---
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoading = true;
  DateTime? _selectedBirthDate;

  // --- Address Data and State ---
  List<dynamic> _allProvincesData = [];
  List<String> _provinces = [];
  List<String> _districts = [];
  List<String> _wards = [];
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _avatarUrlController.dispose();
    _coverUrlController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  /// Tải đồng thời dữ liệu tỉnh/thành và dữ liệu người dùng để tối ưu.
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadProvincesData(),
      _loadUserData(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Tải và phân tích dữ liệu địa chỉ từ file JSON.
  Future<void> _loadProvincesData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/json/vietnam-provinces.json');
      final List<dynamic> data = json.decode(jsonString);
      _allProvincesData = data;
      _provinces = _allProvincesData.map<String>((province) => province['name'] as String).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu địa chỉ: $e')),
        );
      }
    }
  }

  /// Tải dữ liệu người dùng từ Firestore.
  Future<void> _loadUserData() async {
    final userDoc = await _databaseService.getUserById(_authService.currentUser!.uid);
    if (!userDoc.exists || userDoc.data() == null) return;

    final userData = userDoc.data() as Map<String, dynamic>;

    _nameController.text = userData['fullName'] ?? '';
    _avatarUrlController.text = userData['avatarUrl'] ?? '';
    _coverUrlController.text = userData['coverUrl'] ?? '';

    if (userData['birthDate'] != null) {
      _selectedBirthDate = (userData['birthDate'] as Timestamp).toDate();
      _birthDateController.text = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
    }

    _setupAddressFromData(userData);
  }

  /// Thiết lập các giá trị ban đầu cho dropdown địa chỉ từ dữ liệu đã lưu.
  void _setupAddressFromData(Map<String, dynamic> userData) {
    final userProvince = userData['province'] as String?;
    final userDistrict = userData['district'] as String?;
    final userWard = userData['ward'] as String?;
    _streetController.text = userData['street'] ?? '';

    if (userProvince != null && _provinces.contains(userProvince)) {
      _selectedProvince = userProvince;
      final provinceData = _allProvincesData.firstWhere((p) => p['name'] == _selectedProvince);
      final districtsData = provinceData['districts'] as List<dynamic>;
      _districts = districtsData.map<String>((d) => d['name'] as String).toList();

      if (userDistrict != null && _districts.contains(userDistrict)) {
        _selectedDistrict = userDistrict;
        final districtData = districtsData.firstWhere((d) => d['name'] == _selectedDistrict);
        final wardsData = districtData['wards'] as List<dynamic>;
        _wards = wardsData.map<String>((w) => w['name'] as String).toList();

        if (userWard != null && _wards.contains(userWard)) {
          _selectedWard = userWard;
        }
      }
    }
  }

  /// Hiển thị DatePicker.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  /// Xác thực và lưu thông tin lên Firestore.
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ngày sinh.")));
        return;
      }

      setState(() => _isSaving = true);

      final fullAddress = "${_streetController.text}, ${_selectedWard!}, ${_selectedDistrict!}, ${_selectedProvince!}";

      // Gọi service để cập nhật dữ liệu.
      // Đảm bảo hàm updateUserProfile của bạn nhận đủ các tham số này.
      await _databaseService.updateUserProfile(
        fullName: _nameController.text,
        birthDate: _selectedBirthDate!,
        address: fullAddress,
        province: _selectedProvince!,
        district: _selectedDistrict!,
        ward: _selectedWard!,
        street: _streetController.text,
        avatarUrl: _avatarUrlController.text,
        coverUrl: _coverUrlController.text,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thông tin thành công!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa thông tin',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
        actions: [
          if (_isLoading)
            const SizedBox.shrink()
          else if (_isSaving)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              child: Text(_isEditing ? "Lưu" : "Sửa"),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextFormField(_nameController, "Họ và tên"),
            const SizedBox(height: 16),
            _buildDatePickerFormField(),
            const SizedBox(height: 24),
            _buildAddressSection(),
            const SizedBox(height: 16),
            _buildTextFormField(_avatarUrlController, "URL Ảnh đại diện", isRequired: false),
            const SizedBox(height: 16),
            _buildTextFormField(_coverUrlController, "URL Ảnh bìa", isRequired: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, {bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      enabled: _isEditing,
      validator: isRequired ? (v) => (v == null || v.isEmpty) ? "Vui lòng nhập thông tin" : null : null,
    );
  }

  Widget _buildDatePickerFormField() {
    return TextFormField(
      controller: _birthDateController,
      decoration: const InputDecoration(labelText: "Ngày sinh", suffixIcon: Icon(Icons.calendar_today)),
      readOnly: true,
      onTap: _isEditing ? () => _selectDate(context) : null,
      validator: (v) => (v == null || v.isEmpty) ? "Vui lòng chọn ngày sinh" : null,
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          isExpanded: true,
          hint: const Text("Tỉnh/Thành phố"),
          items: _provinces.map((province) => DropdownMenuItem(value: province, child: Text(province, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _isEditing ? (newValue) {
            setState(() {
              _selectedProvince = newValue;
              _selectedDistrict = null; _selectedWard = null;
              _districts = []; _wards = [];
              if (newValue != null) {
                final provinceData = _allProvincesData.firstWhere((p) => p['name'] == newValue);
                final districtsData = provinceData['districts'] as List<dynamic>;
                _districts = districtsData.map<String>((d) => d['name'] as String).toList();
              }
            });
          } : null,
          validator: (v) => v == null ? "Vui lòng chọn" : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedDistrict,
          isExpanded: true,
          hint: const Text("Quận/Huyện"),
          items: _districts.map((district) => DropdownMenuItem(value: district, child: Text(district, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _isEditing ? (newValue) {
            setState(() {
              _selectedDistrict = newValue;
              _selectedWard = null; _wards = [];
              if (newValue != null) {
                final provinceData = _allProvincesData.firstWhere((p) => p['name'] == _selectedProvince);
                final districtsData = provinceData['districts'] as List<dynamic>;
                final districtData = districtsData.firstWhere((d) => d['name'] == newValue);
                final wardsData = districtData['wards'] as List<dynamic>;
                _wards = wardsData.map<String>((w) => w['name'] as String).toList();
              }
            });
          } : null,
          validator: (v) => v == null ? "Vui lòng chọn" : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedWard,
          isExpanded: true,
          hint: const Text("Phường/Xã"),
          items: _wards.map((ward) => DropdownMenuItem(value: ward, child: Text(ward, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _isEditing ? (newValue) => setState(() => _selectedWard = newValue) : null,
          validator: (v) => v == null ? "Vui lòng chọn" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _streetController,
          decoration: const InputDecoration(labelText: "Số nhà, tên đường"),
          enabled: _isEditing,
          validator: (v) => (v == null || v.isEmpty) ? "Vui lòng nhập địa chỉ chi tiết" : null,
        ),
      ],
    );
  }
}