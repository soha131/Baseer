import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../routes.dart';
import 'pharmacist_info.dart';
class PharmacistScreen extends StatefulWidget {
  const PharmacistScreen({super.key});

  @override
  State<PharmacistScreen> createState() => _PharmacistScreenState();
}

class _PharmacistScreenState extends State<PharmacistScreen> {
  TextEditingController searchController = TextEditingController();
  bool sortAZ = true;
  String searchQuery = "";
  int _selectedIndex = 0;
  bool showFavorites = false; // ⭐ لعرض المفضلة
  bool _isSearching = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, AppRoutes.userHome);
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.chatScreen);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, AppRoutes.calenderScreen);
    }
  }

  Future<void> toggleLikeAndFavorite(String pharmacistId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection("users").doc(uid);
    final pharmacistRef = FirebaseFirestore.instance.collection("users").doc(pharmacistId);

    final favRef = userRef.collection("favorites").doc(pharmacistId);
    final likeRef = pharmacistRef.collection("likes").doc(uid);

    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((transaction) async {
      // ✅ اقرأ كل الوثائق أولًا
      final likeDoc = await transaction.get(likeRef);
      final favDoc = await transaction.get(favRef);
      final pharmacistSnap = await transaction.get(pharmacistRef);

      final pharmacistData = pharmacistSnap.data() ?? {};
      int currentLikes = (pharmacistData["likesCount"] ?? 0) as int;

      // ✅ ثم نفذ عمليات الكتابة بناءً على النتائج
      if (likeDoc.exists) {
        // حذف الإعجاب والمفضلة
        transaction.delete(likeRef);
        if (favDoc.exists) transaction.delete(favRef);
        transaction.update(pharmacistRef, {"likesCount": currentLikes - 1});
      } else {
        // إضافة إعجاب ومفضلة
        transaction.set(likeRef, {"likedAt": FieldValue.serverTimestamp()});
        transaction.set(favRef, {"addedAt": FieldValue.serverTimestamp()});
        transaction.update(pharmacistRef, {"likesCount": currentLikes + 1});
      }
    });
  }
  Future<bool> isFavorite(String pharmacistId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final favDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("favorites")
        .doc(pharmacistId)
        .get();
    return favDoc.exists;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search medicines",
            hintStyle: const TextStyle(
                color: Color(0xFF003BFF), fontWeight: FontWeight.w500),
            filled: true,
            fillColor: const Color(0xFFE0E7FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF003BFF)),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value.trim().toLowerCase();
            });
          },
        )
            :const Text(
          "Pharmacist",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF003BFF),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF003BFF)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Color(0xff2260FF)),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  searchQuery = "";
                  searchController.clear();
                }
              });
            },
          ),

        ],

      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Text("Sort By ",
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        sortAZ = !sortAZ;
                      });
                    },
                    child: _filterChip(sortAZ ? "A - Z" : "Z - A", selected: true),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      showFavorites ? Icons.star : Icons.star_border,
                      color: Color(0xFF003BFF),
                    ),
                    onPressed: () {
                      setState(() {
                        showFavorites = !showFavorites;
                      });
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 List of Pharmacists (Firestore)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where("role", isEqualTo: "Pharmacist")
                    .where("status", isEqualTo: "approved")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No approved pharmacists found"));
                  }

                  final pharmacists = snapshot.data!.docs;

                  // 🟦 فلترة بالسيرش
                  List<QueryDocumentSnapshot> filteredPharmacists =
                  pharmacists.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name =
                    (data["fullName"] ?? "").toString().toLowerCase();
                    return name.contains(searchQuery.toLowerCase());
                  }).toList();

                  // 🟦 ترتيب A-Z أو Z-A
                  filteredPharmacists.sort((a, b) {
                    final nameA =
                    ((a.data() as Map<String, dynamic>)["fullName"] ?? "")
                        .toString()
                        .toLowerCase();
                    final nameB =
                    ((b.data() as Map<String, dynamic>)["fullName"] ?? "")
                        .toString()
                        .toLowerCase();
                    return sortAZ
                        ? nameA.compareTo(nameB)
                        : nameB.compareTo(nameA);
                  });

                  if (filteredPharmacists.isEmpty) {
                    return const Center(
                        child: Text("No pharmacists match your search"));
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection("favorites")
                        .get(),
                    builder: (context, favSnapshot) {
                      if (!favSnapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final favoriteIds =
                      favSnapshot.data!.docs.map((e) => e.id).toSet();

                      // لو عرض المفضلة فقط
                      if (showFavorites) {
                        filteredPharmacists = filteredPharmacists
                            .where((doc) => favoriteIds.contains(doc.id))
                            .toList();
                      }

                      if (filteredPharmacists.isEmpty) {
                        return const Center(
                            child: Text("No favorites found"));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPharmacists.length,
                        itemBuilder: (context, index) {
                          final data = filteredPharmacists[index].data()
                          as Map<String, dynamic>;
                          final pharmacistId = filteredPharmacists[index].id;
                          final isFav = favoriteIds.contains(pharmacistId);

                          return PharmacistCard(
                            name: data["fullName"] ?? "Unknown",
                            imageUrl:
                            "assets/logo/pharmacist.jpg",
                            isFavorite: isFav,
                            onInfoTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PharmacistInfoScreen(
                                    userId: pharmacistId,
                                    userData: data,
                                  ),
                                ),
                              );
                            },
                            onDetailsTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PharmacistInfoScreen(
                                    userId: pharmacistId,
                                    userData: data,
                                  ),
                                ),
                              );
                            },
                            onFavoriteTap: () async {
                              await toggleLikeAndFavorite(pharmacistId);
                              setState(() {});
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 🔹 Bottom Navigation معدل
    );
  }
  Widget _filterChip(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Color(0xFF003BFF): Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF003BFF)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: selected ? Colors.white : Color(0xFF003BFF),
            fontWeight: FontWeight.bold),
      ),
    );
  }
  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ""),
        ],
      ),
    );
  }

}

// 🔹 Pharmacist Card Widget
class PharmacistCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onInfoTap;
  final VoidCallback onDetailsTap;
  final VoidCallback onFavoriteTap;

  const PharmacistCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.isFavorite,
    required this.onInfoTap,
    required this.onDetailsTap,
    required this.onFavoriteTap,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffDCEBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // صورة
           CircleAvatar(
            radius: 32,
            backgroundImage: AssetImage(imageUrl),
          ),

          const SizedBox(width: 14),

          // الاسم + الايقونات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onInfoTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xff1A3AA9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Info",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                   /* const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {},
                      icon: const Icon(Icons.calendar_month),
                    ),*/
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: onDetailsTap,
                      icon: const Icon(Icons.info_outline),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: onFavoriteTap,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.black54,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
