import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2260FF),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2260FF)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("notifications")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد إشعارات جديدة"));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isRead ? Colors.white : Colors.blue[50],
                child: ListTile(
                  title: Text(
                    data['title'] ?? "",
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(data['body'] ?? ""),
                  trailing: Text(
                    data['createdAt'] != null
                        ? DateFormat('dd/MM hh:mm a').format((data['createdAt'] as Timestamp).toDate().toLocal())
                        : "",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () async {
                    // تعليم الإشعار كمقروء عند الضغط
                    if (!isRead) {
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(uid)
                          .collection("notifications")
                          .doc(doc.id)
                          .update({"isRead": true});
                    }
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
