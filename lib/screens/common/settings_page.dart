import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../auth/login_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile"),
          ),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notifications"),
          ),
          const ListTile(
            leading: Icon(Icons.lock),
            title: Text("Privacy"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
