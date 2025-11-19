import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../routes.dart';

class UserInfoScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserInfoScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // ✅ Home
      Navigator.pushReplacementNamed(context, AppRoutes.admin);
    } else if (index == 1) {
      // ✅ Profile
      Navigator.pushReplacementNamed(context, AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;
    final userId = widget.userId;

    final name = userData["fullName"] ?? "Unknown";
    final email = userData["email"] ?? "N/A";
    final mobile = userData["mobile"] ?? "N/A";
    final role = userData["role"] ?? "N/A";
    final status = userData["status"] ?? "N/A";
    final likesCount = userData["likesCount"];

    // ✅ DOB handling
    String dob = "N/A";
    if (userData["dob"] != null) {
      if (userData["dob"] is Timestamp) {
        final date = (userData["dob"] as Timestamp).toDate();
        dob = DateFormat("yyyy-MM-dd").format(date);
      } else if (userData["dob"] is String) {
        dob = userData["dob"];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Info",
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 🔹 Profile Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffDCEBFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [

                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(
                        role.toLowerCase() == "pharmacist"
                            ? "assets/logo/pharmacist.jpg"
                            : "assets/logo/patient.jpg",
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Badge for status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == "approved"
                            ? Colors.green
                            : status == "rejected"
                            ? Colors.red
                            : Colors.orange, // pending
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(role,
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:  [
                          Icon(Icons.star, color: Color(0xff2260FF))
                          ,SizedBox(width: 4),
                        Text("${likesCount ?? 0}"),

                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Profile",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text("Email: $email")),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Mobile: $mobile")),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text("DOB: $dob")),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Role: $role")),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (role == "Pharmacist" &&
                            userData["careerPath"] != null &&
                            userData["careerPath"].toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text("Career Path: ${userData["careerPath"]}"),
                        ],

                      ],
                    )

                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Approve / Reject buttons
              if (role == "Pharmacist" && status == "pending")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:Color(0xff2260FF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(userId)
                                .update({"status": "approved"});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Pharmacist has been approved successfully ✅",
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text("Approve",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(userId)
                                .update({"status": "rejected"});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Pharmacist request has been rejected ❌",
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          child: const Text("Reject",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
     // bottomNavigationBar: _bottomNav(),
    );
  }


}
