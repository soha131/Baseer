import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pharmacist_info.dart';

class FavoritePharmacistsScreen extends StatelessWidget {
  const FavoritePharmacistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Favorite Pharmacists",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff2260FF),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff2260FF)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("favorites")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final favoriteDocs = snapshot.data!.docs;
          if (favoriteDocs.isEmpty) return const Center(child: Text("No favorites yet"));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // عدد الكروت في الصف
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final pharmacistId = favoriteDocs[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection("users").doc(pharmacistId).get(),
                builder: (context, docSnap) {
                  if (!docSnap.hasData) return const SizedBox();
                  final data = docSnap.data!.data() as Map<String, dynamic>;

                  return _buildPharmacistCard(context, pharmacistId, data);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPharmacistCard(BuildContext context, String id, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PharmacistInfoScreen(
              userId: id,
              userData: data,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffDCEBFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: AssetImage(
                "assets/logo/pharmacist.jpg"
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data["fullName"] ?? "Unknown",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data["specialization"] ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff1A3AA9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "View",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
