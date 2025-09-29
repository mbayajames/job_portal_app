import 'package:flutter/material.dart';

class EmployerSupportScreen extends StatelessWidget {
  const EmployerSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employer Support & Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text('FAQ 1'), subtitle: Text('Answer to FAQ 1')),
          ListTile(title: Text('FAQ 2'), subtitle: Text('Answer to FAQ 2')),
          ListTile(title: Text('Contact Support'), subtitle: Text('Email: support@email.com')),
        ],
      ),
    );
  }
}