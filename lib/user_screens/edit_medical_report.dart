import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class EditMedicalReportScreen extends StatefulWidget {
  const EditMedicalReportScreen({super.key});

  @override
  State<EditMedicalReportScreen> createState() =>
      _EditMedicalReportScreenState();
}

class _EditMedicalReportScreenState extends State<EditMedicalReportScreen> {
  String? chronicIllness = "no";
  String? bloodType;
  final _weightController = TextEditingController();
  final _medicationController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _historyController = TextEditingController();
  final _habitsController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("medical_report")
        .doc("report")
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        chronicIllness = data['chronicIllness'] ?? "no";
        bloodType = data['bloodType'];
        _weightController.text = data['weight'] ?? "";
        _medicationController.text = data['medication'] ?? "";
        _allergiesController.text = data['allergies'] ?? "";
        _historyController.text = data['history'] ?? "";
        _habitsController.text = data['habits'] ?? "";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveReport() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("medical_report")
        .doc("report")
        .set({
      "chronicIllness": chronicIllness,
      "bloodType": bloodType,
      "weight": _weightController.text,
      "medication": _medicationController.text,
      "allergies": _allergiesController.text,
      "history": _historyController.text,
      "habits": _habitsController.text,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Any Chronic Illnesses",
                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
            Row(
              children: [
                Radio<String>(
                  activeColor: Color(0xff79aedc),
                  value: "yes",
                  groupValue: chronicIllness,
                  onChanged: (val) {
                    setState(() => chronicIllness = val);
                  },
                ),
                const Text("Yes"),
                Radio<String>(
                  activeColor: Color(0xff79aedc),
                  value: "no",
                  groupValue: chronicIllness,
                  onChanged: (val) {
                    setState(() => chronicIllness = val);
                  },
                ),
                const Text("No"),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Blood Type",
                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
            Wrap(
              spacing: 8,
              children: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
                  .map(
                    (type) => ChoiceChip(
                      backgroundColor: Color(0xffEAF5FF),
                  selectedColor: Color(0xff79aedc),
                  label: Text(type),
                  selected: bloodType == type,
                  onSelected: (_) {
                    setState(() => bloodType = type);
                  },
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 20),
            _buildTextField("Weight", _weightController),
            _buildTextField("Current Medication", _medicationController),
            _buildTextField("Allergies (If Any)", _allergiesController),
            _buildTextField("Medical History (Any Surgery)", _historyController),
            _buildTextField("Healthy Habits (If Any)", _habitsController),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:Color(0xff2260FF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () async {
                await saveReport();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Add",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 18
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xffEAF5FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}