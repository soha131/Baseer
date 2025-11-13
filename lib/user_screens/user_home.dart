import 'package:baseer/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'patient_reports_screen.dart';
import '../widgets/widget_chat.dart';
import '../widgets/widget_notification.dart';
import '../auth_screeens/ProfileScreen.dart';
import '../chat_screen.dart';
import 'FavoritePharmacistsScreen.dart';

final dashboardUserKey = GlobalKey<_UserDashboardScreenState>();

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState
    extends State<UserDashboardScreen> {
  String? fullName;
  int _selectedIndex = 0;
  String searchQuery = '';
  final List<Widget> _pages = [];
  final List<Map<String, dynamic>> _availablePages = [];
  final TextEditingController _searchController = TextEditingController(); // ✅ أضفنا ده

  @override
  @override
  void initState() {
    super.initState();
    _loadUserName();

    // ✅ عدلنا الصفحات هنا لتكون هي نفسها الموجودة في الكروت
    _availablePages.addAll([
      {
        'title': 'Medication reminders',
        'icon': Icons.alarm,
        'onTap': (BuildContext context) {
          Navigator.pushNamed(context, AppRoutes.medicationReminder);
        },
      },
      {
        'title': 'View pharmacists',
        'icon': Icons.person,
        'onTap': (BuildContext context) {
          Navigator.pushNamed(context, AppRoutes.viewPharmacist);
        },
      },
      {
        'title': 'Medicines Screening',
        'icon': Icons.qr_code_scanner,
        'onTap': (BuildContext context) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Medicines Screening coming soon!"),
            ),
          );
        },
      },
      {
        'title': 'View Medicines',
        'icon': Icons.local_hospital,
        'onTap': (BuildContext context) {
          Navigator.pushNamed(context, AppRoutes.viewMedicines);
        },
      },
      {
        'title': 'Medical Report',
        'icon': Icons.description,
        'onTap': (BuildContext context) {
          Navigator.pushNamed(context, AppRoutes.medicalReport);
        },
      },
      {
        'title': 'Favorite Pharmacists',
        'icon': Icons.favorite_border_sharp,
        'onTap': (BuildContext context) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FavoritePharmacistsScreen(),
            ),
          );
        },
      },
      {
        'title': 'Chat',
        'icon': Icons.chat_bubble_outline,
        'onTap': (BuildContext context) {
          dashboardUserKey.currentState?.setState(() {
            dashboardUserKey.currentState!._selectedIndex = 1;
          });
        },
      },
      {
        'title': 'Profile',
        'icon': Icons.person_outline,
        'onTap': (BuildContext context) {
          dashboardUserKey.currentState?.setState(() {
            dashboardUserKey.currentState!._selectedIndex = 2;
          });
        },
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_month,
        'onTap': (BuildContext context) {
          dashboardUserKey.currentState?.setState(() {
            dashboardUserKey.currentState!._selectedIndex = 3;
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
      const ChatsListScreen(),         // صفحة الشات
      const ProfileScreen(),      // البروفايل
      const PatientReportsScreen(),     // صفحة الكالندر
    ]);

    return Scaffold(
        key:dashboardUserKey,
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
              // صورة + اسم المستخدم
              Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage("assets/logo/patient.jpg"),
                  ),

                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hi, WelcomeBack",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        fullName ?? "User",
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
              // ايقونات
              Row(
                children: [
                  NotificationIconWithBadge(),
                  IconButton(
                    onPressed: ()async {
                      await FirebaseAuth.instance.signOut();

                      /*  final prefs = await SharedPreferences.getInstance();
                          await prefs.remove("biometricEnabled");
*/
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
// 🔹 إضافة كود داخل UserDashboardScreen
              IconButton(
                icon: const Icon(Icons.favorite_border_sharp, color: Color(0xff2260FF)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FavoritePharmacistsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              const Text(
                "Favorite",
                style: TextStyle(color: Color(0xff2260FF), fontSize: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25), // بيضاوي
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
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  icon: Icons.alarm,
                  title: "Medication reminders",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.medicationReminder,
                    );
                  },),
                _buildDashboardCard(
                    icon: Icons.person,
                    title: "View pharmacists",
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.viewPharmacist,
                      );
                    }),
                _buildDashboardCard(
                  icon: Icons.qr_code_scanner,
                  title: "Medicines Screening",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.scanMedicine,
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.local_hospital,
                  title: "View Medicines",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.viewMedicines,
                    );

                  },
                ),
                _buildDashboardCard(
                    icon: Icons.description,
                    title: "Medical Report",
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.medicalReport,
                      );

                    }),
              ],
            ),
          ),
        ),

      ],
    );
  }

  // 🔹 Widget للكارت
  Widget _buildDashboardCard(
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
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
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 2,
              offset: const Offset(2, 2),
            )
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
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 40, color: Colors.black87),
                  const SizedBox(width: 10),
                  Container(
                    width: 70,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(0xff1A3AA9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "View",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
