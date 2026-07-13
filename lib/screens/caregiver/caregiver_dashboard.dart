import 'package:flutter/material.dart';
import '../../widgets/dashboard_card.dart';
import '../patient/medication_page.dart';
import 'patient_info_page.dart';
import 'alerts_page.dart';
import '../common/appointments_page.dart';
import '../common/reports_page.dart';
import '../common/settings_page.dart';

class CaregiverDashboard extends StatelessWidget {
  const CaregiverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Caregiver Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DashboardCard(
              title: "Medication Management",
              icon: Icons.medication_liquid,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicationPage()),
                );
              },
            ),
            DashboardCard(
              title: "Patient Information",
              icon: Icons.person,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientInfoPage()),
                );
              },
            ),
            DashboardCard(
              title: "Appointments",
              icon: Icons.event_note,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentsPage()),
                );
              },
            ),
            DashboardCard(
              title: "Reports",
              icon: Icons.bar_chart,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                );
              },
            ),
            DashboardCard(
              title: "Alerts",
              icon: Icons.notifications,
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsPage()),
                );
              },
            ),
            DashboardCard(
              title: "Settings",
              icon: Icons.settings,
              color: Colors.grey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
