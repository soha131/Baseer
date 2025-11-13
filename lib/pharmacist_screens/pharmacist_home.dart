import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pharmacist_reports_screen.dart';
import '../widgets/widget_notification.dart';
import '../auth_screeens/ProfileScreen.dart';
import '../chat_screen.dart';
import '../routes.dart';
import '../reports_screen.dart';
import '../widgets/widget_chat.dart';
final dashboardKey = GlobalKey<_PharmacistDashboardScreenState>();
class PharmacistDashboardScreen extends StatefulWidget {
  const PharmacistDashboardScreen({super.key});

  @override
  State<PharmacistDashboardScreen> createState() =>
      _PharmacistDashboardScreenState();
}

class _PharmacistDashboardScreenState
    extends State<PharmacistDashboardScreen> {
  String? fullName;
  int _selectedIndex = 0;
  String searchQuery = '';
  final List<Widget> _pages = [];
  final List<Map<String, dynamic>> _availablePages = [];
  final TextEditingController _searchController = TextEditingController(); // ✅ أضفنا ده

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _availablePages.addAll([
      {
        'title': 'View Patients',
        'icon': Icons.person,
        'onTap': (BuildContext context) {
          Navigator.pushNamed(context, AppRoutes.viewPatient);
        },
      },
      {
        'title': 'Edit Profile',
        'icon': Icons.edit_document,
        'onTap': (BuildContext context) {
          dashboardKey.currentState?.setState(() {
            dashboardKey.currentState!._selectedIndex = 2;
          });
        },
      },
      {
        'title': 'Chat',
        'icon': Icons.chat_bubble_outline,
        'onTap': (BuildContext context) {
          dashboardKey.currentState?.setState(() {
            dashboardKey.currentState!._selectedIndex = 1;
          });
        },
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_month,
        'onTap': (BuildContext context) {
          dashboardKey.currentState?.setState(() {
            dashboardKey.currentState!._selectedIndex = 3;
          });
        },
      },
    ]);
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          fullName = doc.data()!["fullName"] ?? "Pharmacist";
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    _pages.clear();
    _pages.addAll([
      _buildDashboard(), // الهوم
      const ChatsListScreen(),        // صفحة الشات
      const ProfileScreen(),      // البروفايل
      const PharmacistStatisticsScreen(),     // صفحة الكالندر
    ]);

    return Scaffold(
      key: dashboardKey,
      backgroundColor: const Color(0xffEAF5FF),
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xff2260FF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items:  [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: ChatIconWithBadge(isSelected: _selectedIndex == 1),
              label: "Chat",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Reports"),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // 🔹 Header: صورة + اسم + أيقونات
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage("assets/logo/pharmacist.jpg"),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hi, Welcome Back",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        "Ph.$fullName",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  NotificationIconWithBadge(),
                  IconButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/welcome');
                    },
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🔹 Search Bar + Shortcuts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
           /*   Column(
                children: const [
                  Icon(Icons.headphones_outlined, color: Colors.blue),
                  SizedBox(height: 6),
                  Text("Doctor", style: TextStyle(color: Colors.blue, fontSize: 14)),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                children: const [
                  Icon(Icons.favorite_border, color: Colors.blue),
                  SizedBox(height: 6),
                  Text("Favorite", style: TextStyle(color: Colors.blue, fontSize: 14)),
                ],
              ),*/
              const SizedBox(width: 25),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Search pages...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (searchQuery.isNotEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final filteredPages = _availablePages
                      .where((page) =>
                      page['title'].toLowerCase().contains(searchQuery))
                      .toList();

                  if (filteredPages.isEmpty) {
                    return const Center(
                      child: Text(
                        "No matching pages found ",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 16,
                    children: filteredPages
                        .map<Widget>((page) => _buildDashboardCard(
                      icon: page['icon'],
                      title: page['title'],
                      onTap: () => page['onTap'](context),
                    ))
                        .toList(),
                  );
                },
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    icon: Icons.person,
                    title: "View Patients",
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.viewPatient);
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.edit_document,
                    title: "Edit Profile",
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

      ],
    );
  }

// 🔹 Card Widget
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
        onTap: () {
          setState(() {
            searchQuery = '';
            _searchController.clear(); // ✅ تصفير النص
          });
          onTap(); // بعدها يفتح الصفحة
        },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 2,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 40, color: Colors.black87),
                  Container(
                    width: 70,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xff1A3AA9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "View",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
