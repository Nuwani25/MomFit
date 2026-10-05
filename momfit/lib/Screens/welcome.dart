import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin.dart';
import 'additionalData.dart';
import 'dashboard.dart';
import 'login.dart';

class WelcomeScreen extends StatefulWidget {
  static const String idScreen = "welcomeScreen";

  @override
  _WelcomeScreen createState() => _WelcomeScreen();
}

class _WelcomeScreen extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    navigateScreen(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.pink.shade200,
              child: const Icon(Icons.favorite, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              "MomFit",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your pregnancy wellness companion",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 50),
            const SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                strokeWidth: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void navigateScreen(BuildContext context) async {
    var d = const Duration(seconds: 3);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Future.delayed(d, () {
      if (prefs.getString('email') != null) {
        if (prefs.getString("userType").toString() == "admin") {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Admin()));
        } else if (prefs.getString("userType").toString() == "doctor") {
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Doctor()));
        } else {
          if(int.parse(prefs.getString("additional_data").toString())==1){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Dashboard()));
          }else{
            Navigator.push(context,MaterialPageRoute(builder: (context) => AdditionalDataPage()));
          }
        }
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => login()));
      }
    });
  }
}
