import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/main_screen.dart';
import 'firebase_options.dart';
import 'package:vietmall/screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const VietMallApp());
}

class VietMallApp extends StatelessWidget {
  const VietMallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VietMall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryRed,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          elevation: 1,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.grey.withOpacity(0.5)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        useMaterial3: true,
      ),
      home: AuthWrapper(),
    );
  }
}
