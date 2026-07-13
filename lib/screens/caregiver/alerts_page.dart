import 'package:flutter/material.dart';

import '../../models/emergency_alert.dart';
import '../../repositories/alert_repository.dart';
import '../../widgets/async_value_view.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final repository = AlertRepository(patientId);

    return Scaffold(
      appBar: AppBar(title: const Text("Alerts")),
      body: AsyncValueView(
        stream: repository.stream(),
        builder: (context, alerts) {
          if (alerts.isEmpty) {
            return const Center(child: Text("No emergency alerts yet."));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final alert in alerts)
                _AlertTile(
                  alert: alert,
                  onAcknowledge: () => repository.acknowledge(alert.id),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onAcknowledge});

  final EmergencyAlert alert;
  final VoidCallback onAcknowledge;

  String _formatTime(DateTime? dt) {
    if (dt == null) return "Just now";
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: alert.acknowledged ? null : Colors.red.shade50,
      child: ListTile(
        leading: Icon(
          Icons.warning,
          color: alert.acknowledged ? Colors.grey : Colors.red,
        ),
        title: Text(alert.message),
        subtitle: Text(_formatTime(alert.createdAt)),
        trailing: alert.acknowledged
            ? const Text("Acknowledged", style: TextStyle(color: Colors.grey))
            : TextButton(
                onPressed: onAcknowledge,
                child: const Text("Acknowledge"),
              ),
      ),
    );
  }
}
