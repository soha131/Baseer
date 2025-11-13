import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes.dart';

class NotificationIconWithBadge extends StatelessWidget {
  const NotificationIconWithBadge({super.key});

  Future<String?> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data()?['role'];
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(); // انتظار تحميل الدور
        }

        final role = snapshot.data;
        late final Stream<QuerySnapshot> stream;

        // 📦 حدد مصدر الإشعارات حسب الدور
        if (role == "Admin") {
          stream = FirebaseFirestore.instance
              .collection("notifications")
              .where("to", isEqualTo: uid)
              .where("isRead", isEqualTo: false)
              .snapshots();
        } else {
          stream = FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("notifications")
              .where("isRead", isEqualTo: false)
              .snapshots();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.length;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    // 👇 توجيه حسب نوع المستخدم
                    if (role == "Admin") {
                      Navigator.pushNamed(context, AppRoutes.adminNotifications);
                    } else {
                      Navigator.pushNamed(
                          context, AppRoutes.notifications);
                    }
                  },
                  icon: const Icon(Icons.notifications_none, size: 28),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
