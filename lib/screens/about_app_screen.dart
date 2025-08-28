// lib/screens/about_app_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Đóng'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url"); // tránh crash app
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông tin ứng dụng',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/img.png', // logo app
              height: 150,
            ),
            const SizedBox(height: 30),
            const Text(
              'VietMall',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              'Phát triển bởi Team 7',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),

            // Các social link
            _buildSocialLink(
              icon: 'assets/img/fb.png',
              text: 'Liên hệ qua Facebook',
              onTap: () => _launchURL('https://www.facebook.com/'),
            ),
            _buildSocialLink(
              icon: 'assets/img/zalo.png',
              text: 'Liên hệ qua Zalo',
              onTap: () => _launchURL('https://chat.zalo.me/'),
            ),
            _buildSocialLink(
              icon: 'assets/img/Instagram_icon.png',
              text: 'Liên hệ qua Instagram',
              onTap: () => _launchURL('https://www.instagram.com/'),
            ),
            _buildSocialLink(
              icon: 'assets/img/email.png',
              text: 'Liên hệ qua Email',
              onTap: () => _launchURL('mailto:your.atushidaiki@gmail.com'),
            ),
            const SizedBox(height: 20),

            // Chính sách bảo mật
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _showDialog(
                  context,
                  'Chính sách bảo mật',
                  'VietMall cam kết bảo mật thông tin cá nhân của khách hàng.\n\n'
                      '- Chúng tôi chỉ thu thập thông tin cần thiết để phục vụ mua sắm và giao hàng.\n'
                      '- Thông tin của bạn được sử dụng cho mục đích xử lý đơn hàng và chăm sóc khách hàng.\n'
                      '- VietMall không chia sẻ dữ liệu cá nhân với bên thứ ba, trừ khi có yêu cầu pháp lý.\n'
                      '- Dữ liệu thanh toán luôn được mã hóa và bảo mật tuyệt đối.\n\n'
                      '- Chúng tôi nỗ lực mang đến trải nghiệm mua sắm an toàn, minh bạch và đáng tin cậy.',
                ),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Color(0xFFE53935)),
                      SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          'Chính sách bảo mật',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLink({
    required String icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Image.asset(icon, height: 24, width: 24),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
