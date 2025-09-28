import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  final String role; // "seeker" or "employer"
  const NotificationsScreen({super.key, this.role = "seeker"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications will appear here')),
    );
  }
}
