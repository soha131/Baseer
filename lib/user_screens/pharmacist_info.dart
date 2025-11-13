import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

import '../notifications/notification_service.dart';
import '../routes.dart';

class PharmacistInfoScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const PharmacistInfoScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<PharmacistInfoScreen> createState() => _PharmacistInfoScreenState();
}

class _PharmacistInfoScreenState extends State<PharmacistInfoScreen> {
  late FlutterTts flutterTts;
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
  String _formatDob(dynamic dobRaw) {
    if (dobRaw == null) return "N/A";

    DateTime? dob;
    if (dobRaw is Timestamp) {
      dob = dobRaw.toDate();
    } else if (dobRaw is String) {
      dob = DateTime.tryParse(dobRaw);
    }

    if (dob == null) return "N/A";
    return DateFormat("dd/MM/yyyy").format(dob);
  }
  int? _calculateAge(dynamic dobRaw) {
    DateTime? dob;
    if (dobRaw is Timestamp) {
      dob = dobRaw.toDate();
    } else if (dobRaw is String) {
      dob = DateTime.tryParse(dobRaw);
    }

    if (dob == null) return null;

    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }
  void _showSendConsultationstDialog() {
    final TextEditingController treatmentController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Send Consultations the pharmacist", style: TextStyle(fontSize: 16)),
        content: TextField(
            controller: treatmentController,
            maxLines: 5,

            decoration: InputDecoration(
              hintText: "Enter Consultations here...",
              hintStyle: const TextStyle(color: Color(0xff2260FF)),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xffECF1FF)),
              ),
              enabledBorder:  OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xffECF1FF)),
              ),
              focusedBorder:  OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xff2260FF), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xffECF1FF),
            )
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff2260FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              child: const Text("Send", style: TextStyle(color: Colors.white),),
              onPressed: () async {
                final text = treatmentController.text.trim();
                if (text.isEmpty || currentUser == null) return;

                final patientId = currentUser.uid;
                final pharmacistId = widget.userId;

                // ✅ جلب بيانات المريض
                final pharmacistDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(pharmacistId)
                    .get();

                final pharmacistFcmToken = pharmacistDoc.data()?['fcmToken'];

                // ✅ ID ثابت للشات (نفس الترتيب دايماً)
                final chatId = patientId.compareTo(pharmacistId) < 0
                    ? '${patientId}_$pharmacistId'
                    : '${pharmacistId}_$patientId';

                final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

                // تأكد إن الشات موجود
                await chatRef.set({
                  'users': [patientId, pharmacistId],
                  'lastMessage': text,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // أضف الرسالة
                await chatRef.collection('messages').add({
                  'senderId': patientId,
                  'receiverId': pharmacistId,
                  'text': text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'isRead': false,
                });

                if (pharmacistFcmToken != null && pharmacistFcmToken.toString().isNotEmpty) {
                  // 🔔 جلب بيانات الدكتور من Firestore
                  final doctorDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(patientId)
                      .get();
                  final patientName = doctorDoc.data()?['fullName'] ?? "الدكتور";

                  // 🔔 إرسال إشعار فوري للمريض
                  await NotificationService.sendToSpecificUser(
                    title: "رسالة جديدة من $patientName",
                    body: text,
                    fcmToken: pharmacistFcmToken,
                  );

                  // 🔔 تسجيل الإشعار في collection الخاص بالمريض
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(pharmacistId)
                      .collection("notifications")
                      .add({
                    "title": "رسالة جديدة من $patientName",
                    "body": text,
                    "createdAt": FieldValue.serverTimestamp(),
                    "isRead": false,
                    "type": "new_message",
                  });
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Message sent successfully ✅")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();

    // إعدادات الصوت
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak() async {
    final name = widget.userData["fullName"] ?? "Unknown";
    final email = widget.userData["email"] ?? "N/A";
    final mobile = widget.userData["mobile"] ?? "N/A";
    final role = widget.userData["role"] ?? "N/A";
    final status = widget.userData["status"] ?? "N/A";
    final dob = widget.userData["dob"] ?? "N/A";
    final likesCount = widget.userData["likesCount"];

    final dobFormatted = _formatDob(dob);

    String text = """
    Pharmacist Information:
    Name: $name.
    Email: $email.
    Mobile: $mobile.
    Date of Birth: $dobFormatted.
    Role: $role.
    Status: $status.
    Likes Count: $likesCount.
    """;

    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData["fullName"] ?? "Unknown";
    final email = widget.userData["email"] ?? "N/A";
    final mobile = widget.userData["mobile"] ?? "N/A";
    final role = widget.userData["role"] ?? "N/A";
    final status = widget.userData["status"] ?? "N/A";
    final dobRaw = widget.userData["dob"];
    final likesCount = widget.userData["likesCount"];

    final dobFormatted = _formatDob(dobRaw);
    final age = _calculateAge(dobRaw);

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
              // 🔹 Pharmacist Profile Card
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
                      backgroundImage: AssetImage(  "assets/logo/pharmacist.jpg"),
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Badge for status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      "$name ${age != null ? "($age yrs)" : ""}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(role, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:  [
                        Icon(Icons.star, color: Color(0xff2260FF)),
                        SizedBox(width: 4),
                        Text("${likesCount ?? 0}"),
                       /* SizedBox(width: 12),
                        Icon(Icons.calendar_today, color: Color(0xff2260FF)),
                        SizedBox(width: 4),
                        Text("Mon-Sat / 9:00AM - 5:00PM"),*/
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Profile & Career Path
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
                            Expanded(child: Text("DOB: $dobFormatted")),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Role: $role")),
                          ],
                        ),
                      ],
                    )

                   /* const SizedBox(height: 14),
                    const Text("Career Path",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                        "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
                  */
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff2260FF),
                        minimumSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _speak,
                      child: const Text(
                        "Convert To Audio",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff2260FF),
                        minimumSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _showSendConsultationstDialog,
                      child: const Text(
                        "Send",
                        style: TextStyle(color: Colors.white),
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
      //bottomNavigationBar: _bottomNav(),
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
  }

}
