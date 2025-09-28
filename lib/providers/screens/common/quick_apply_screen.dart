import 'package:flutter/material.dart';

class QuickApplyScreen extends StatelessWidget {
  final String jobId;
  
  const QuickApplyScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Apply'),
      ),
      body: const Center(
        child: Text('Quick Apply Screen'),
      ),
    );
  }
}