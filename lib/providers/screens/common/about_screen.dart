import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'This is a job portal app. Here you can find jobs, manage applications, '
          'and track your employment activities. Version 1.0.0',
        ),
      ),
    );
  }
}
