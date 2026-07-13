import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../repositories/alert_repository.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  bool isSending = false;

  Future<void> callHelp() async {
    setState(() => isSending = true);
    try {
      final uid = context.read<AuthProvider>().currentUser!.uid;
      await AlertRepository(widget.patientId).trigger(triggeredByUid: uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency alert sent to caregiver!"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not send alert. Check your connection and try again.")),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Press button to alert caregiver",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              onPressed: isSending ? null : callHelp,
              child: isSending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("EMERGENCY ALERT"),
            ),
          ],
        ),
      ),
    );
  }
}
