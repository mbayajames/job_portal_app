import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String role; // "seeker" or "employer"
  const ProfileScreen({super.key, this.role = "seeker"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Text('Profile Page for $role'),
      ),
    );
  }
}
