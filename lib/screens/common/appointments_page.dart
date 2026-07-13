import 'package:flutter/material.dart';
import '../../core/supabase.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _fetchAppointments();
  }

  Future<List<Map<String, dynamic>>> _fetchAppointments() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await supabase
        .from('appointments')
        .select()
        .eq('patient_id', userId)
        .order('appointment_time');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointments")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final appointments = snapshot.data ?? [];
          if (appointments.isEmpty) {
            return const Center(child: Text("No appointments found"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              final dateStr = appt['appointment_time'] != null
                  ? DateTime.parse(appt['appointment_time']).toLocal().toString().substring(0, 16)
                  : 'N/A';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.orange),
                  title: Text(appt['title'] ?? ''),
                  subtitle: Text(
                      "${appt['doctor_name'] ?? 'Doctor'} — $dateStr"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
