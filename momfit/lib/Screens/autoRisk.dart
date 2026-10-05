import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ProfilePage.dart';
import 'RecommendationPage.dart';
import 'base_url.dart';

class AutoRisk extends StatefulWidget {
  @override
  _AutoRiskState createState() => _AutoRiskState();
}

class _AutoRiskState extends State<AutoRisk> {
  String? riskLevel;
  bool isLoading = true;
  String? userId;

  // Firestore fields
  int? age;
  double? bmi;
  String? complications;
  String? bloodPressure;
  String? bloodSugar;
  String? heartRate;
  int weeks=0;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndPredict();
  }

  Future<void> _loadUserIdAndPredict() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('userid');

      if (uid == null) {
        Fluttertoast.showToast(msg: "No user ID found in SharedPreferences");
        setState(() => isLoading = false);
        return;
      }

      setState(() => userId = uid);
      await _fetchAndPredictRisk(uid);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading user ID: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAndPredictRisk(String uid) async {
    try {
      DocumentSnapshot snapshot =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (!snapshot.exists) {
        Fluttertoast.showToast(msg: "No user data found");
        setState(() => isLoading = false);
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>;
      var personal = data["personalInformation"] ?? {};
      var medical = data["medicalHistory"] ?? {};
      var health = data["healthInfo"] ?? {};
      var prePregnancy = data["prePregnancy"] ?? {};

      print(prePregnancy);

      age = personal["age"];
      bmi = double.tryParse(personal["bmi"].toString()) ?? 0;
      complications = (prePregnancy["previousComplications"] == true) ? "Yes" : "None";
      bloodPressure = (medical["highBloodPressure"] == true) ? "High" : "Normal";
      bloodSugar = (medical["diabetes"] == true) ? "High" : "Normal";
      heartRate = health["heartRate"].toString();

      String? pregDate = personal["pregnantDate"];
      if (pregDate != null && pregDate.isNotEmpty) {
        try {
          List<String> parts = pregDate.split("-");
          DateTime start = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          int week = DateTime.now().difference(start).inDays ~/ 7;

          setState(() {
            weeks=week;
          });

        } catch (_) {}
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL:1111/risk'),
      );

      request.fields['age'] = (age ?? 0).toString();
      request.fields['bmi'] = (bmi ?? 0).toString();
      request.fields['previous_complications'] =
      (prePregnancy["previousComplications"] == true) ? "1" : "0";
      request.fields['preexisting_diabetes'] =
      (medical["diabetes"] == true) ? "1" : "0";
      request.fields['bp'] =
      (medical["highBloodPressure"] == true) ? "1" : "0";
      request.fields['blood_sugar'] =
      (medical["diabetes"] == true) ? "1" : "0";

      String heartRateVal = "1";
      if (heartRate != null) {
        if (heartRate! == "High") heartRateVal = "2"; // High
        else if (heartRate! == "Low") heartRateVal = "3"; // Low
        else heartRateVal = "1"; // Normal
      }
      request.fields['heart_rate'] = heartRateVal;

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decoded = jsonDecode(responseString);
        setState(() {
          riskLevel = decoded["result"].toString();
          isLoading = false;
        });
      } else {
        Fluttertoast.showToast(msg: "Server Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text("Exercise Recommendations"),
        backgroundColor: Colors.pink.shade400,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (riskLevel == null)
          ? const Center(child: Text("Unable to load risk data"))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    Color riskColor = Colors.orange;
    if (riskLevel!.toLowerCase() == "high") riskColor = Colors.red;
    if (riskLevel!.toLowerCase() == "low") riskColor = Colors.green;
    if (riskLevel!.toLowerCase() == "medium") riskColor = Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // === Risk Assessment Card ===
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: const [
                    Icon(Icons.favorite, color: Colors.pink),
                    SizedBox(width: 8),
                    Text(
                      "Risk Assessment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Risk Level Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Risk Level",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${riskLevel!.toUpperCase()} Risk",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Week "+weeks.toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Safe to exercise",
                        style:
                        TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Assessment Details Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Assessment Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfilePage()),
                        );
                      },
                      child: const Icon(Icons.edit, color: Colors.pink, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildInfoRow("Age", "${age ?? 'N/A'} years"),
                _buildInfoRow("BMI", "${bmi?.toStringAsFixed(1) ?? 'N/A'} (Normal)"),
                _buildInfoRow("Complications", complications ?? "None"),
                _buildInfoRow("Blood Pressure", bloodPressure ?? "Normal"),
                _buildInfoRow("Blood Sugar", bloodSugar ?? "Normal"),
                _buildInfoRow("Heart Rate", heartRate ?? "Normal"),

                const SizedBox(height: 20),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecommendationPage(
                              riskLevel: riskLevel.toString()),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Let's Get Started",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20)
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "⚠️ Safety Reminder:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 12),
                GuidelinesItem("Always get approval from your doctor before starting"),
                GuidelinesItem("Warm up for 3–5 minutes (gentle walking or arm circles)."),
                GuidelinesItem("Breathe normally—don’t hold your breath."),
                GuidelinesItem("Stop if you feel pain, dizziness, contractions, bleeding, or unusual shortness of breath."),
                GuidelinesItem("Use pillows, walls, or chairs for support when needed."),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class GuidelinesItem extends StatelessWidget {
  final String text;
  const GuidelinesItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
