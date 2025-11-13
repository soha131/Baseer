import 'package:baseer/admin_screens/user_info.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes.dart';

class PharmacistListScreen extends StatefulWidget {
  const PharmacistListScreen({super.key});

  @override
  State<PharmacistListScreen> createState() => _PharmacistListScreenState();
}

class _PharmacistListScreenState extends State<PharmacistListScreen> {
  TextEditingController searchController = TextEditingController();
  bool sortAZ = true;
  String searchQuery = "";
  int _selectedIndex = 0;
  bool _isSearching = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // ✅ الهوم
      Navigator.pushReplacementNamed(context, AppRoutes.admin);
    } else if (index == 1) {
      // ✅ البروفايل
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:_isSearching
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
            :  const Text(
          "View Users",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff2260FF),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color:Color(0xff2260FF)),
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
          children: [
            // 🔹 Sort Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Text("Sort: ",
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        sortAZ = !sortAZ;
                      });
                    },
                    child:
                    _filterChip(sortAZ ? "A - Z" : "Z - A", selected: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 List from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .orderBy("fullName", descending: !sortAZ)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  final users = snapshot.data!.docs.where((user) {
                    final data = user.data() as Map<String, dynamic>;

                    final name = data["fullName"]?.toString().toLowerCase() ?? "";
                    final role = data["role"]?.toString().toLowerCase() ?? "";

                    // ✅ نخفي الادمن واليوزر ونسيب بس الفارمست
                    if (role != "pharmacist") return false;

                    return name.contains(searchQuery.toLowerCase());
                  }).toList();


                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final data = user.data() as Map<String, dynamic>;
                      return PharmacistCard(
                        name: data["fullName"] ?? "No Name",
                        role: data["role"] ?? "N/A",
                        imageUrl: "https://i.pravatar.cc/150?u=${user.id}",
                        onInfoTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserInfoScreen(
                                userId: user.id,
                                userData: data,
                              ),
                            ),
                          );
                        },
                        onDetailsTap: () {
                          Navigator.pushNamed(
                            context,
                            '/userInfoScreen',
                            arguments: UserInfoArgs(
                              userId: user.id,
                              userData: data,
                            ),
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
    //  bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _filterChip(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Color(0xff2260FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xff2260FF)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: selected ? Colors.white : Color(0xff2260FF),
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color:Color(0xff2260FF),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

class PharmacistCard extends StatelessWidget {
  final String name;
  final String role;
  final String imageUrl;
  final VoidCallback onInfoTap;
  final VoidCallback onDetailsTap;

  const PharmacistCard({
    super.key,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.onInfoTap,
    required this.onDetailsTap,
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
          CircleAvatar(
            radius: 32,
            backgroundImage: AssetImage(
              role.toLowerCase() == "pharmacist"
                  ? "assets/logo/pharmacist.jpg"
                  : "assets/logo/patient.jpg",
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                Text(role, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onInfoTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xff2260FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("Info",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                   /* const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {},
                      icon: const Icon(Icons.calendar_month),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: onDetailsTap,
                      icon: const Icon(Icons.info_outline),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () async {},
                      icon: const Icon(Icons.favorite_border),
                    ),*/
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
