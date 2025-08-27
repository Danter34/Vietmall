import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vietmall/screens/auth/auth_page.dart';
import 'package:vietmall/screens/main_screen.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          // 🔍 Lắng nghe thay đổi user trên Firestore
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final isActive = userSnapshot.hasData
                  ? (userSnapshot.data!.get('isActive') ?? true)
                  : true;

              if (!isActive) {
                // 🔥 Nếu tài khoản bị khóa → signOut
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authService.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Tài khoản của bạn đã bị khóa"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
                return const MainScreen(); // quay về login
              }

              return const MainScreen(); // Bình thường
            },
          );
        } else {
          return const MainScreen();
        }
      },
    );
  }
}
