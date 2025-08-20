import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterScreen({super.key, required this.showLoginPage});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
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

  Future<void> _register() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đồng ý với Điều khoản và Chính sách bảo mật.")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Kiểm tra tuổi
      if (_selectedBirthDate != null) {
        final age = DateTime.now().difference(_selectedBirthDate!).inDays / 365;
        if (age < 16) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bạn phải đủ 16 tuổi để đăng ký.")),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn ngày sinh.")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final authService = AuthService();
      String? result = await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _fullNameController.text.trim(),
        _selectedBirthDate!,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đăng ký thành công! Vui lòng đăng nhập.")),
          );
          widget.showLoginPage();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("VietMall"),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Đăng ký tài khoản",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                  validator: (v) => v!.isEmpty ? "Vui lòng nhập họ tên" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthDateController,
                  decoration: const InputDecoration(
                    labelText: 'Ngày sinh',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Mật khẩu không khớp';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTermsAndConditions(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ĐĂNG KÝ'),
                  ),
                ),
                const SizedBox(height: 32),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildSocialLoginButtons(),
                const SizedBox(height: 48),
                _buildSwitchPageLink(
                    "Đã có tài khoản?", " Đăng nhập", widget.showLoginPage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value!),
          activeColor: AppColors.primaryRed,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 14),
              children: [
                const TextSpan(text: "Bằng việc Đăng ký, bạn đồng ý với "),
                TextSpan(
                  text: "Điều khoản",
                  style: const TextStyle(color: AppColors.primaryRed),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                const TextSpan(text: " và "),
                TextSpan(
                  text: "Chính sách bảo mật",
                  style: const TextStyle(color: AppColors.primaryRed),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("Hoặc đăng nhập bằng",
              style: TextStyle(color: AppColors.greyDark)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(
            icon: Icons.facebook,
            label: "Facebook",
            onTap: () {},
            iconColor: const Color(0xFF1877F2)),
        const SizedBox(width: 16),
        _socialButton(
            icon: Icons.g_mobiledata,
            label: "Google",
            onTap: () {},
            iconColor: Colors.red),
        const SizedBox(width: 16),
        _socialButton(
            icon: Icons.message,
            label: "Zalo",
            onTap: () {},
            iconColor: const Color(0xFF0068FF)),
      ],
    );
  }

  Widget _socialButton(
      {required IconData icon,
        required String label,
        required VoidCallback onTap,
        required Color iconColor}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: iconColor),
      label: Text(label, style: const TextStyle(color: Colors.black)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: AppColors.grey.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildSwitchPageLink(String text1, String text2, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text1),
        GestureDetector(
          onTap: onTap,
          child: Text(
            text2,
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
