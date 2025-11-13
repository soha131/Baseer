import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes.dart';
import 'edit_medical_report.dart';

class MedicalReportScreen extends StatefulWidget {
  const MedicalReportScreen({super.key});

  @override
  State<MedicalReportScreen> createState() => _MedicalReportScreenState();
}

class _MedicalReportScreenState extends State<MedicalReportScreen> {
  Map<String, dynamic>? reportData;
  bool isLoading = true;
  String? fullName;
  int _selectedIndex = 0;

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
  @override
  void initState() {
    super.initState();
    _loadReport();
    _loadUserName();

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
  Future<void> _loadReport() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("medical_report")
        .doc("report")
        .get();

    if (doc.exists) {
      setState(() {
        reportData = doc.data();
        isLoading = false;
      });
    } else {
      setState(() {
        reportData = {};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Medical Report",
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(  "assets/logo/patient.jpg"),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                fullName ?? "User",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Profile",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xff2260FF)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Any Chronic Illnesses: ${reportData?['chronicIllness'] ?? 'None'}\n"
                  "Blood Type: ${reportData?['bloodType'] ?? 'None'}\n"
                  "Weight: ${reportData?['weight'] ?? 'None'}\n"
                  "Current Medication: ${reportData?['medication'] ?? 'None'}\n"
                  "Allergies: ${reportData?['allergies'] ?? 'None'}\n"
                  "Medical History (Any Surgery): ${reportData?['history'] ?? 'None'}\n"
                  "Healthy Habits: ${reportData?['habits'] ?? 'None'}",
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff2260FF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditMedicalReportScreen()),
                ).then((_) => _loadReport()); // بعد الرجوع يعمل refresh
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Edit Medical Report",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff2260FF),
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
  }}
