import 'package:flutter/material.dart';
import 'package:vietmall/screens/auth/auth_page.dart';

void showAuthRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Yêu cầu đăng nhập"),
        content: const Text("Bạn cần đăng nhập để sử dụng chức năng này."),
        actions: <Widget>[
          TextButton(
            child: const Text("Để sau"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text("Đăng nhập"),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthPage()));
            },
          ),
        ],
      );
    },
  );
}