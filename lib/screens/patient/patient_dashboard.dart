import 'package:flutter/material.dart';
import '../../widgets/dashboard_card.dart';
import 'medication_page.dart';
import 'schedule_page.dart';
import 'emergency_page.dart';
import '../common/appointments_page.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DashboardCard(
              title: "Medication",
              icon: Icons.medication,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicationPage()),
                );
              },
            ),
            DashboardCard(
              title: "Daily Schedule",
              icon: Icons.calendar_today,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SchedulePage()),
                );
              },
            ),
            DashboardCard(
              title: "Emergency",
              icon: Icons.warning,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyPage()),
                );
              },
            ),
            DashboardCard(
              title: "Appointments",
              icon: Icons.event,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
