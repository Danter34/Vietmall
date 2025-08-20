import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _addressController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _coverUrlController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  bool _isEditing = false;
  DateTime? _selectedBirthDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDoc = await _databaseService.getUserById(_authService.currentUser!.uid);
    final userData = userDoc.data() as Map<String, dynamic>;

    _nameController.text = userData['fullName'] ?? '';
    _addressController.text = userData['address'] ?? '';
    _avatarUrlController.text = userData['avatarUrl'] ?? '';
    _coverUrlController.text = userData['coverUrl'] ?? '';
    if (userData['birthDate'] != null) {
      _selectedBirthDate = (userData['birthDate'] as Timestamp).toDate();
      _birthDateController.text = DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _avatarUrlController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Kiểm tra tuổi
      if (_selectedBirthDate != null) {
        final age = DateTime.now().difference(_selectedBirthDate!).inDays / 365;
        if (age < 16) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ngày sinh ko hợp lệ")),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn ngày sinh.")),
        );
        return;
      }

      await _databaseService.updateUserProfile(
        fullName: _nameController.text,
        birthDate: _selectedBirthDate!,
        address: _addressController.text,
        avatarUrl: _avatarUrlController.text,
        coverUrl: _coverUrlController.text,
      );

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thông tin thành công!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa thông tin"),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator()))
              : TextButton(
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            /*TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Họ và tên"),
              enabled: _isEditing,
            ),*/
            const SizedBox(height: 16),
            TextFormField(
              controller: _birthDateController,
              decoration: const InputDecoration(labelText: "Ngày sinh"),
              readOnly: true,
              onTap: _isEditing ? () => _selectDate(context) : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Địa chỉ"),
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _avatarUrlController,
              decoration: const InputDecoration(labelText: "URL Ảnh đại diện"),
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coverUrlController,
              decoration: const InputDecoration(labelText: "URL Ảnh bìa"),
              enabled: _isEditing,
            ),
          ],
        ),
      ),
    );
  }
}