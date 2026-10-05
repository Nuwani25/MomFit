import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dashboard.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController bmiController = TextEditingController();
  final TextEditingController pregnantDateController = TextEditingController();

  String? selectedCuisine;
  String? selectedFitness;
  String? selectedDiet;
  String? selectedEducation;
  String? heartRate;
  String? activityBeforePregnancy;

  bool highBloodPressure = false;
  bool diabetes = false;
  bool anemia = false;
  bool renalDisease = false;
  bool malignancies = false;
  bool shellfishAllergy = false;
  bool redMeatAllergy = false;
  bool ironSupplement = false;
  bool previousComplications = false;
  bool twinPregnancy = false;
  bool familyDiabetes = false;
  bool familyHypertension = false;
  bool familyHematology = false;

  bool isLoading = true;
  bool isSaving = false;

  final cuisineOptions = ["Sinhala", "Tamil", "Muslim"];
  final fitnessOptions = ["Beginner", "Intermediate", "Advanced"];
  final dietOptions = ["Any", "Vegetarian"];
  final educationOptions = ["None", "Primary", "Secondary", "Higher"];
  final heartRateOptions = ["Low", "Normal", "High"];
  final activityOptions = ["Sedentary", "Moderately Active", "Very Active"];

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          final personal = data["personalInformation"] ?? {};
          final lifestyle = data["lifestyle"] ?? {};
          final medical = data["medicalHistory"] ?? {};
          final health = data["healthInfo"] ?? {};
          final prePregnancy = data["prePregnancy"] ?? {};
          final family = data["familyHistory"] ?? {};

          setState(() {
            ageController.text = personal["age"]?.toString() ?? "";
            heightController.text = personal["height"]?.toString() ?? "";
            weightController.text = personal["currentWeight"]?.toString() ?? "";
            bmiController.text = personal["bmi"]?.toString() ?? "";
            pregnantDateController.text = personal["pregnantDate"] ?? "";
            selectedCuisine = personal["ethnicity"];

            selectedFitness = lifestyle["fitnessLevel"];
            selectedDiet = lifestyle["dietaryPreference"];
            selectedEducation = lifestyle["educationLevel"];

            highBloodPressure = medical["highBloodPressure"] ?? false;
            diabetes = medical["diabetes"] ?? false;
            anemia = medical["anemia"] ?? false;
            renalDisease = medical["renalDisease"] ?? false;
            malignancies = medical["malignancies"] ?? false;

            heartRate = health["heartRate"];
            shellfishAllergy = health["allergyShellfish"] ?? false;
            redMeatAllergy = health["allergyRedMeat"] ?? false;
            ironSupplement = health["ironSupplement"] ?? false;

            activityBeforePregnancy = prePregnancy["activity"];
            previousComplications =
                prePregnancy["previousComplications"] ?? false;
            twinPregnancy = prePregnancy["twinPregnancy"] ?? false;

            familyDiabetes = family["diabetes"] ?? false;
            familyHypertension = family["hypertension"] ?? false;
            familyHematology = family["hematology"] ?? false;
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "⚠️ Error loading profile: $e");
    }

    setState(() => isLoading = false);
  }

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

  Future<void> saveProfile() async {
    setState(() => isSaving = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "personalInformation": {
          "age": int.tryParse(ageController.text) ?? 0,
          "height": int.tryParse(heightController.text) ?? 0,
          "currentWeight": int.tryParse(weightController.text) ?? 0,
          "bmi": double.tryParse(bmiController.text) ?? 0,
          "ethnicity": selectedCuisine,
          "pregnantDate": pregnantDateController.text,
        },
        "lifestyle": {
          "fitnessLevel": selectedFitness,
          "dietaryPreference": selectedDiet,
          "educationLevel": selectedEducation,
        },
        "medicalHistory": {
          "highBloodPressure": highBloodPressure,
          "diabetes": diabetes,
          "anemia": anemia,
          "renalDisease": renalDisease,
          "malignancies": malignancies,
        },
        "healthInfo": {
          "heartRate": heartRate,
          "allergyShellfish": shellfishAllergy,
          "allergyRedMeat": redMeatAllergy,
          "ironSupplement": ironSupplement,
        },
        "prePregnancy": {
          "activity": activityBeforePregnancy,
          "previousComplications": previousComplications,
          "twinPregnancy": twinPregnancy,
        },
        "familyHistory": {
          "diabetes": familyDiabetes,
          "hypertension": familyHypertension,
          "hematology": familyHematology,
        },
      }, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "✅ Profile updated!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Dashboard()),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "❌ Error saving profile: $e");
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.pink.shade400,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle("Personal Information"),
                  buildTextField(
                    ageController,
                    "Age (Years)",
                    TextInputType.number,
                  ),
                  buildTextField(
                    heightController,
                    "Height (cm)",
                    TextInputType.number,
                    onChanged: (_) => calculateBMI(),
                  ),
                  buildTextField(
                    weightController,
                    "Current Weight (kg)",
                    TextInputType.number,
                    onChanged: (_) => calculateBMI(),
                  ),
                  buildDisabledField(bmiController, "BMI (calculated)"),
                  buildDropdown(
                    "Ethnicity",
                    cuisineOptions,
                    selectedCuisine,
                    (val) => setState(() => selectedCuisine = val),
                  ),
                  buildDateField(
                    "Pregnant Date (Approximately)",
                    pregnantDateController,
                  ),

                  sectionTitle("Lifestyle"),
                  buildDropdown(
                    "Fitness Level",
                    fitnessOptions,
                    selectedFitness,
                    (val) => setState(() => selectedFitness = val),
                  ),
                  buildDropdown(
                    "Dietary Preference",
                    dietOptions,
                    selectedDiet,
                    (val) => setState(() => selectedDiet = val),
                  ),
                  buildDropdown(
                    "Education Level",
                    educationOptions,
                    selectedEducation,
                    (val) => setState(() => selectedEducation = val),
                  ),

                  sectionTitle("Medical History"),
                  buildSwitch(
                    "High blood pressure",
                    highBloodPressure,
                    (val) => setState(() => highBloodPressure = val),
                  ),
                  buildSwitch(
                    "Diabetes",
                    diabetes,
                    (val) => setState(() => diabetes = val),
                  ),
                  buildSwitch(
                    "Anemia",
                    anemia,
                    (val) => setState(() => anemia = val),
                  ),
                  buildSwitch(
                    "Renal disease",
                    renalDisease,
                    (val) => setState(() => renalDisease = val),
                  ),
                  buildSwitch(
                    "Malignancies",
                    malignancies,
                    (val) => setState(() => malignancies = val),
                  ),

                  sectionTitle("Health Information"),
                  buildDropdown(
                    "Heart Rate",
                    heartRateOptions,
                    heartRate,
                    (val) => setState(() => heartRate = val),
                  ),
                  buildSwitch(
                    "Shellfish Allergy",
                    shellfishAllergy,
                    (val) => setState(() => shellfishAllergy = val),
                  ),
                  buildSwitch(
                    "Red Meat Allergy",
                    redMeatAllergy,
                    (val) => setState(() => redMeatAllergy = val),
                  ),
                  buildSwitch(
                    "Iron Supplement",
                    ironSupplement,
                    (val) => setState(() => ironSupplement = val),
                  ),

                  sectionTitle("Pre-pregnancy Information"),
                  buildDropdown(
                    "Activity Before Pregnancy",
                    activityOptions,
                    activityBeforePregnancy,
                    (val) => setState(() => activityBeforePregnancy = val),
                  ),
                  buildSwitch(
                    "Previous Complications",
                    previousComplications,
                    (val) => setState(() => previousComplications = val),
                  ),
                  buildSwitch(
                    "Twin/Multiple Pregnancies",
                    twinPregnancy,
                    (val) => setState(() => twinPregnancy = val),
                  ),

                  sectionTitle("Family History"),
                  buildSwitch(
                    "Family history of Diabetes",
                    familyDiabetes,
                    (val) => setState(() => familyDiabetes = val),
                  ),
                  buildSwitch(
                    "Family history of Hypertension",
                    familyHypertension,
                    (val) => setState(() => familyHypertension = val),
                  ),
                  buildSwitch(
                    "Family history of Hematological Diseases",
                    familyHematology,
                    (val) => setState(() => familyHematology = val),
                  ),

                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveProfile,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Reusable Widgets ----------

  Widget sectionTitle(String text) => Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.pink.shade400,
      ),
    ),
  );

  Widget buildTextField(
    TextEditingController controller,
    String label,
    TextInputType type, {
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
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
      ),
    );
  }

  Widget buildDisabledField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
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
      ),
    );
  }

  Widget buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 6),
          TextField(
            controller: controller,
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
        ],
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final bool isSelected = value == item;
              return GestureDetector(
                onTap: () => onChanged(item),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink.shade50 : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? Colors.pink.shade400
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.pink,
    );
  }
}
