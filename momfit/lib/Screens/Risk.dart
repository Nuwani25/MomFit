import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'RecommendationPage.dart';
import 'base_url.dart';

class Risk extends StatefulWidget {
  @override
  _RiskState createState() => _RiskState();
}

class _RiskState extends State<Risk> {
  TextEditingController ageController = TextEditingController();
  TextEditingController bmiController = TextEditingController();

  String? previousComplications;
  String? preexistingDiabetes;
  String? bp;
  String? bloodSugar;
  String? heartRate;

  final yesNoOptions = ['Yes', 'No'];
  final heartRateOptions = ['Normal', 'High', 'Low'];

  bool isLoading = false;

  Future<void> sendFormData() async {
    if (ageController.text.isEmpty ||
        bmiController.text.isEmpty ||
        previousComplications == null ||
        preexistingDiabetes == null ||
        bp == null ||
        bloodSugar == null ||
        heartRate == null) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL:1111/risk'),
      );

      String prevCompVal = (previousComplications == "Yes") ? "1" : "0";
      String diabetesVal = (preexistingDiabetes == "Yes") ? "1" : "0";
      String bpVal = (bp == "Yes") ? "1" : "0";
      String sugarVal = (bloodSugar == "Yes") ? "1" : "0";

      String heartRateVal = "1";
      if (heartRate == "Normal") heartRateVal = "1";
      if (heartRate == "High") heartRateVal = "2";
      if (heartRate == "Low") heartRateVal = "3";

      request.fields['age'] = ageController.text;
      request.fields['bmi'] = bmiController.text;
      request.fields['previous_complications'] = prevCompVal;
      request.fields['preexisting_diabetes'] = diabetesVal;
      request.fields['bp'] = bpVal;
      request.fields['blood_sugar'] = sugarVal;
      request.fields['heart_rate'] = heartRateVal;

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decoded = jsonDecode(responseString);
        String res = decoded["result"].toString();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text("Risk Prediction"),
            content: Text(res + " Risk"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecommendationPage(riskLevel: res),
                    ),
                  );
                },
                child: Text(
                  "Next",
                  style: TextStyle(color: Colors.pink.shade400),
                ),
              ),
            ],
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
        title: Text("Risk Prediction"),
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
                  buildTextField(ageController, "Age", TextInputType.number),
                  SizedBox(height: 16),
                  buildTextField(bmiController, "BMI", TextInputType.number),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Previous Complications",
                    yesNoOptions,
                    previousComplications,
                    (val) => setState(() => previousComplications = val),
                  ),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Preexisting Diabetes",
                    yesNoOptions,
                    preexistingDiabetes,
                    (val) => setState(() => preexistingDiabetes = val),
                  ),
                  SizedBox(height: 16),
                  buildDropdown(
                    "BP",
                    yesNoOptions,
                    bp,
                    (val) => setState(() => bp = val),
                  ),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Blood Sugar",
                    yesNoOptions,
                    bloodSugar,
                    (val) => setState(() => bloodSugar = val),
                  ),
                  SizedBox(height: 16),
                  buildDropdown(
                    "Heart Rate",
                    heartRateOptions,
                    heartRate,
                    (val) => setState(() => heartRate = val),
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
                              "Predict Risk",
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
        DropdownButtonFormField<String>(
          value: value,
          hint: Text("Select $label"),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
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
}
