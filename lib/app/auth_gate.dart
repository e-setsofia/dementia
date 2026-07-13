import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pairing_screen.dart';
import '../screens/caregiver/caregiver_dashboard.dart';
import '../screens/patient/patient_dashboard.dart';

/// Root routing decision point: unauthenticated goes to LoginScreen,
/// authenticated-but-unlinked goes to PairingScreen, authenticated-and-linked
/// goes to the role-appropriate dashboard. No screen needs to know how to
/// get here; they just react to AuthProvider changing (e.g. via signOut()).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authProvider.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    if (!authProvider.isLinked) {
      return const PairingScreen();
    }

    return user.role == UserRole.patient
        ? const PatientDashboard()
        : const CaregiverDashboard();
  }
}
