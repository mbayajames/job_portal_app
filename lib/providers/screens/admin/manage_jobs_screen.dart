import 'package:flutter/material.dart';

class ManageJobsScreen extends StatelessWidget {
  const ManageJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Jobs")),
      body: const Center(
        child: Text("Manage jobs here"),
      ),
    );
  }
}