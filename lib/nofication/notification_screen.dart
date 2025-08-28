import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vietmall/services/database_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser != null) {
        _dbService.markAllAsRead();
      }
    });
  }

  Future<void> _markAsRead(DocumentReference docRef) {
    return docRef.update({'read': true});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Nếu chưa đăng nhập → show thông báo mặc định
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.white),
        ),
          backgroundColor: const Color(0xFFE53935),),
        body: const Center(
          child: Text("Bạn chưa có thông báo nào."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bạn chưa có thông báo nào.'));
          }

          final notifications = snapshot.data!.docs;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final isRead = data['read'] ?? false;

              return Card(
                color: isRead ? Colors.white : Colors.blue.withOpacity(0.1),
                child: ListTile(
                  title: Text(
                    data['title'] ?? "",
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(data['body'] ?? ""),
                  onTap: () {
                    _markAsRead(notification.reference);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
