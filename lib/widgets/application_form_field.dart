import 'package:flutter/material.dart';

class ApplicationFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  const ApplicationFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}