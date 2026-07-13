import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/sign_out_action.dart';
import '../shared/settings_page.dart';
import 'alerts_page.dart';
import 'medication_manage_page.dart';
import 'patient_info_page.dart';
import 'schedule_manage_page.dart';

class CaregiverDashboard extends StatelessWidget {
  const CaregiverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final patientId = context.watch<AuthProvider>().patientId!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Dashboard"),
        actions: const [SignOutAction()],
      ),
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
                  MaterialPageRoute(builder: (_) => MedicationManagePage(patientId: patientId)),
                );
              },
            ),
            DashboardCard(
              title: "Daily Schedule",
              icon: Icons.calendar_today,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ScheduleManagePage(patientId: patientId)),
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
                  MaterialPageRoute(builder: (_) => PatientInfoPage(patientId: patientId)),
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
                  MaterialPageRoute(builder: (_) => AlertsPage(patientId: patientId)),
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
