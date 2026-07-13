import 'package:flutter/material.dart';

/// Shared text field styling for the auth screens' blue gradient
/// background: translucent white fill, white hint/icon, rounded border.
InputDecoration authInputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: Colors.white),
    filled: true,
    fillColor: Colors.white.withOpacity(0.2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  );
}
