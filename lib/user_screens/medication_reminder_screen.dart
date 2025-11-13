import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notifications/notification_service.dart';

class MedicationReminderScreen extends StatefulWidget {
  final String? medicineName; // ← اسم الدواء لو موجود

  const MedicationReminderScreen({super.key, this.medicineName});
  @override
  State<MedicationReminderScreen> createState() =>
      _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedTimes = ['10:00 AM'];

  DateTime _currentWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday % 7),
  );

  final List<String> _availableTimes = [
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:55 AM',
    '1:00 AM',
    '1:30 PM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
  ];
  @override
  void initState() {
    super.initState();

    if (widget.medicineName != null) {
      _medicineController.text = widget.medicineName!;
    }
  }

  // Controllers
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();


  // helpers.dart
  DateTime parseTimeManually(String time, DateTime date) {
    time = time.replaceAll(RegExp(r'\s+'), '');
    final RegExp regex = RegExp(
      r'(\d{1,2}):(\d{2})(AM|PM)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(time.toUpperCase());

    if (match == null) {
      throw FormatException('Invalid time format: $time');
    }

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String period = match.group(3)!;

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> scheduleMedicineNotifications(
      Map<String, dynamic> medicine,
      ) async {
    final String name = medicine['medicine'] ?? 'Unknown';
    final DateTime date = medicine['date'] ?? DateTime.now();
    final List<dynamic> times = medicine['times'] ?? [];

    debugPrint("Current time: ${DateTime.now()}");

    for (var time in times) {
      try {
        final scheduledTime = parseTimeManually(time.toString(), date);
        debugPrint("Scheduling notification for $name at $scheduledTime");

        DateTime finalTime = scheduledTime;

        // ✅ لو الوقت فات، نزوده يوم تلقائياً
        if (scheduledTime.isBefore(DateTime.now())) {
          finalTime = scheduledTime.add(const Duration(days: 1));
          debugPrint(
            "⏰ الوقت $scheduledTime فات، تم تأجيل الإشعار لـ $finalTime",
          );
        }

        final int notificationId = Random().nextInt(1000000);

        await NotificationService.scheduleNotification(
          id: notificationId,
          title: "💊 تذكير الدواء",
          body: "حان وقت تناول دواء: $name",
          scheduledTime: finalTime,
        );

        debugPrint("✅ Notification scheduled successfully for $finalTime");
      } catch (e) {
        debugPrint("❌ خطأ أثناء جدولة الإشعار للوقت: $time => $e");
      }
    }
  }

  Future<void> _saveReminder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a time.")));
      return;
    }

    try {
      final reminderData = {
        "medicine": _medicineController.text,
        "dosage": _dosageController.text,
        "comments": _commentsController.text,
        "date": _selectedDate,
        "times":
            _selectedTimes
                .map(
                  (time) => {
                    "time": time,
                    "status": "pending", // الحالة المبدئية لكل ميعاد
                  },
                )
                .toList(),
        "createdAt": Timestamp.now(),
      };

      // حفظ البيانات في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medications')
          .add(reminderData);

      // جدولة إشعارات الدواء
      await scheduleMedicineNotifications(reminderData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حفظ الدواء وضبط الإشعارات ✅")),
      );

      _medicineController.clear();
      _dosageController.clear();
      _commentsController.clear();
      setState(() {
        _selectedTimes = ['10:00 AM'];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xff2260FF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xff2260FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Medication reminders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(),
              const SizedBox(height: 24),
              const Text(
                'Available Time',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildTimeSelector(),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      //  bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _currentWeekStart = pickedDate.subtract(
                        Duration(days: pickedDate.weekday % 7),
                      );
                    });
                  }
                },
                child: Row(
                  children: [
                    Text(
                      "${_currentWeekStart.month}-${_currentWeekStart.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentWeekStart = _currentWeekStart.subtract(
                      const Duration(days: 7),
                    );
                  });
                },
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (index) {
                      final dayDate = _currentWeekStart.add(
                        Duration(days: index),
                      );
                      final dayNum = dayDate.day;
                      final dayName =
                          [
                            "SUN",
                            "MON",
                            "TUE",
                            "WED",
                            "THU",
                            "FRI",
                            "SAT",
                          ][dayDate.weekday % 7];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildDayItem(dayDate, dayNum, dayName),
                      );
                    }),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentWeekStart = _currentWeekStart.add(
                      const Duration(days: 7),
                    );
                  });
                },
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(DateTime fullDate, int day, String dayName) {
    final bool isSelected =
        _selectedDate.day == day &&
        _selectedDate.month == fullDate.month &&
        _selectedDate.year == fullDate.year;

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = fullDate),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff2260FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              dayName,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Wrap(
      spacing: 5.0,
      runSpacing: 8.0,
      children:
          _availableTimes.map((time) {
            final bool isSelected = _selectedTimes.contains(
              time,
            ); // Check if time is in list
            return ChoiceChip(
              label: Text(time),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTimes.add(time); // Add time to list
                  } else {
                    _selectedTimes.remove(time); // Remove time from list
                  }
                });
              },
              backgroundColor: const Color(0xFFE0E7FF),
              selectedColor: const Color(0xff2260FF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xff2260FF),
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              showCheckmark: false,
            );
          }).toList(),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'Choose the medicine',
          'Choose the medicine',
          _medicineController,
        ),
        const SizedBox(height: 16),
        _buildTextField('Dosage', 'Dosage', _dosageController),
        const SizedBox(height: 16),
        _buildTextField(
          'Comments',
          'Your Comments',
          _commentsController,
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveReminder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2260FF),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Add',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xff2260FF),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFE0E7FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }



}
