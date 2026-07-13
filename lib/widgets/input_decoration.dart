import 'package:flutter/material.dart';

InputDecoration inputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: Colors.white),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  );
}
