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
        const SnackBar(
          content: Text("Vui lòng đồng ý với Điều khoản và Chính sách bảo mật."),
        ),
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
            const SnackBar(
                content: Text("Đăng ký thành công! Vui lòng đăng nhập.")),
          );
          widget.showLoginPage();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // nền trắng
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo
                  Image.asset("assets/logo/applogo (1).png", height: 90),
                  const SizedBox(height: 20),

                  const Text(
                    "Bắt đầu cuộc hành trình của bạn",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Họ tên
                  _buildTextField(
                    controller: _fullNameController,
                    hint: "Họ và tên",
                    validator: (v) =>
                    v!.isEmpty ? "Vui lòng nhập họ tên" : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    hint: "Email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Vui lòng nhập email";
                      if (!v.contains('@')) return "Email không hợp lệ";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ngày sinh
                  _buildTextField(
                    controller: _birthDateController,
                    hint: "Ngày sinh",
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  const SizedBox(height: 16),

                  // Mật khẩu
                  _buildTextField(
                    controller: _passwordController,
                    hint: "Mật khẩu",
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Vui lòng nhập mật khẩu";
                      }
                      if (v.length < 6) {
                        return "Mật khẩu phải có ít nhất 6 ký tự";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Xác nhận mật khẩu
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: "Xác nhận mật khẩu",
                    obscureText: !_isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                      _isConfirmPasswordVisible =
                      !_isConfirmPasswordVisible),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return "Mật khẩu không khớp";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTermsAndConditions(),
                  const SizedBox(height: 24),

                  // Nút đăng ký
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "Tiếp tục",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Đăng nhập link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Đã có tài khoản? "),
                      GestureDetector(
                        onTap: widget.showLoginPage,
                        child: const Text(
                          "Đăng nhập ngay",
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
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
}
