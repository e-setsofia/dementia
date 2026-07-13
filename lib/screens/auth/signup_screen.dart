import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_input_decoration.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  UserRole selectedRole = UserRole.patient;
  bool isSubmitting = false;
  String? errorText;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => errorText = "Fill all fields");
      return;
    }
    if (password.length < 6) {
      setState(() => errorText = "Password must be at least 6 characters");
      return;
    }

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      final authService = context.read<AuthProvider>().authService;
      await authService.signUp(
        email: email,
        password: password,
        displayName: name,
        role: selectedRole,
      );
      // Pop back to the root route so AuthGate (already updated with the
      // new signed-in, unlinked user) is what's visible next, instead of
      // this pushed SignUpScreen staying on top of it.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = switch (e.code) {
            'email-already-in-use' => "That email is already registered. Try logging in instead.",
            'weak-password' => "Choose a stronger password.",
            'invalid-email' => "That email address looks invalid.",
            _ => "Sign up failed: ${e.message ?? e.code}",
          });
    } catch (e) {
      setState(() => errorText = "Sign up failed: $e");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0047FF), Color(0xff3FA9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: authInputDecoration("Full name", Icons.badge),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: authInputDecoration("Email", Icons.email),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: authInputDecoration("Password", Icons.lock),
                ),
                const SizedBox(height: 20),
                const Text("Register as", style: TextStyle(color: Colors.white)),
                RadioListTile<UserRole>(
                  value: UserRole.patient,
                  groupValue: selectedRole,
                  onChanged: (v) => setState(() => selectedRole = v!),
                  title: const Text("Patient", style: TextStyle(color: Colors.white)),
                ),
                RadioListTile<UserRole>(
                  value: UserRole.caregiver,
                  groupValue: selectedRole,
                  onChanged: (v) => setState(() => selectedRole = v!),
                  title: const Text("Caregiver", style: TextStyle(color: Colors.white)),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Colors.yellowAccent)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : signUp,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("SIGN UP"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
