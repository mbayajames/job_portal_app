import 'package:flutter/material.dart';

class ApplicationStatusBadge extends StatelessWidget {
  final String status;
  const ApplicationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status.toLowerCase()) {
      case 'submitted':
        color = Colors.yellow;
        break;
      case 'reviewed':
        color = Colors.orange;
        break;
      case 'interview':
        color = Colors.blue;
        break;
      case 'hired':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
