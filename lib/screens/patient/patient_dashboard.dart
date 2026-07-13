import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../repositories/medication_repository.dart';
import '../../services/notification_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/sign_out_action.dart';
import 'emergency_page.dart';
import 'medication_page.dart';
import 'schedule_page.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  @override
  void initState() {
    super.initState();
    // Reconcile local reminders with whatever's currently in Firestore each
    // time this dashboard loads (e.g. after the caregiver edited meds
    // while this device was off). See NotificationService.reconcile.
    final patientId = context.read<AuthProvider>().patientId!;
    MedicationRepository(patientId).stream().first.then(
          NotificationService.instance.reconcile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final patientId = context.watch<AuthProvider>().patientId!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Dashboard"),
        actions: const [SignOutAction()],
      ),
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
                  MaterialPageRoute(builder: (_) => MedicationPage(patientId: patientId)),
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
                  MaterialPageRoute(builder: (_) => SchedulePage(patientId: patientId)),
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
                  MaterialPageRoute(builder: (_) => EmergencyPage(patientId: patientId)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
