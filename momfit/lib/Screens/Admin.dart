import 'package:MomFit/Screens/AddMealPage.dart';
import 'package:MomFit/Screens/ListMealPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AddFAQ.dart';
import 'ListFAQ.dart';
import 'login.dart';

class Admin extends StatelessWidget {
  const Admin({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning, Admin!";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon, Admin!";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening, Admin!";
    } else {
      return "Good Night, Admin!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.admin_panel_settings,
                          color: Colors.blue),
                    ),
                    onSelected: (value) async {
                      if (value == "logout") {
                        SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => login()),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "logout",
                        child: Text("Logout"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _actionButton(
                        "Add FAQ", Colors.indigoAccent, Icons.add_comment, () {
                      Navigator.push(context,MaterialPageRoute(builder: (context) => AddFaqPage()));
                    }),
                    const SizedBox(height: 12),
                    _actionButton("FAQ List", Colors.cyan, Icons.help_center,
                            () {
                              Navigator.push(context,MaterialPageRoute(builder: (context) => ListFaqPage()));
                        }),
                    const SizedBox(height: 12),
                    _actionButton(
                        "Add Meal", Colors.purple, Icons.add_comment, () {
                      Navigator.push(context,MaterialPageRoute(builder: (context) => AddMealPage()));
                    }),
                    const SizedBox(height: 12),
                    _actionButton(
                        "List Meal", Colors.deepPurpleAccent, Icons.add_comment, () {
                      Navigator.push(context,MaterialPageRoute(builder: (context) => ListMealPage()));
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      String text, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
