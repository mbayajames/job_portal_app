import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() =>
      _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  String selectedPlan = "Free";

  Future<void> _savePlan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection("employers")
          .doc(user.uid)
          .update({"subscriptionPlan": selectedPlan});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subscribed to $selectedPlan plan")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving plan: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> labels = [
      "Free Plan",
      "Pro Plan - \$19.99/month",
      "Enterprise Plan - \$49.99/month"
    ];
    List<String> values = ["Free", "Pro", "Enterprise"];

    return Scaffold(
      appBar: AppBar(title: const Text("Subscription Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              children: List.generate(
                labels.length,
                (index) => RadioMenuButton<String>(
                  value: values[index],
                  groupValue: selectedPlan,
                  onChanged: (value) {
                    setState(() => selectedPlan = value!);
                  },
                  child: Text(labels[index]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePlan,
              child: const Text("Save Plan"),
            ),
          ],
        ),
      ),
    );
  }
}
