import 'package:flutter/material.dart';

import 'autoRisk.dart';

class WorkoutResultPage extends StatefulWidget {
  @override
  _WorkoutResultPageState createState() => _WorkoutResultPageState();
}

class _WorkoutResultPageState extends State<WorkoutResultPage> {
  String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.pink.shade50,
        appBar: AppBar(
        title: Text("Workout Result"),
    backgroundColor: Colors.pink.shade400,
    ),
    body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 60),
                const SizedBox(height: 10),
                const Text(
                  "Great Job!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "You've completed today's workout",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "How are your complications today?",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),

                      // Options
                      _buildOption("Better", "😊", Colors.green),
                      const SizedBox(height: 10),
                      _buildOption("Same", "😐", Colors.amber[700]!),
                      const SizedBox(height: 10),
                      _buildOption("Worse", "☹️", Colors.red),

                      const SizedBox(height: 25),

                      // Buttons / Messages based on selected state
                      if (selectedStatus == "Better") ...[
                        _buildPrimaryButton("Continue Current Plan"),
                        const SizedBox(height: 10),
                        _buildSecondaryButton("Generate New Plan"),
                        const SizedBox(height: 10),
                        const Text(
                          "That's wonderful! Keep up the great work with your current routine.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ] else if (selectedStatus == "Same") ...[
                        _buildPrimaryButton("Continue Current Plan"),
                        const SizedBox(height: 10),
                        _buildSecondaryButton("Generate New Plan"),
                        const SizedBox(height: 10),
                        const Text(
                          "Your current plan is working well. You can continue or try something new.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ] else if (selectedStatus == "Worse") ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Important: Stop Exercising",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Since your symptoms have worsened, we recommend you stop exercising and consult with your healthcare provider as soon as possible.\n\n• Contact your doctor or midwife\n• Describe your symptoms in detail\n• Follow their medical advice",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("I Understand",
                              style:
                              TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildOption(String text, String emoji, Color color) {
    final bool isSelected = selectedStatus == text;

    return GestureDetector(
      onTap: () => setState(() => selectedStatus = text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4081), Color(0xFFE91E63)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildSecondaryButton(String text) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE91E63), width: 1.5),
      ),
      child: TextButton(
        onPressed: () {
          if(text=="Generate New Plan"){
            Navigator.push(context, MaterialPageRoute(builder: (context) => AutoRisk()));
          }
        },
        child: Text(
          text,
          style: const TextStyle(
              color: Color(0xFFE91E63), fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}