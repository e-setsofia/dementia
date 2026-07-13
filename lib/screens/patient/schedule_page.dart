import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../../widgets/schedule_tile.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late Future<List<Map<String, dynamic>>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _schedulesFuture = _fetchSchedules();
  }

  Future<List<Map<String, dynamic>>> _fetchSchedules() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await supabase
        .from('schedules')
        .select()
        .eq('patient_id', userId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Schedule")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _schedulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final schedules = snapshot.data ?? [];
          if (schedules.isEmpty) {
            return const Center(child: Text("No schedule found"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final s = schedules[index];
              return ScheduleTile(
                time: s['time'] ?? '',
                task: s['task'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}
