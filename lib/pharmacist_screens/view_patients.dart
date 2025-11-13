import 'package:baseer/pharmacist_screens/patient_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../routes.dart';

class AllPatientsScreen extends StatefulWidget {
  const AllPatientsScreen({super.key});

  @override
  State<AllPatientsScreen> createState() => _AllPatientsScreenState();
}

class _AllPatientsScreenState extends State<AllPatientsScreen> {
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
      Navigator.pushReplacementNamed(context, AppRoutes.pharmacistHome);
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.chatScreen);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, AppRoutes.calenderScreen);
    }
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
            : const Text(
          "All Patients",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff2260FF),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color:  Color(0xff2260FF)),
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

            // 🔹 Sort A-Z / Z-A
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

                ],
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Patients List from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where("role", isEqualTo: "User")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No patients found",
                            style: TextStyle(color: Colors.black54)));
                  }

                  // فلترة لإزالة الأدمن
                  final users = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data["email"] != "admin@gmail.com";
                  }).toList();

                  // 🔹 فلترة حسب البحث
                  List<QueryDocumentSnapshot> filteredUsers = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data["fullName"] ?? "").toString().toLowerCase();
                    return name.contains(searchQuery.toLowerCase());
                  }).toList();

                  // 🔹 ترتيب A-Z / Z-A
                  filteredUsers.sort((a, b) {
                    final nameA = ((a.data() as Map<String, dynamic>)["fullName"] ?? "")
                        .toString()
                        .toLowerCase();
                    final nameB = ((b.data() as Map<String, dynamic>)["fullName"] ?? "")
                        .toString()
                        .toLowerCase();
                    return sortAZ ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
                  });

                  if (filteredUsers.isEmpty) {
                    return const Center(
                        child: Text("No patients found",
                            style: TextStyle(color: Colors.black54)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final data = filteredUsers[index].data() as Map<String, dynamic>;

                      // ✅ حل مشكلة dob (String or Timestamp)
                      String dobText = "";
                      if (data["dob"] is Timestamp) {
                        final ts = data["dob"] as Timestamp;
                        dobText = DateFormat("dd/MM/yyyy").format(ts.toDate());
                      } else if (data["dob"] is String) {
                        dobText = data["dob"];
                      }

                      return PatientCard(
                        name: data["fullName"] ?? "Unknown",
                        age: dobText,
                        condition: data["status"] ?? "N/A",
                        imageUrl:
                        "https://i.pravatar.cc/150?u=${filteredUsers[index].id}",
                        onViewTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientInfoScreen(patientId: filteredUsers[index].id,),

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
   //   bottomNavigationBar: _bottomNav(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ""),
        ],
      ),
    );
  }
}

// 🔹 Patient Card
class PatientCard extends StatelessWidget {
  final String name;
  final String age;
  final String condition;
  final String imageUrl;
  final VoidCallback onViewTap;

  const PatientCard({
    super.key,
    required this.name,
    required this.age,
    required this.condition,
    required this.imageUrl,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffE7EDFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage("assets/logo/patient.jpg"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                Text(age, style: const TextStyle(color: Colors.black54)),
                Text(condition,
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff2260FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            onPressed: onViewTap,
            child: const Text("View", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
