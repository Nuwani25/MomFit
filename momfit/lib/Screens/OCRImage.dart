import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'base_url.dart';

class OCRImage extends StatefulWidget {
  final String method;

  OCRImage({required this.method});

  @override
  _OCRImageState createState() => _OCRImageState();
}

class _OCRImageState extends State<OCRImage> {
  File? _imageFile;
  bool _loading = false;
  String res = "",
      con = "",
      haemoglobin = "",
      postprandial_glucose = "",
      fasting = "",
      one_hr = "",
      two_hr = "";
  final picker = ImagePicker();

  Future<void> _chooseImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _getFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _uploadImage(context) async {
    if (_imageFile == null) {
      Fluttertoast.showToast(msg: "Choose an image first!");
      return;
    }

    setState(() => _loading = true);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseURL:1111/image_upload'),
    );

    request.fields['method'] = widget.method;
    request.files.add(
      await http.MultipartFile.fromPath('photo', _imageFile!.path),
    );

    var response = await request.send();
    var responseString = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var decoded = jsonDecode(responseString);
      if (widget.method == "cbc") {
        setState(() {
          _loading = false;
          res = "haemoglobin value : " + decoded['haemoglobin'];
          haemoglobin = decoded['haemoglobin'];
        });
      } else if (widget.method == "fasting_bs") {
        setState(() {
          _loading = false;
          res =
              "postprandial glucose value : " + decoded['postprandial_glucose'];
          postprandial_glucose = decoded['postprandial_glucose'];
        });
      } else {
        setState(() {
          _loading = false;
          res =
              "fasting value : " +
              decoded['fasting'] +
              " | 1hr value : " +
              decoded['1hr'] +
              " | 2hr value : " +
              decoded['2hr'];
          fasting = decoded['fasting'];
          one_hr = decoded['1hr'];
          two_hr = decoded['2hr'];
        });
      }
    } else {
      setState(() => _loading = false);
      setState(() {
        haemoglobin = "";
        postprandial_glucose = "";
        fasting = "";
        one_hr = "";
        two_hr = "";
      });
      Fluttertoast.showToast(msg: "Upload failed. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade400,
        title: Text(
          "OCR Image",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔹 Image Display or Placeholder
                      _imageFile == null
                          ? Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.pink.shade100),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 80,
                                  color: Colors.pink.shade200,
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                _imageFile!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                      const SizedBox(height: 20),

                      // 🔹 Choose Image Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _chooseImage,
                            icon: const Icon(Icons.photo, color: Colors.white),
                            label: Text(
                              "Gallery",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink.shade400,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _getFromCamera,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Camera",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink.shade400,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🔹 Upload Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _uploadImage(context),
                          icon: const Icon(Icons.upload, color: Colors.white),
                          label: Text(
                            "Upload Image",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(thickness: 1.2, color: Colors.black12),
                      const SizedBox(height: 10),

                      // 🔹 Result Section
                      Text(
                        "Result",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        res.isEmpty ? "No result yet" : res,
                        style: GoogleFonts.poppins(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      res.isEmpty
                          ? SizedBox(height: 5)
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  User? user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) return;

                                  if(postprandial_glucose!=""){
                                    await FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(user.uid)
                                        .set({
                                      "postprandial_glucose":postprandial_glucose
                                    }, SetOptions(merge: true));
                                  }

                                  if(haemoglobin!=""){
                                    await FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(user.uid)
                                        .set({
                                      "haemoglobin": haemoglobin
                                    }, SetOptions(merge: true));
                                  }

                                  if(fasting!=""){
                                    await FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(user.uid)
                                        .set({
                                      "fasting":fasting,
                                      "one_hr":one_hr,
                                      "two_hr":two_hr
                                    }, SetOptions(merge: true));
                                  }


                                  Fluttertoast.showToast(
                                    msg: "Data Save!",
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade300,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "Save",
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
                ),
              ),
            ),
          ),

          // 🔹 Loading overlay
          if (_loading)
            Container(
              color: Colors.white70,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        "Please wait...",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
