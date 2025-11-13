import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../widgets/widget_medicines_time.dart';

class ViewMedicinesScreen extends StatefulWidget {
  const ViewMedicinesScreen({super.key});

  @override
  State<ViewMedicinesScreen> createState() => _ViewMedicinesScreenState();
}

class _ViewMedicinesScreenState extends State<ViewMedicinesScreen> {
  bool _isDescending = true;
  String _searchText = "";
  bool _isNameAsc = true;
  String _sortBy = "date";
  bool _isSearching = false;
  final FlutterTts _flutterTts = FlutterTts();
  String _currentTtsText = "";
  String? _selectedTime;

  final TextEditingController _searchController = TextEditingController();
  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US"); // لو عايزة عربي خليه "ar-SA"
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }
  Future<void> _updateTimeStatus(String docId, String time, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medications')
        .doc(docId);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return;

    final data = docSnapshot.data()!;
    final List<dynamic> times = List.from(data['times'] ?? []);

    final updatedTimes = times.map((entry) {
      if (entry['time'] == time) {
        return {
          'time': entry['time'],
          'status': newStatus,
        };
      }
      return entry;
    }).toList();

    await docRef.update({'times': updatedTimes});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$time marked as $newStatus")),
    );
  }
  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search medicines",
            hintStyle: const TextStyle(
                color: Color(0xff2260FF), fontWeight: FontWeight.w500),
            filled: true,
            fillColor: const Color(0xFFE0E7FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: const Icon(Icons.search, color: Color(0xff2260FF)),
          ),
          onChanged: (value) {
            setState(() {
              _searchText = value.trim().toLowerCase();
            });
          },
        )
            : const Text(
          "View Medicines",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff2260FF),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff2260FF)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff2260FF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Color(0xff2260FF)),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchText = "";
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xff2260FF)),
            onPressed: () {
              setState(() {
                _sortBy = "name"; // تفعيل الترتيب حسب الاسم
                _isNameAsc = !_isNameAsc; // قلب الترتيب حسب الاسم
              });
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("Please log in to view reminders"))
          : Column(
        children: [
          const SizedBox(height: 20),
          _buildSortBy(),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('medications')
                  .orderBy(_sortBy == "date" ? 'date' : 'medicine',
                  descending: _sortBy == "date" ? _isDescending : !_isNameAsc)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reminders found."));
                }

                // فلترة حسب البحث
                final medicines = snapshot.data!.docs.where((doc) {
                  final medicineName =
                  (doc['medicine'] ?? '').toString().toLowerCase();
                  return medicineName.contains(_searchText);
                }).toList();

                // ترتيب حسب الاختيار (التاريخ أو الاسم)
                medicines.sort((a, b) {
                  final dateA =
                      (a['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final dateB =
                      (b['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final nameA = (a['medicine'] ?? '').toString().toLowerCase();
                  final nameB = (b['medicine'] ?? '').toString().toLowerCase();

                  if (_sortBy == "date") {
                    // ترتيب التاريخ أولاً
                    final dateCompare =
                    _isDescending ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
                    if (dateCompare != 0) return dateCompare;
                    // لو التاريخ نفس الشيء، ترتيب الاسم
                    return _isNameAsc ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
                  } else {
                    // ترتيب الاسم أولاً
                    final nameCompare =
                    _isNameAsc ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
                    if (nameCompare != 0) return nameCompare;
                    // لو الاسم نفس الشيء، ترتيب التاريخ
                    return _isDescending ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
                  }
                });

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: medicines.map(_buildMedicineCard).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBy() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text(
            "Sort By Date:",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _sortBy = "date"; // تفعيل الترتيب حسب التاريخ
                _isDescending = !_isDescending; // قلب الترتيب حسب التاريخ
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    _isDescending ? "Newest First" : "Oldest First",
                    style: const TextStyle(
                        color: Color(0xff2260FF), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Color(0xff2260FF),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(DocumentSnapshot medicineDoc) {
    final medicine = medicineDoc.data() as Map<String, dynamic>;
    final String name = medicine['medicine'] ?? 'Unknown';
    final String dosage = medicine['dosage'] ?? 'Not specified';
    final String comments = medicine['comments'] ?? 'No comments';
    final DateTime date =
        (medicine['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final List<Map<String, dynamic>> times =
    List<Map<String, dynamic>>.from(medicine['times'] ?? []);
    final String formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final String timesString =
    times.isNotEmpty ? times.join(', ') : 'No times specified';

    return Card(
      color: const Color(0xFFE0E7FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$name\n",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  _buildDetailRow("Dose: ", dosage),
                  _buildDetailRow("Date: ", formattedDate),
                  _buildDetailRow("Comments: ", comments),
                ],
              ),
              style: const TextStyle(height: 1.5, color: Colors.black87),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Times:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: times.map((timeData) {
                    return MedicineTimeChip(
                      time: timeData['time'],
                      status: timeData['status'],
                      onSelected: (selectedTime) {
                        _selectedTime = selectedTime;
                      },
                    );
                  }).toList(),
                )
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [

                    _buildActionButton(
                      "Take",
                      isPrimary: false,
                      onPressed: () {
                        if (_selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please select a time first")),
                          );
                          return;
                        }
                        _updateTimeStatus(medicineDoc.id, _selectedTime!, 'taken');

                        setState(() {
                          _selectedTime = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),

                    _buildActionButton(
                      "Not Take",
                      isPrimary: false,
                      onPressed: () {
                        if (_selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please select a time first")),
                          );
                          return;
                        }
                        _updateTimeStatus(medicineDoc.id, _selectedTime!, 'missed');

                        setState(() {
                          _selectedTime = null;
                        });
                      },
                    ),



                  ],
                ),
                _buildActionButton(
                  "Convert To Audio",
                  icon: Icons.volume_up_outlined,
                  isPrimary: true,
                  onPressed: () async {
                    final textToRead =
                        "Medicine: $name. "
                        "Dose: $dosage. "
                        "Date: $formattedDate. "
                        "Times: $timesString. "
                        "Comments: $comments.";

                    // لو النص نفسه شغال، نوقف الصوت
                    if (_currentTtsText == textToRead) {
                      await _flutterTts.stop();
                      _currentTtsText = ""; // نص حالي فارغ بعد الإيقاف
                    }

                    // نخزن النص الحالي
                    _currentTtsText = textToRead;

                    // نبدأ الصوت
                    await _flutterTts.stop(); // يوقف أي صوت شغال
                    await _speak(textToRead);
                  },
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildDetailRow(String title, String value) {
    return TextSpan(
      children: [
        TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "$value\n"),
      ],
    );
  }

  Widget _buildActionButton(
      String label, {
        IconData? icon,
        bool isPrimary = false,
        VoidCallback? onPressed,
      }) {
    return ElevatedButton(
      onPressed: () async {
        // أول حاجة نوقف أي صوت شغال
        await _flutterTts.stop();
        // بعدين ننفذ الكود الأصلي للزرار لو موجود
        if (onPressed != null) onPressed();
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isPrimary ? Colors.white : Color(0xff2260FF),
        backgroundColor: isPrimary ? Color(0xff2260FF) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 6),
          ],
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void deactivate() {
    _flutterTts.stop();
    super.deactivate();
  }
}