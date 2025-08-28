// lib/screens/contact_support_screen.dart
import 'package:flutter/material.dart';
import 'package:vietmall/screens/chat/chat_room_screen.dart';
import 'package:vietmall/common/constants.dart'; // import hằng số

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Điều hướng trực tiếp đến phòng chat với admin
    return ChatRoomScreen(
      receiverId: adminSupportId,
      receiverName: adminSupportName,
    );
  }
}