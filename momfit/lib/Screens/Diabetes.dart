import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'base_url.dart';
import 'diabetesData.dart';

class DiabetesFinder extends StatefulWidget {
  @override
  _DiabetesFinderState createState() => _DiabetesFinderState();
}

class _DiabetesFinderState extends State<DiabetesFinder> {
  TextEditingController ageController = TextEditingController();
  TextEditingController bmiController = TextEditingController();
  TextEditingController week8Controller = TextEditingController();
  TextEditingController ogttFastingController = TextEditingController();
  TextEditingController ogttOneHourController = TextEditingController();
  TextEditingController ogttTwoHourController = TextEditingController();

  String? selectedFHDiabetes;

  final yesNoOptions = ['Yes', 'No'];
  final fhDiabetesMap = {'No': 0, 'Yes': 1};

  bool isLoading = false;
  bool isFetching = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
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

      setState(() {
        ageController.text =
            data['personalInformation']['age']?.toString() ?? '';
        bmiController.text =
            data['personalInformation']['bmi']?.toString() ?? '';
        ogttFastingController.text = data['fasting']?.toString() ?? '';
        ogttOneHourController.text = data['one_hr']?.toString() ?? '';
        ogttTwoHourController.text = data['two_hr']?.toString() ?? '';
        week8Controller.text = data['postprandial_glucose']?.toString() ?? '';
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching data: $e");
    }

    setState(() => isFetching = false);
  }

  Future<void> sendFormData() async {
    if (ageController.text.isEmpty ||
        bmiController.text.isEmpty ||
        selectedFHDiabetes == null ||
        week8Controller.text.isEmpty ||
        ogttFastingController.text.isEmpty ||
        ogttOneHourController.text.isEmpty ||
        ogttTwoHourController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL:1111/diabetes'),
      );

      request.fields['age_years'] = ageController.text;
      request.fields['bmi_prepreg'] = bmiController.text;
      request.fields['fh_diabetes'] = fhDiabetesMap[selectedFHDiabetes]
          .toString();
      request.fields['Blood_suger_week_8'] = week8Controller.text;
      request.fields['Bloog_suger_OGTT_Fasting'] = ogttFastingController.text;
      request.fields['Blood_suger_OGTT_one_hour'] = ogttOneHourController.text;
      request.fields['Blood_suger_OGTT_two_hour'] = ogttTwoHourController.text;

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decoded = jsonDecode(responseString);
        String result = decoded["result"].toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DiabetesData(predictedValue: double.parse(result)),
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
        title: Text("Diabetes Finder"),
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
                          "Age (years)",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          bmiController,
                          "Pre-pregnancy BMI",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildDropdown(
                          "Family History of Diabetes",
                          yesNoOptions,
                          selectedFHDiabetes,
                          (val) => setState(() => selectedFHDiabetes = val),
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          week8Controller,
                          "Blood Sugar Week 8",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          ogttFastingController,
                          "OGTT Fasting",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          ogttOneHourController,
                          "OGTT One Hour",
                          TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        buildTextField(
                          ogttTwoHourController,
                          "OGTT Two Hour",
                          TextInputType.number,
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
                                    "Predict Diabetes Risk",
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
