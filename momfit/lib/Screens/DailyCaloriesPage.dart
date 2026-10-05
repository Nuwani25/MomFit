import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DailyCaloriePage extends StatefulWidget {
  const DailyCaloriePage({super.key});

  @override
  State<DailyCaloriePage> createState() => _DailyCaloriePageState();
}

class _DailyCaloriePageState extends State<DailyCaloriePage> {
  bool loading = true;
  Map<String, int> dailyCalories = {};

  @override
  void initState() {
    super.initState();
    fetchDailyCalories();
  }

  Future<void> fetchDailyCalories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final last7Days = List.generate(7, (i) => now.subtract(Duration(days: i)));

      Map<String, int> data = {};
      for (var date in last7Days) {
        String key = DateFormat('yyyy-MM-dd').format(date);
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('daily_calories')
            .doc(key)
            .get();

        data[key] = doc.exists ? (doc['calories'] ?? 0) : 0;
      }

      setState(() {
        dailyCalories = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading calories: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = dailyCalories.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayCalories = dailyCalories[todayKey] ?? 0;

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade400,
        title: const Text("Daily Calorie Summary"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchDailyCalories,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(todayCalories),
            const SizedBox(height: 20),
            _buildBarChart(sortedDates),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(int calories) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.pink.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade200.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text("Today’s Total",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 18,
              )),
          const SizedBox(height: 8),
          Text("$calories kcal",
              style: GoogleFonts.poppins(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<String> sortedDates) {
    final chartData = sortedDates
        .map((date) => BarChartGroupData(
      x: sortedDates.indexOf(date),
      barRods: [
        BarChartRodData(
          toY: (dailyCalories[date] ?? 0).toDouble(),
          gradient: LinearGradient(
            colors: [Colors.pink.shade300, Colors.pink.shade600],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    ))
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Last 7 Days",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= sortedDates.length) {
                            return const SizedBox.shrink();
                          }
                          final d = DateFormat('E').format(
                            DateTime.parse(sortedDates[value.toInt()]),
                          );
                          return Text(
                            d.substring(0, 3),
                            style: GoogleFonts.poppins(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: chartData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
