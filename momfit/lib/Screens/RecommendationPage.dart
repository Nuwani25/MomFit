import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ExerciseRecommendation.dart';
import 'base_url.dart';

class RecommendationPage extends StatefulWidget {
  final String riskLevel;

  RecommendationPage({required this.riskLevel});

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  String? trimester;
  String? fitnessLevel;
  String? complications;
  String? goal;
  String? activity;

  final trimesterOptions = ["1", "2", "3"];
  final fitnessOptions = ["Advanced", "Beginner", "Intermediate"];
  final complicationOptions = [
    "Back Pain",
    "Back Pain, Pelvic Floor Weakness",
    "Diastasis Recti",
    "Gestational Diabetes",
    "None",
    "Pelvic Floor Weakness",
    "Pelvic Girdle Pain",
  ];
  final goalOptions = [
    "Back Pain Relief",
    "Core Strengthening",
    "General Fitness",
    "None",
    "Pelvic Floor Strengthening",
    "Weight Control",
  ];
  final activityOptions = ["Moderately Active", "Sedentary", "Very Active"];

  bool isLoading = false;
  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userid');

      if (userId == null) {
        Fluttertoast.showToast(msg: "No user ID found.");
        setState(() => isFetching = false);
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;

        String? pregDate = data["personalInformation"]?["pregnantDate"];
        String? firebaseTrimester;
        if (pregDate != null && pregDate.isNotEmpty) {
          try {
            List<String> parts = pregDate.split("-");
            DateTime start = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
            int weeks = DateTime.now().difference(start).inDays ~/ 7;
            if (weeks < 13)
              firebaseTrimester = "1";
            else if (weeks < 27)
              firebaseTrimester = "2";
            else
              firebaseTrimester = "3";
          } catch (_) {}
        }
        String? firebaseFitness = data["lifestyle"]?["fitnessLevel"]
            ?.toString();
        String? firebaseActivity = data["prePregnancy"]?["activity"]
            ?.toString();

        setState(() {
          if (firebaseTrimester != null &&
              trimesterOptions.contains(firebaseTrimester)) {
            trimester = firebaseTrimester;
          }
          if (firebaseFitness != null &&
              fitnessOptions.contains(firebaseFitness)) {
            fitnessLevel = firebaseFitness;
          }
          if (firebaseActivity != null &&
              activityOptions.contains(firebaseActivity)) {
            activity = firebaseActivity;
          }
          isFetching = false;
        });
      } else {
        Fluttertoast.showToast(msg: "User data not found.");
        setState(() => isFetching = false);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading user data: $e");
      setState(() => isFetching = false);
    }
  }

  Future<void> sendRecommendation() async {
    if (trimester == null ||
        fitnessLevel == null ||
        complications == null ||
        goal == null ||
        activity == null) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL:1111/recom'),
      );
      String riskVal = (widget.riskLevel == "High") ? "0" : "1";
      String trimesterVal = (int.parse(trimester!) - 1).toString();
      String fitnessVal = {
        "Advanced": "0",
        "Beginner": "1",
        "Intermediate": "2",
      }[fitnessLevel]!;
      String complicationVal = complicationOptions
          .indexOf(complications!)
          .toString();
      String goalVal = goalOptions.indexOf(goal!).toString();
      String activityVal = {
        "Moderately Active": "0",
        "Sedentary": "1",
        "Very Active": "2",
      }[activity]!;

      request.fields['risk'] = riskVal;
      request.fields['trimester'] = trimesterVal;
      request.fields['fitness_level'] = fitnessVal;
      request.fields['pregnancy_complications'] = complicationVal;
      request.fields['specific_goal'] = goalVal;
      request.fields['activity_before_pregnancy'] = activityVal;

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decoded = jsonDecode(responseString);
        String result = decoded["result"].toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseRecommendationPage(
              predictedCategory: int.parse(result),
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "Server Error: ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isFetching) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: Text("Recommendations"),
        backgroundColor: Colors.pink.shade400,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Container(
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
              Column(
                children: [
                  buildReadOnlyField("Risk Level", widget.riskLevel),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Trimester",
                    trimesterOptions,
                    trimester,
                    (val) => setState(() => trimester = val),
                  ),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Fitness Level",
                    fitnessOptions,
                    fitnessLevel,
                    (val) => setState(() => fitnessLevel = val),
                  ),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Pregnancy Complications",
                    complicationOptions,
                    complications,
                    (val) => setState(() => complications = val),
                  ),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Specific Goal",
                    goalOptions,
                    goal,
                    (val) => setState(() => goal = val),
                  ),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Activity Before Pregnancy",
                    activityOptions,
                    activity,
                    (val) => setState(() => activity = val),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : sendRecommendation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Submit",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Label left-aligned
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),

          // ---- Buttons Column ----
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items.map((item) {
              final bool isSelected = value == item;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: GestureDetector(
                  onTap: () => onChanged(item),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: double.infinity, // makes each button full-width
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.pink.shade50 : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.pink.shade400
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.pink.shade400
                            : Colors.grey[800],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
