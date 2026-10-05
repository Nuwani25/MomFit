import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard.dart';

class AdditionalDataPage extends StatefulWidget {
  @override
  _AdditionalDataPageState createState() => _AdditionalDataPageState();
}

class _AdditionalDataPageState extends State<AdditionalDataPage> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController bmiController = TextEditingController();
  final TextEditingController pregnantDateController = TextEditingController();

  String? selectedCuisine;
  String? selectedFitness;
  String? selectedDiet;
  String? selectedEducation;

  bool isSaving = false;

  final cuisineOptions = ["Sinhala", "Tamil", "Muslim"];
  final fitnessOptions = ["Beginner", "Intermediate", "Advanced"];
  final dietOptions = ["Any", "Vegetarian"];
  final educationOptions = ["None", "Primary", "Secondary", "Higher"];

  void calculateBMI() {
    if (heightController.text.isNotEmpty && weightController.text.isNotEmpty) {
      double height = double.tryParse(heightController.text) ?? 0;
      double weight = double.tryParse(weightController.text) ?? 0;
      if (height > 0) {
        double bmi = weight / ((height / 100) * (height / 100));
        bmiController.text = bmi.toStringAsFixed(2);
      }
    }
  }

  Future<void> saveFormData() async {
    if (ageController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty ||
        bmiController.text.isEmpty ||
        selectedCuisine == null ||
        pregnantDateController.text.isEmpty ||
        selectedFitness == null ||
        selectedDiet == null ||
        selectedEducation == null) {
      Fluttertoast.showToast(msg: "⚠️ Please fill all fields");
      return;
    }

    setState(() => isSaving = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: "❌ User not logged in");
        return;
      }

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "userid": user.uid,
        "personalInformation": {
          "age": int.parse(ageController.text),
          "height": int.parse(heightController.text),
          "currentWeight": int.parse(weightController.text),
          "bmi": double.parse(bmiController.text),
          "ethnicity": selectedCuisine,
          "pregnantDate": pregnantDateController.text,
        },
        "lifestyle": {
          "fitnessLevel": selectedFitness,
          "dietaryPreference": selectedDiet,
          "educationLevel": selectedEducation,
        },
        "additional_data": 1
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('additional_data', "1");

      Fluttertoast.showToast(msg: "✅ Data saved successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Dashboard()),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "❌ Error: $e");
    }

    setState(() => isSaving = false);
  }

  Future<void> pickPregnantDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        pregnantDateController.text =
        "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile Form"),
        backgroundColor: Colors.pink.shade400,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Personal Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade400,
              ),
            ),
            SizedBox(height: 12),

            buildTextField(ageController, "Age (Years)", TextInputType.number),
            SizedBox(height: 12),

            buildTextField(
              heightController,
              "Height (cm)",
              TextInputType.number,
              onChanged: (_) => calculateBMI(),
            ),
            SizedBox(height: 12),

            buildTextField(
              weightController,
              "Current Weight (kg)",
              TextInputType.number,
              onChanged: (_) => calculateBMI(),
            ),
            SizedBox(height: 12),

            buildDisabledField(bmiController, "BMI (calculated)"),
            SizedBox(height: 12),

            buildDropdown(
              "Ethnicity",
              cuisineOptions,
              selectedCuisine,
                  (val) => setState(() => selectedCuisine = val),
            ),
            SizedBox(height: 12),

            Text(
              "Pregnant Date (Approximately)",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 6),
            TextField(
              controller: pregnantDateController,
              readOnly: true,
              onTap: pickPregnantDate,
              decoration: InputDecoration(
                suffixIcon: Icon(Icons.calendar_today, color: Colors.pink),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 24),

            Text(
              "Lifestyle",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade400,
              ),
            ),
            SizedBox(height: 12),

            buildDropdown(
              "Fitness Level",
              fitnessOptions,
              selectedFitness,
                  (val) => setState(() => selectedFitness = val),
            ),
            SizedBox(height: 12),

            buildDropdown(
              "Dietary Preference",
              dietOptions,
              selectedDiet,
                  (val) => setState(() => selectedDiet = val),
            ),
            SizedBox(height: 12),

            buildDropdown(
              "Education Level",
              educationOptions,
              selectedEducation,
                  (val) => setState(() => selectedEducation = val),
            ),
            SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveFormData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Save Profile",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---- Custom Field Builders with Labels ----

  Widget buildTextField(
      TextEditingController controller,
      String label,
      TextInputType type, {
        Function(String)? onChanged,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
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

  Widget buildDisabledField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
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
