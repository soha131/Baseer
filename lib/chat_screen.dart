import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications/notification_service.dart';


class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      doc.reference.update({'isRead': true});
    }
  }
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    // أضف الرسالة داخل messages
    await chatRef.collection('messages').add({
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // حدّث بيانات الشات العامة
    await chatRef.set({
      'users': [currentUser!.uid, widget.receiverId],
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 🔹 جلب بيانات المرسل والمستلم
    final senderDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final receiverDoc = await FirebaseFirestore.instance.collection('users').doc(widget.receiverId).get();

    final senderName = senderDoc.data()?['fullName'] ?? "مستخدم";
    final receiverFcmToken = receiverDoc.data()?['fcmToken'];

    // 🔔 إرسال إشعار فوري عبر FCM
    if (receiverFcmToken != null && receiverFcmToken.toString().isNotEmpty) {
      await NotificationService.sendToSpecificUser(
        title: "رسالة جديدة من $senderName",
        body: text,
        fcmToken: receiverFcmToken,
      );
    }

    // 💾 حفظ الإشعار داخل Firestore للمستلم
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.receiverId)
        .collection("notifications")
        .add({
      "title": "رسالة جديدة من $senderName",
      "body": text,
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
      "type": "new_message",
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName, style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xff2260FF),
        ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color:  Color(0xff2260FF)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser?.uid;

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xff2260FF)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: const Color(0xffECF1FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xff2260FF)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats", style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xff2260FF),
        ),
      ),
        automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      iconTheme: const IconThemeData(color:  Color(0xff2260FF)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUser.uid)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final users = List<String>.from(chat['users']);
              final otherUserId =
              users.firstWhere((id) => id != currentUser.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  final userData = userSnap.data!;
                  final name = userData['fullName'] ?? 'Unknown User';
                  final lastMessage = chat['lastMessage'] ?? '';
                  final updatedAt =
                  (chat['updatedAt'] as Timestamp?)?.toDate();

                  // 🔹 Stream لمتابعة الرسائل غير المقروءة
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chat.id)
                        .collection('messages')
                        .where('receiverId', isEqualTo: currentUser.uid)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, unreadSnapshot) {
                      final hasUnread = unreadSnapshot.hasData &&
                          unreadSnapshot.data!.docs.isNotEmpty;

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xff2260FF),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (updatedAt != null)
                              Text(
                                "${updatedAt.hour}:${updatedAt.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            const SizedBox(width: 8),
                            if (hasUnread)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chat.id,
                                receiverId: otherUserId,
                                receiverName: name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


