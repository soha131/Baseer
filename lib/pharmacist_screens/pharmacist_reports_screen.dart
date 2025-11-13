import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PharmacistStatisticsScreen extends StatefulWidget {
  const PharmacistStatisticsScreen({super.key});

  @override
  State<PharmacistStatisticsScreen> createState() =>
      _PharmacistStatisticsScreenState();
}

class _PharmacistStatisticsScreenState
    extends State<PharmacistStatisticsScreen> with TickerProviderStateMixin {
  bool loading = true;
  List<Map<String, dynamic>> patientStats = [];
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadAllPatientsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPatientsData() async {
    setState(() {
      loading = true;
    });

    // نجيب بس اليوزرز اللي role = "user"
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'User')
        .get();

    List<Map<String, dynamic>> statsList = [];

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final medsSnapshot = await userDoc.reference.collection('medications').get();

      int taken = 0;
      int missed = 0;

      for (var med in medsSnapshot.docs) {
        final data = med.data();
        final List times = List.from(data['times'] ?? []);
        for (var t in times) {
          if (t['status'] == 'taken') taken++;
          if (t['status'] == 'missed') missed++;
        }
      }

      final total = taken + missed;
      final adherence = total > 0 ? (taken / total * 100) : 0;

      statsList.add({
        'name': userData['fullName'] ?? 'Unknown',
        'taken': taken,
        'missed': missed,
        'adherence': adherence.toDouble(),
      });
    }

    setState(() {
      patientStats = statsList;
      loading = false;
    });
  }

// نفس الشيء في دالة جلب أدوية المريض
  Future<List<Map<String, dynamic>>> _getPatientMeds(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('fullName', isEqualTo: name)
        .where('role', isEqualTo: 'User') // هنا نضيف الشرط
        .get();
    if (snapshot.docs.isEmpty) return [];
    final userDoc = snapshot.docs.first;
    final medsSnapshot = await userDoc.reference.collection('medications').get();
    return medsSnapshot.docs.map((doc) => doc.data()).toList();
  }


  Color _getBarColor(double adherence) {
    if (adherence > 70) {
      return Colors.green;
    } else if (adherence > 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Patients Statistics",
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff2260FF)),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Color(0xff2260FF)),
        ),
      body: SafeArea(
        child:loading
          ? const Center(child: CircularProgressIndicator())
          : patientStats.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              "No patients data found",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAllPatientsData,
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barGroups: patientStats.map((p) {
                            final index = patientStats.indexOf(p);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: (p['adherence'] as double) *
                                      _animationController.value,
                                  width: 14,
                                  borderRadius: BorderRadius.circular(6),
                                  color: _getBarColor(p['adherence']),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  if (value < 0 ||
                                      value >= patientStats.length) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Text(
                                        patientStats[value.toInt()]['name'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, _) => Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Detailed Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...patientStats.map(
                          (p) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: ExpansionTile(
                          leading: CircularPercentIndicator(
                            radius: 28,
                            lineWidth: 5,
                            percent: (p['adherence'] as double) / 100,
                            center: Text(
                              '${(p['adherence'] as double).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            progressColor: _getBarColor(p['adherence']),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          title: Text(
                            p['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Taken: ${p['taken']} | Missed: ${p['missed']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          children: [
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _getPatientMeds(p['name']),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const CircularProgressIndicator();
                                final meds = snapshot.data!;
                                if (meds.isEmpty) {
                                  return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("No medications found."),
                                );
                                }
                                return Column(
                                  children: meds.map((med) {
                                    final List times = med['times'] ?? [];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(med['medicine'] ?? 'Unknown',
                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ...times.map((t) => Text('${t['time']} - ${t['status']}',
                                              style: const TextStyle(fontSize: 13))),
                                          const Divider(),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
          ))])




          );
        }),
      ),
    ));
  }

}
