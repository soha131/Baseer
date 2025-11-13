import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PatientReportsScreen extends StatefulWidget {
  const PatientReportsScreen({super.key});

  @override
  State<PatientReportsScreen> createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen> {
  int takenCount = 0;
  int missedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMedicineStats();
  }

  Future<void> _loadMedicineStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final medsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medications')
        .get();

    int totalTaken = 0;
    int totalMissed = 0;

    for (var doc in medsSnapshot.docs) {
      final data = doc.data();
      final List times = List.from(data['times'] ?? []);

      for (var time in times) {
        if (time['status'] == 'taken') totalTaken++;
        if (time['status'] == 'missed') totalMissed++;
      }
    }

    setState(() {
      takenCount = totalTaken;
      missedCount = totalMissed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = takenCount + missedCount;
    final adherence = total > 0 ? ((takenCount / total) * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F0FF), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Medicine Statistics',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[800]),
              ),
              const SizedBox(height: 30),

              // Circular Indicator
              CircularPercentIndicator(
                radius: 90.0,
                lineWidth: 12.0,
                percent: total > 0 ? takenCount / total : 0,
                center: Text(
                  '$adherence%',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                progressColor: Colors.blueAccent,
                backgroundColor: Colors.grey.shade300,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
              ),
              const SizedBox(height: 30),

              _buildStatCard('Taken Doses', takenCount, Colors.green, Icons.check_circle),
              const SizedBox(height: 12),
              _buildStatCard('Missed Doses', missedCount, Colors.red, Icons.cancel),
              const SizedBox(height: 20),

              Divider(color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                'Adherence Rate: $adherence%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(height: 10),
              Text(
                'Last updated: ${DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.now())}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 30,
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(
                  '$count doses',
                  style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
