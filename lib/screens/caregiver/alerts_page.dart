import 'package:flutter/material.dart';
import '../../core/supabase.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _fetchAlerts();
  }

  Future<List<Map<String, dynamic>>> _fetchAlerts() async {
    final data = await supabase
        .from('emergency_alerts')
        .select('*, profiles(name)')
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alerts")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                "No active alerts",
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final patientName =
                  alert['profiles']?['name'] ?? 'Unknown Patient';
              final dateStr = alert['created_at'] != null
                  ? DateTime.parse(alert['created_at']).toLocal().toString().substring(0, 16)
                  : '';
              return Card(
                color: Colors.red[50],
                child: ListTile(
                  leading:
                      const Icon(Icons.warning_amber, color: Colors.red, size: 36),
                  title: Text("🚨 Emergency from $patientName"),
                  subtitle: Text("Time: $dateStr"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
