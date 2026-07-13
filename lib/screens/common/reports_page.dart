import 'package:flutter/material.dart';
import '../../core/supabase.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchReports();
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await supabase
        .from('medications')
        .select()
        .eq('patient_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text("No medication records found"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final med = reports[index];
              final dateStr = med['created_at'] != null
                  ? DateTime.parse(med['created_at']).toLocal().toString().substring(0, 10)
                  : '';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.green),
                  title: Text("${med['drug']} — ${med['dose']}"),
                  subtitle: Text("${med['time']}  •  Added: $dateStr"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
