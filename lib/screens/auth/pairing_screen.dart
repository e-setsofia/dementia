import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/pairing_service.dart';
import '../../widgets/sign_out_action.dart';

/// Shown after sign-up/sign-in when the current user has no linked
/// counterpart yet. Patients see their pairing code to share; caregivers
/// enter a patient's code to link accounts.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final codeController = TextEditingController();
  final pairingService = PairingService();

  bool isSubmitting = false;
  String? errorText;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> link() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      setState(() => errorText = "Enter the pairing code");
      return;
    }

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      final caregiverUid = context.read<AuthProvider>().currentUser!.uid;
      await pairingService.linkByCode(code: code, caregiverUid: caregiverUid);
      // AuthProvider's profile stream picks up the new linkedUid and
      // AuthGate routes to CaregiverDashboard automatically.
    } catch (e) {
      setState(() => errorText = e is StateError ? e.message : "Could not link that code.");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Link Accounts"),
        actions: const [SignOutAction()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : user.role == UserRole.patient
                ? _PatientPairingCode(code: user.pairingCode ?? '')
                : _CaregiverPairingForm(
                    codeController: codeController,
                    isSubmitting: isSubmitting,
                    errorText: errorText,
                    onSubmit: link,
                  ),
      ),
    );
  }
}

class _PatientPairingCode extends StatelessWidget {
  const _PatientPairingCode({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Share this code with your caregiver so they can link their account to yours:",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Once your caregiver enters this code, this screen will move on automatically.",
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _CaregiverPairingForm extends StatelessWidget {
  const _CaregiverPairingForm({
    required this.codeController,
    required this.isSubmitting,
    required this.errorText,
    required this.onSubmit,
  });

  final TextEditingController codeController;
  final bool isSubmitting;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter the pairing code your patient shared with you:",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: "Pairing code",
            prefixIcon: const Icon(Icons.key),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Text(errorText!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("LINK ACCOUNT"),
          ),
        ),
      ],
    );
  }
}
