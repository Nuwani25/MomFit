import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'LowBirthWeightResult.dart';
import 'base_url.dart';

class LowBirthWeightPage extends StatefulWidget {
  @override
  _LowBirthWeightPageState createState() => _LowBirthWeightPageState();
}

class _LowBirthWeightPageState extends State<LowBirthWeightPage> {
  TextEditingController ageController = TextEditingController();
  TextEditingController bmiController = TextEditingController();
  TextEditingController gestationalAgeController = TextEditingController();
  TextEditingController systolicController = TextEditingController();
  TextEditingController diastolicController = TextEditingController();
  TextEditingController hemoglobinController = TextEditingController();

  String? selectedDiabetes;
  String? selectedHypertension;
  String? selectedIronSupplement;

  final yesNoOptions = ['Yes', 'No'];

  bool isLoading = false;
  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  /// 🔹 Convert pregnantDate (any format) → weeks
  int calculateGestationalWeeksFromDynamic(dynamic value) {
    try {
      DateTime startDate;

      if (value is Timestamp) {
        startDate = value.toDate();
      } else if (value is String) {
        // Try parsing ISO 8601 first
        try {
          startDate = DateTime.parse(value);
        } catch (_) {
          // Try dd-MM-yyyy
          try {
            final parts = value.split("-");
            if (parts.length == 3) {
              startDate = DateTime(
                int.parse(parts[2]), // year
                int.parse(parts[1]), // month
                int.parse(parts[0]), // day
              );
            } else {
              return 0;
            }
          } catch (e) {
            print("❌ Date parsing failed for string: $value");
            return 0;
          }
        }
      } else {
        print("❌ Unknown pregnantDate type: $value");
        return 0;
      }

      final today = DateTime.now();
      final days = today.difference(startDate).inDays;
      return (days ~/ 7);
    } catch (e) {
      print("❌ calculateGestationalWeeks error: $e");
      return 0;
    }
  }

  Future<void> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: "User not logged in");
        return;
      }

      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        Fluttertoast.showToast(msg: "User data not found");
        return;
      }

      var data = doc.data()!;
      print("🔥 Full User Data: $data");
      print(
        "👉 pregnantDate raw value: ${data['personalInformation']['pregnantDate']}",
      );

      setState(() {
        ageController.text =
            data['personalInformation']['age']?.toString() ?? '';
        bmiController.text =
            data['personalInformation']['bmi']?.toString() ?? '';
        systolicController.text =
            data['healthInfo']['systolic']?.toString() ?? '';
        diastolicController.text =
            data['healthInfo']['diastolic']?.toString() ?? '';
        hemoglobinController.text = data['haemoglobin']?.toString() ?? '';

        final pregnantDateCandidate =
            data['personalInformation']['pregnantDate'];
        final gestWeeksCandidate =
            data['personalInformation']['gestationalAgeWeeks'];

        if (gestWeeksCandidate != null) {
          gestationalAgeController.text = gestWeeksCandidate.toString();
        } else if (pregnantDateCandidate != null) {
          gestationalAgeController.text = calculateGestationalWeeksFromDynamic(
            pregnantDateCandidate,
          ).toString();
        } else {
          gestationalAgeController.text = '';
        }

        selectedDiabetes = (data['medicalHistory']['diabetes'] == true)
            ? "Yes"
            : "No";
        selectedHypertension =
            (data['medicalHistory']['highBloodPressure'] == true)
            ? "Yes"
            : "No";
        selectedIronSupplement = (data['healthInfo']['ironSupplement'] == true)
            ? "Yes"
            : "No";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching data: $e");
    }

    setState(() => isFetching = false);
  }

  Future<void> sendFormData() async {
    if (ageController.text.isEmpty ||
        bmiController.text.isEmpty ||
        gestationalAgeController.text.isEmpty ||
        systolicController.text.isEmpty ||
        diastolicController.text.isEmpty ||
        hemoglobinController.text.isEmpty ||
        selectedDiabetes == null ||
        selectedHypertension == null ||
        selectedIronSupplement == null) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL:1111/birth_weight'),
      );

      String diabetesVal = (selectedDiabetes == "Yes") ? "1" : "0";
      String hypertensionVal = (selectedHypertension == "Yes") ? "1" : "0";
      String ironVal = (selectedIronSupplement == "Yes") ? "1" : "0";

      request.fields['age'] = ageController.text;
      request.fields['pre_pregnancy_bmi'] = bmiController.text;
      request.fields['gestational_age_weeks'] = gestationalAgeController.text;
      request.fields['blood_pressure_systolic'] = systolicController.text;
      request.fields['blood_pressure_diastolic'] = diastolicController.text;
      request.fields['hemoglobin_level'] = hemoglobinController.text;
      request.fields['has_diabetes'] = diabetesVal;
      request.fields['has_hypertension'] = hypertensionVal;
      request.fields['iron_supplementation'] = ironVal;

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decoded = jsonDecode(responseString);
        String result = decoded["result"].toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LowBirthWeightResultPage(prediction: result),
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
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: Text("Low Birth Weight Finder"),
        backgroundColor: Colors.pink.shade400,
      ),
      body: isFetching
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        buildTextField(
                          ageController,
                          "Age (Years)",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          bmiController,
                          "Pre-pregnancy BMI",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          gestationalAgeController,
                          "Gestational Age (Weeks)",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          systolicController,
                          "Blood Pressure Systolic",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          diastolicController,
                          "Blood Pressure Diastolic",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          hemoglobinController,
                          "Hemoglobin Level",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildDropdown(
                          "Has Diabetes",
                          yesNoOptions,
                          selectedDiabetes,
                          (val) => setState(() => selectedDiabetes = val),
                        ),
                        SizedBox(height: 16),
                        buildDropdown(
                          "Has Hypertension",
                          yesNoOptions,
                          selectedHypertension,
                          (val) => setState(() => selectedHypertension = val),
                        ),
                        SizedBox(height: 16),
                        buildDropdown(
                          "Iron Supplementation",
                          yesNoOptions,
                          selectedIronSupplement,
                          (val) => setState(() => selectedIronSupplement = val),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : sendFormData,
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
                                    "Predict Low Birth Weight",
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

  Widget buildTextField(
    TextEditingController controller,
    String label,
    TextInputType type,
  ) {
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
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: "Enter $label",
            filled: true,
            fillColor: Colors.grey.shade100,
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
