import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _selectedDob;
  bool _loading = false;
  String _role = "user"; // قيمة افتراضية

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data["fullName"] ?? "";
      _phoneController.text = data["mobile"] ?? "";
      _emailController.text = data["email"] ?? "";

      // قراءة الـ role
      _role = data["role"] ?? "user";

      // التعامل مع الـ DOB
      var dobData = data["dob"];
      if (dobData != null && dobData is Timestamp) {
        _selectedDob = dobData.toDate();
        _dobController.text =
        "${_selectedDob!.day.toString().padLeft(2, '0')} / "
            "${_selectedDob!.month.toString().padLeft(2, '0')} / "
            "${_selectedDob!.year}";
      }

      setState(() {});
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "fullName": _nameController.text.trim(),
        "mobile": _phoneController.text.trim(),
        "dob": _selectedDob != null ? Timestamp.fromDate(_selectedDob!) : null,
        // الايميل مش هيتغير هنا
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تحديث البيانات بنجاح ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:Color(0xff2260FF),
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff2260FF)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xff2260FF)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/welcome');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔹 Profile Picture
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        _role.toLowerCase() == "user"
                            ? "assets/logo/patient.jpg"
                            : _role.toLowerCase() == "pharmacist"
                            ? "assets/logo/pharmacist.jpg"
                            : "assets/logo/admin.jpg",
                      ),
                    ),


                    Container(
                      decoration: const BoxDecoration(
                          color:Color(0xff2260FF), shape: BoxShape.circle),
                      padding: const EdgeInsets.all(6),
                      child:
                      const Icon(Icons.edit, size: 16, color: Colors.white),
                    )
                  ],
                ),

                const SizedBox(height: 30),

                // 🔹 Form Fields
                _buildTextField(
                    controller: _nameController, label: "Full Name", hint: "Ahmed"),
                const SizedBox(height: 16),

                _buildTextField(
                    controller: _phoneController, label: "Phone Number", hint: "+966"),
                const SizedBox(height: 16),

                _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    hint: "ahmed@gmail.com",
                    readOnly: true), // 👈 الايميل مش بيتعدل
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _dobController,
                  label: "Date Of Birth",
                  hint: "DD / MM / YYYY",
                  isBlue: true,
                  readOnly: true,
                  onTap: () async {
                    DateTime initialDate = _selectedDob ?? DateTime(2000);
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      _selectedDob = pickedDate;
                      String formattedDate =
                          "${pickedDate.day.toString().padLeft(2, '0')} / "
                          "${pickedDate.month.toString().padLeft(2, '0')} / "
                          "${pickedDate.year}";
                      setState(() {
                        _dobController.text = formattedDate;
                      });
                    }
                  },
                ),

                const SizedBox(height: 40),

                // 🔹 Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff2260FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading ? null : _updateProfile,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Update Profile",
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Reusable TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isBlue = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffEAF0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            validator: (value) {
              if (!readOnly && (value == null || value.isEmpty)) {
                return "$label is required";
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: isBlue ? Color(0xff2260FF) : Colors.black87, fontSize: 18),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
