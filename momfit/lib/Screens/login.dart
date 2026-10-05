import 'package:MomFit/Screens/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin.dart';
import 'additionalData.dart';
import 'dashboard.dart';

class login extends StatefulWidget {
  static const String idScreen = "login";
  @override
  _loginState createState() => _loginState();
}

class _loginState extends State<login> {
  bool _isObscured = true;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 180),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.pink.shade200,
              child: const Icon(Icons.favorite, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              "MomFit",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              "Your pregnancy wellness companion",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome Back",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email address",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: _isObscured,
                    decoration: InputDecoration(
                      hintText: "Password",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _isObscured ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!emailController.text.contains("@")) {
                          displayToastMessage("Email address is not valid", context);
                        } else if (passwordController.text.isEmpty) {
                          displayToastMessage("Password is mandatory.", context);
                        } else {
                          loginAndAuthenticateUser(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.pink.shade400,
                      ),
                      child: const Text(
                        "Sign In",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don’t have an account?",
                    style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (context) => register()));
                  },
                  child: Text("Sign Up",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade400)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void loginAndAuthenticateUser(BuildContext context) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final User? firebaseUser = (await _firebaseAuth.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text))
          .user;

      if (firebaseUser != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userid', firebaseUser.uid);

        firestore.collection("users").doc(firebaseUser.uid).snapshots().listen((snapshot) async {
          await prefs.setString('email', snapshot["email"].toString());
          await prefs.setString('name', snapshot["name"].toString());
          await prefs.setString('userType', snapshot["userType"].toString());

          print(snapshot["additional_data"]);

          final additionalData = snapshot["additional_data"].toString();

          await prefs.setString('additional_data', additionalData.toString()+"");

          displayToastMessage("Welcome", context);
          if(snapshot["userType"].toString()=="admin"){
            Navigator.push(context,MaterialPageRoute(builder: (context) => Admin()));
          }else if(snapshot["userType"].toString()=="doctor"){
            //Navigator.push(context,MaterialPageRoute(builder: (context) => doctor()));
          } else {
            String? pregDate = snapshot["personalInformation"]["pregnantDate"].toString();
            if (pregDate != null && pregDate.isNotEmpty) {
              try {
                List<String> parts = pregDate.split("-");
                DateTime start = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
                int weeks = DateTime.now().difference(start).inDays ~/ 7;
                int selectedTrimester=0;
                if (weeks < 13)
                  selectedTrimester = 0;
                else if (weeks < 27)
                  selectedTrimester = 1;
                else
                  selectedTrimester = 2;

                await prefs.setString('trimester', selectedTrimester.toString()+" Trimester • Week "+weeks.toString());

              } catch (_) {}
            }
            if(int.parse(additionalData.toString())==1){
              Navigator.push(context,MaterialPageRoute(builder: (context) => Dashboard()));
            }else{
              Navigator.push(context,MaterialPageRoute(builder: (context) => AdditionalDataPage()));
            }
          }
        });
      }
    } catch (e) {
      displayToastMessage("Error: ${e.toString()}", context);
    }
  }
}

displayToastMessage(String message, BuildContext context) {
  Fluttertoast.showToast(msg: message);
}
