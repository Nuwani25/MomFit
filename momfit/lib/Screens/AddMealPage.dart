import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddMealPage extends StatefulWidget {
  @override
  _AddMealPageState createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final TextEditingController _foodDescController = TextEditingController();
  final TextEditingController _calorieController = TextEditingController();
  final TextEditingController _youtubeIdController = TextEditingController();

  int? _selectedCategory;
  String? _selectedMealType;
  File? _selectedImage;

  final List<int> _categories = List.generate(10, (index) => index + 1);
  final List<String> _mealTypes = [
    "Breakfast",
    "Morning Snack",
    "Lunch",
    "Evening Snack",
    "Dinner"
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('meal_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _addMeal() async {
    if (_selectedCategory == null ||
        _selectedMealType == null ||
        _foodDescController.text.isEmpty ||
        _calorieController.text.isEmpty ||
        _selectedImage == null ||
        _youtubeIdController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill in all fields");
      return;
    }

    try {
      String imageUrl = await _uploadImage(_selectedImage!);

      await FirebaseFirestore.instance.collection('meals').add({
        'category': _selectedCategory,
        'mealType': _selectedMealType,
        'foodDescription': _foodDescController.text,
        'calorieCount': int.parse(_calorieController.text),
        'imageUrl': imageUrl,
        'youtubeVideoId': _youtubeIdController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(msg: "Meal Added Successfully");

      // Clear fields
      _foodDescController.clear();
      _calorieController.clear();
      _youtubeIdController.clear();
      setState(() {
        _selectedCategory = null;
        _selectedMealType = null;
        _selectedImage = null;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Add Meal",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _dropdownField(
              "Select Category",
              _categories.map((e) => e.toString()).toList(),
              _selectedCategory?.toString(),
                  (value) => setState(() => _selectedCategory = int.parse(value!)),
            ),
            const SizedBox(height: 16),
            _dropdownField(
              "Select Meal Type",
              _mealTypes,
              _selectedMealType,
                  (value) => setState(() => _selectedMealType = value),
            ),
            const SizedBox(height: 16),
            _labeledTextField("Food Description", _foodDescController,
                maxLines: 3),
            const SizedBox(height: 16),
            _labeledTextField("Calorie Count", _calorieController,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _labeledTextField("YouTube Video ID", _youtubeIdController),
            const SizedBox(height: 16),
            _imagePicker(),
            const SizedBox(height: 24),
            _gradientButton("Save Meal", Colors.indigoAccent, _addMeal),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(String label, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            underline: SizedBox(),
            hint: Text("Select $label"),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _imagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Image",
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _selectedImage == null
                ? Center(child: Icon(Icons.add_a_photo, color: Colors.grey))
                : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Enter $label",
            hintStyle: GoogleFonts.poppins(fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientButton(String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
