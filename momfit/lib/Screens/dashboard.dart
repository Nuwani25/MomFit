import 'package:MomFit/Screens/DailyCaloriesPage.dart';
import 'package:MomFit/Screens/Diabetes.dart';
import 'package:MomFit/Screens/LowBirth.dart';
import 'package:MomFit/Screens/MealPlan.dart';
import 'package:MomFit/Screens/PregnancySupport.dart';
import 'package:MomFit/Screens/ProfilePage.dart';
import 'package:MomFit/Screens/Risk.dart';
import 'package:MomFit/Screens/StepsCal.dart';
import 'package:MomFit/Screens/autoRisk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'OCR.dart';
import 'login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String stepCount = "0";
  String distanceWalked = "0 km";
  String caloriesBurned = "0 kcal";
  String moveMinutes = "0 min";
  String trimester = "";

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      stepCount = prefs.getString('_stepCount') ?? "0";
      distanceWalked = prefs.getString('distanceWalked') ?? "0 km";
      caloriesBurned = prefs.getString('caloriesBurned') ?? "0 kcal";
      moveMinutes = prefs.getString('moveMinutes') ?? "0 min";
      trimester = prefs.getString('trimester') ?? "";
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning!";
    if (hour >= 12 && hour < 17) return "Good Afternoon!";
    if (hour >= 17 && hour < 21) return "Good Evening!";
    return "Good Night!";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.pink.shade400,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        trimester,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.pink),
                    ),
                    onSelected: (value) async {
                      if (value == "profile") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(),
                          ),
                        );
                      } else if (value == "settings") {
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => Doctor()));
                      } else if (value == "logout") {
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
                      const PopupMenuItem(value: "profile", child: Text("Profile")),
                      const PopupMenuItem(value: "settings", child: Text("Settings")),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: "logout", child: Text("Logout")),
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
                    _healthSummary(context),
                    const SizedBox(height: 20),
                    _quickActions(context),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _featureCard(
                          Icons.restaurant_menu,
                          "Meal Plan",
                          "Nutrition guidance",
                          Colors.orange.shade300,
                              () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => MealPlan())),
                        ),
                        _featureCard(
                          Icons.fitness_center,
                          "Exercise Plan",
                          "Personalized workouts",
                          Colors.pink.shade300,
                              () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => AutoRisk())),
                        ),
                        _featureCard(
                          Icons.chat,
                          "Chat Support",
                          "Ask questions",
                          Colors.blue.shade300,
                              () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => PregnancySupport())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthSummary(context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StepsCal()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink.shade400, size: 20),
                const SizedBox(width: 6),
                Text(
                  "Health Summary",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _healthCard(Icons.directions_walk, "Steps", stepCount, Colors.pink.shade300),
                _healthCard(Icons.map, "Distance", distanceWalked, Colors.blue.shade300),
                _healthCard(Icons.local_fire_department, "Calories", caloriesBurned, Colors.green.shade300),
                _healthCard(Icons.timer, "Move", moveMinutes, Colors.orange.shade300),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _actionButton("Diabetes Finder", Colors.blueAccent, Icons.add_chart, context),
          const SizedBox(height: 12),
          _actionButton("Baby Low Birth", Colors.purpleAccent, Icons.edit_document, context),
          const SizedBox(height: 12),
          _actionButton("Manual Data Exercise", Colors.amberAccent, Icons.edit_document, context),
          const SizedBox(height: 12),
          _actionButton("Reports upload", Colors.deepOrange, Icons.add_chart, context),
          const SizedBox(height: 12),
          _actionButton("Daily calorie count", Colors.green, Icons.add_chart, context),
        ],
      ),
    );
  }

  Widget _healthCard(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _actionButton(String text, Color color, IconData icon, context) {
    return GestureDetector(
      onTap: () {
        if (text == "Diabetes Finder") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DiabetesFinder()));
        } else if (text == "Baby Low Birth") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => LowBirthWeightPage()));
        } else if (text == "Manual Data Exercise") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Risk()));
        } else if (text == "Reports upload") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => OCR()));
        } else if (text == "Daily calorie count") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DailyCaloriePage()));
        }
      },
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
