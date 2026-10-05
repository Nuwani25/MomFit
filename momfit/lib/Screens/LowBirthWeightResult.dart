import 'package:flutter/material.dart';

class LowBirthWeightResultPage extends StatelessWidget {
  final String prediction;

  LowBirthWeightResultPage({required this.prediction});

  final Map<String, Map<String, dynamic>> riskInfo = {
    "Normal": {
      "message":
          "Your baby’s growth looks on track. Birth is likely to be normal based on your current records.",
      "instructions": [
        "Keep all clinic/doctor visits as scheduled.",
        "Eat balanced meals and snacks; don’t skip breakfast.",
        "Take supplements exactly as your clinic advised.",
      ],
    },
    "Low": {
      "message":
          "This forecast shows a higher chance of low birth weight. It’s a precaution, not a diagnosis.",
      "instructions": [
        "Contact your clinic/midwife soon for a check and follow their plan.",
        "Keep an eye on baby’s movements; if you feel noticeably less movement, seek care.",
        "Rest more and try simple relaxation.",
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final info = riskInfo[prediction]!;

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: Text("Low Birth Weight Result"),
        backgroundColor: Colors.pink.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Prediction: $prediction",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade400,
                  ),
                ),
                SizedBox(height: 16),
                Text(info["message"], style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Text(
                  "Instructions:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade400,
                  ),
                ),
                SizedBox(height: 8),
                ...List<Widget>.from(
                  info["instructions"].map(
                    (instr) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "• ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(instr, style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
