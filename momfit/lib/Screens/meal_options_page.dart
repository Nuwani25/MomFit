import 'dart:math';

import 'package:MomFit/Screens/MealPlan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

final Map<int, String> categoryNotes = {
  1: "You have more than one health risk. Keep meals simple and steady. Avoid ultra‑processed snacks, deep‑fried food, sugary drinks, very salty food, energy drinks, and too much caffeine. Choose meals made from whole grains, vegetables, beans, and lean proteins cooked with little oil. Eat at regular times, drink enough water, keep sugar and salt low, and check any new herbal drinks or supplements with your doctor.",
  2: "Help control sugar levels. Avoid sugary drinks, sweets, white‑flour snacks, and very large meals made mostly of starch. Choose slower‑release carbohydrates with fibre and always combine them with protein and a little healthy fat. Spread carbohydrate foods across the day, prefer steaming, boiling, or grilling, and follow your glucose checks with your doctor.",
  3: "Help lower blood pressure. Avoid high‑salt processed foods, salty snacks, instant noodles or soups, pickled foods, stock cubes, and too much caffeine. Cook with less salt and use herbs, spices, or lemon for flavour. Pick fresh foods more often, drink water regularly, and read labels to keep salt low.",
  4: "Support iron and folate. Avoid tea or coffee with meals and do not rely mainly on refined grains. Choose meal plans that often include iron‑ and folate‑supporting foods from plants or animal sources, and add a vitamin‑C‑rich fruit or side to help absorption. Follow your doctor’s guidance.",
  5: "Protect yourself from reactions. Avoid your allergen and prevent cross‑contact in the kitchen or at food stalls. Choose safe proteins that fit your allergy plan, along with vegetables, grains, and legumes. Check labels, ask how food is prepared when eating out, and follow your doctor’s allergy advice.",
  6: "Build healthy weight. Avoid skipping meals and avoid filling up on tea or black coffee instead of food. Choose energy‑ and protein‑rich meals made from whole foods, with some healthy fats and fibre. Keep three meals plus regular snacks, use softer textures if appetite is low, and review progress with your doctor.",
  7: "Lower excess weight safely. Avoid sugary drinks, frequent desserts, deep‑fried foods, and highly refined starches. Base meals on vegetables, whole‑grain carbohydrates, and lean proteins cooked with little oil. Eat at steady times, choose water as your main drink, keep late‑night meals light, and practice mindful eating.",
  8: "Early pregnancy comfort. If you feel nauseous, avoid very greasy or very spicy meals and keep caffeine low. Choose gentle, balanced meals that include carbohydrates, protein, vegetables, and fluids. Small, frequent meals can help. Use simple cooking methods and stay hydrated through the day.",
  9: "Balanced vegetarian eating. Avoid ultra‑processed mock meats that are high in salt or fat. Eat a mix of plant proteins with whole‑grain foods and include regular sources that support iron, calcium, iodine, and vitamin B12 (through foods or supplements as advised). Pair iron‑supporting foods with vitamin‑C‑rich sides and check key nutrients with your doctor when needed.",
  10: "Third‑trimester care. Avoid very heavy late‑night meals and very spicy or fried foods near bedtime to reduce reflux. Choose slightly more protein with fibre‑rich carbohydrates and enough fluids. Try to eat dinner earlier, pick lighter textures if heartburn occurs, keep salt moderate, and follow your doctor’s advice.",
};

class MealOptionsPage extends StatefulWidget {
  final int category;
  const MealOptionsPage({required this.category});

  @override
  State<MealOptionsPage> createState() => _MealOptionsPageState();
}

class _MealOptionsPageState extends State<MealOptionsPage> {
  final List<String> mealTypes = [
    "Breakfast",
    "Morning Snack",
    "Lunch",
    "Evening Snack",
    "Dinner"
  ];

  Map<String, Map<String, dynamic>> selectedMeals = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRandomMeals();
  }

  Future<void> _loadRandomMeals() async {
    try {
      Map<String, Map<String, dynamic>> tempMeals = {};

      for (var type in mealTypes) {
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('meals')
            .where('category', isEqualTo: widget.category)
            .where('mealType', isEqualTo: type)
            .get();

        if (query.docs.isNotEmpty) {
          var randomDoc = query.docs[Random().nextInt(query.docs.length)];
          tempMeals[type] = randomDoc.data() as Map<String, dynamic>;
        }
      }

      setState(() {
        selectedMeals = tempMeals;
        loading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading meals: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _markAsEaten(Map<String, dynamic> meal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final dateKey = "${today.year}-${today.month}-${today.day}";

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_calories')
          .doc(dateKey);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        int currentCalories = 0;
        if (snapshot.exists && snapshot.data() != null) {
          currentCalories = (snapshot.data() as Map<String, dynamic>)['calories'] ?? 0;
        }

        int mealCalories = meal['calorieCount'] ?? 0;
        int newCalories = currentCalories + mealCalories;

        transaction.set(docRef, {
          'calories': newCalories,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });


      Fluttertoast.showToast(
          msg: "Added ${meal['calorieCount']} kcal to your daily total!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving calories: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = categoryNotes[widget.category] ?? "No guidance available.";

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text("Your Meal Plan"),
        backgroundColor: Colors.pink.shade400,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadRandomMeals,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuidanceCard(notes),
              const SizedBox(height: 16),
              ...mealTypes.map((type) =>
                  _buildMealCard(type, selectedMeals[type])).toList(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loadRandomMeals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Get Another Meal Plan",
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
    );
  }

  Widget _buildGuidanceCard(String notes) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Guidance",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(notes, style: GoogleFonts.poppins(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(String type, Map<String, dynamic>? meal) {
    if (meal == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: ListTile(
          title: Text(type),
          subtitle: const Text("No meals available for this category."),
        ),
      );
    }

    final videoId = meal['youtubeVideoId'] ?? '';
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(meal['imageUrl'], fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            YoutubePlayer(controller: controller, showVideoProgressIndicator: true),
            const SizedBox(height: 8),
            Text(meal['foodDescription'] ?? "",
                style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 6),
            Text("Calories: ${meal['calorieCount']} kcal",
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _markAsEaten(meal),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Mark as Eaten"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
