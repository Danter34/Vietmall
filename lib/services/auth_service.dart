import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vietmall/services/database_service.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> registerWithEmailAndPassword(
      String email, String password, String fullName, DateTime birthDate) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(fullName);
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'email': email,
          'birthDate': Timestamp.fromDate(birthDate),
          'createdAt': Timestamp.now(),
          'role': 'user', // Thêm trường role
          'isActive': true, // Thêm trường isActive
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 🔍 Kiểm tra trạng thái isActive trong Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && !(doc['isActive'] ?? true)) {
          // Nếu bị khóa thì signOut ngay
          await _auth.signOut();
          return "Tài khoản của bạn đã bị khóa";
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "Người dùng không tồn tại.";

      // Xác thực lại người dùng với mật khẩu cũ
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Nếu xác thực thành công, đổi mật khẩu mới
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteUserAccount(String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "Người dùng không tồn tại.";

      // Xác thực lại trước khi xóa
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Xóa dữ liệu trên Firestore
      await DatabaseService().deleteAllUserData(user.uid);

      // Xóa tài khoản trên Authentication
      await user.delete();

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}