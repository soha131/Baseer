import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../notifications/notification_service.dart';

class PatientInfoScreen extends StatefulWidget {
  final String patientId; // 👈 ID المريض
  const PatientInfoScreen({super.key, required this.patientId});

  @override
  State<PatientInfoScreen> createState() => _PatientInfoScreenState();
}

class _PatientInfoScreenState extends State<PatientInfoScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? medicalReport;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMedicalReport();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.patientId) // 👈 استخدمنا الـ patientId
            .get();
    setState(() {
      userData = doc.data();
    });
  }

  Future<void> _loadMedicalReport() async {
    final doc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(widget.patientId) // 👈 استخدمنا الـ patientId
            .collection("medical_report")
            .doc("report")
            .get();
    if (doc.exists) {
      setState(() {
        medicalReport = doc.data();
      });
    }
  }

  String formatDob(dynamic dob) {
    if (dob == null) return "";
    if (dob is Timestamp) {
      return DateFormat("dd/MM/yyyy").format(dob.toDate());
    } else if (dob is String) {
      return dob;
    }
    return "";
  }

  int calculateAge(dynamic dob) {
    if (dob == null) return 0;
    DateTime birthDate;
    if (dob is Timestamp) {
      birthDate = dob.toDate();
    } else if (dob is String) {
      birthDate = DateTime.tryParse(dob) ?? DateTime.now();
    } else {
      return 0;
    }
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // 🔹 ديلوج إضافة العلاج
  void _showAddTreatmentDialog() {
    final TextEditingController messageController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Send Message to Patient",
          style: TextStyle(fontSize: 16),
        ),
        content: TextField(
          controller: messageController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Type your message...",
            hintStyle: const TextStyle(color: Color(0xff2260FF)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xffECF1FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xffECF1FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xff2260FF), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xffECF1FF),
          ),
        ),
        actions: [
          Center(
            child:ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2260FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text("Send", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final text = messageController.text.trim();
                if (text.isEmpty || currentUser == null) return;

                final doctorId = currentUser.uid;
                final patientId = widget.patientId;

                // ✅ جلب بيانات المريض
                final patientDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(patientId)
                    .get();

                final patientFcmToken = patientDoc.data()?['fcmToken'];

                // ✅ ID ثابت للشات (نفس الترتيب دايماً)
                final chatId = doctorId.compareTo(patientId) < 0
                    ? '${doctorId}_$patientId'
                    : '${patientId}_$doctorId';

                final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

                // تأكد إن الشات موجود
                await chatRef.set({
                  'users': [doctorId, patientId],
                  'lastMessage': text,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // أضف الرسالة
                await chatRef.collection('messages').add({
                  'senderId': doctorId,
                  'receiverId': patientId,
                  'text': text,
                  'timestamp': FieldValue.serverTimestamp(),
                  'isRead': false,
                });

                if (patientFcmToken != null && patientFcmToken.toString().isNotEmpty) {
                  // 🔔 جلب بيانات الدكتور من Firestore
                  final doctorDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(doctorId)
                      .get();
                  final doctorName = doctorDoc.data()?['fullName'] ?? "الدكتور";

                  // 🔔 إرسال إشعار فوري للمريض
                  await NotificationService.sendToSpecificUser(
                    title: "رسالة جديدة من $doctorName",
                    body: text,
                    fcmToken: patientFcmToken,
                  );

                  // 🔔 تسجيل الإشعار في collection الخاص بالمريض
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(patientId)
                      .collection("notifications")
                      .add({
                    "title": "رسالة جديدة من $doctorName",
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
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dob = userData!["dob"];
    final age = calculateAge(dob);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Patient Info",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff2260FF)),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff2260FF)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 🔹 Patient Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffE7EDFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (dob != null)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xff2260FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "$age years",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage("assets/logo/patient.jpg"),
                      ),
                      const SizedBox(height: 10),
                      // الاسم + العمر
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userData!["fullName"] ?? "Unknown",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userData!["mobile"] ?? "",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Medical Care Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      medicalReport == null
                          ? const Text(
                            "No medical report available",
                            style: TextStyle(color: Colors.black54),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$age years",
                                style: const TextStyle(
                                  color: Color(0xff2260FF),
                                  fontSize: 16,
                                ),
                              ),

                              Text(
                                "${medicalReport!["bloodType"] ?? "-"}",
                                style: const TextStyle(
                                  color: Color(0xff2260FF),
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "${medicalReport!["history"] ?? "-"}",
                                style: const TextStyle(
                                  color: Color(0xff2260FF),
                                fontSize: 16,
                              ),
                              ),
                              Text(
                                " ${medicalReport!["habits"] ?? "-"}",
                                style: const TextStyle(
                                  color: Color(0xff2260FF),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 15),

                              Text(
                                "${medicalReport!["medication"] ?? "-"}",
                                style: const TextStyle(
                                  color: Color(0xff2260FF),
                                  fontSize: 16,
                                ),
                              ),



                            ],
                          ),
                ),

                const SizedBox(height: 30),

                // 🔹 To Reply Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:Color(0xff2260FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                  ),
                  onPressed: _showAddTreatmentDialog,
                  child: const Text(
                    "To Reply",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
/*
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xff2260FF),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ""),
        ],
      ),
*/
    );
  }
}
