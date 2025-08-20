import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/screens/chat/chat_room_screen.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/services/chat_service.dart';
import 'package:vietmall/services/database_service.dart';
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tin nhắn"),
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Đã có lỗi xảy ra."));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Bạn chưa có cuộc trò chuyện nào."));
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) => _buildChatListItem(snapshot.data!.docs[index]),
                  separatorBuilder: (context, index) => const Divider(height: 1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Text("Tất cả"),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Nhập 3 ký tự để tìm kiếm",
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final currentUserId = _authService.currentUser!.uid;

    List<String> userIds = List<String>.from(data['users']);
    String otherUserId = userIds.firstWhere((id) => id != currentUserId);
    String otherUserName = data['userNames'][otherUserId] ?? 'Người dùng';

    Timestamp timestamp = data['lastMessageTimestamp'];
    String formattedTime = DateFormat('HH:mm').format(timestamp.toDate());

    return ListTile(
      leading: StreamBuilder<DocumentSnapshot>(
        stream: DatabaseService().getUserProfile(otherUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.greyLight,
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final avatarUrl = userData?['avatarUrl'] as String?;

          return CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.greyLight,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          );
        },
      ),
      title: Row(
        children: [
          Text(otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(formattedTime, style: const TextStyle(color: AppColors.greyDark, fontSize: 12)),
        ],
      ),
      subtitle: Text(data['lastMessage'], maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Container(
        width: 50,
        height: 50,
        color: AppColors.greyLight,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              receiverId: otherUserId,
              receiverName: otherUserName,
            ),
          ),
        );
      },
    );
  }
}