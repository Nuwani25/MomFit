import 'package:flutter/material.dart';

class DiabetesData extends StatelessWidget {
  final double predictedValue;

  DiabetesData({required this.predictedValue});

  final List<Map<String, dynamic>> riskData = [
    {
      "min": -10.0,
      "max": 10.0,
      "level": "No Risk",
      "message": "You’re not at increased risk right now.",
      "instructions": [
        "Keep drinking water instead of sugary drinks.",
        "Add a bit of movement every day (walks, stairs, chores).",
        "Sleep well and try to keep a regular bedtime.",
        "If your health changes (new meds, weight gain, pregnancy, symptoms), check in with your doctor."
      ]
    },
    {
      "min": 10.01,
      "max": 32.99,
      "level": "Low Risk",
      "message": "You have a low risk. Keep your routine going.",
      "instructions": [
        "Cut down on sugary drinks and sweets.",
        "Aim to move most days—a comfortable walk is great.",
        "Keep a steady sleep schedule and manage stress with simple breathing or stretching."
      ]
    },
    {
      "min": 33.0,
      "max": 65.99,
      "level": "Moderate Risk",
      "message": "You’re at moderate risk. Please book a routine doctor visit to confirm with tests and get a plan.",
      "instructions": [
        "Make simple swaps: water instead of soda/juice; whole grains instead of white rice or white bread.",
        "After meals, take a short walk—it helps your sugar levels.",
        "Add basic strength moves a few times a week.",
        "Keep a small note of your meals and walks to share at your visit."
      ]
    },
    {
      "min": 66.0,
      "max": double.infinity,
      "level": "High Risk",
      "message": "You’re at high risk. Please book a doctor’s appointment as soon as possible.\nIf you feel very thirsty, pee often, vomit, feel confused, or extremely tired, go to urgent care today.",
      "instructions": [
        "Only water or unsweetened drinks; skip sugary drinks and sweets.",
        "Take gentle walks (short and easy) after meals if you feel well; avoid very hard workouts until your doctor advises.",
        "Gather your medication list and recent results for your appointment."
      ]
    }
  ];

  Map<String, dynamic> getRiskInfo(double value) {
    return riskData.firstWhere(
          (risk) => value >= risk["min"] && value <= risk["max"],
      orElse: () => riskData[0],
    );
  }

  String getCount(double value) {
    if(value<10){
      return "0%";
    }else if(10<value||value<100){
      return value.toStringAsFixed(2).toString()+"%";
    }else{
      return "100%";
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskInfo = getRiskInfo(predictedValue);
    final String riskCount = getCount(predictedValue);

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: Text("Diabetes Risk"),
        backgroundColor: Colors.pink.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Diabetes : ${riskCount}",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade400),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Risk Level: ${riskInfo['level']}",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade400),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Message:",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    riskInfo['message'],
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Instructions:",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  ...List<Widget>.from(
                    riskInfo['instructions']
                        .map<Widget>((inst) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text("• $inst", style: TextStyle(fontSize: 16)),
                    )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
