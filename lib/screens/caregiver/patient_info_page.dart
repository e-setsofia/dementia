import 'package:flutter/material.dart';
import '../../core/supabase.dart';

class PatientInfoPage extends StatefulWidget {
  const PatientInfoPage({super.key});

  @override
  State<PatientInfoPage> createState() => _PatientInfoPageState();
}

class _PatientInfoPageState extends State<PatientInfoPage> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    // Caregivers viewing patient info — fetch the first patient profile
    final data = await supabase
        .from('profiles')
        .select()
        .eq('role', 'patient')
        .limit(1)
        .maybeSingle();
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Information")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text("No patient profile found"));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTile("Name", profile['name'] ?? 'N/A'),
                _infoTile("Age", profile['age']?.toString() ?? 'N/A'),
                _infoTile("Condition", profile['condition'] ?? 'N/A'),
                _infoTile("Blood Group", profile['blood_group'] ?? 'N/A'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
