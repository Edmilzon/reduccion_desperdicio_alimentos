import 'package:flutter/material.dart';

class CustomPasswordInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CustomPasswordInput({
    super.key,
    required this.hint,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}