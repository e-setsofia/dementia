import 'package:flutter/material.dart';
import '../../core/supabase.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  bool _isSending = false;

  Future<void> callHelp() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSending = true);

    try {
      await supabase.from('emergency_alerts').insert({
        'patient_id': userId,
        'status': 'active',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚨 Emergency alert sent to caregiver!"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send alert: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 20),
              ),
              onPressed: _isSending ? null : callHelp,
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("EMERGENCY ALERT"),
            ),
          ],
        ),
      ),
    );
  }
}
