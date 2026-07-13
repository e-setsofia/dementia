import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../../widgets/medication_tile.dart';

class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  late Future<List<Map<String, dynamic>>> _medicationsFuture;

  @override
  void initState() {
    super.initState();
    _medicationsFuture = _fetchMedications();
  }

  Future<List<Map<String, dynamic>>> _fetchMedications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await supabase
        .from('medications')
        .select()
        .eq('patient_id', userId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Medication")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final medications = snapshot.data ?? [];
          if (medications.isEmpty) {
            return const Center(child: Text("No medications found"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final med = medications[index];
              return MedicationTile(
                time: med['time'] ?? '',
                drug: med['drug'] ?? '',
                dose: med['dose'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}
