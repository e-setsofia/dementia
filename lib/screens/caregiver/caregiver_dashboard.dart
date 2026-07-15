// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../../widgets/dashboard_card.dart';
import '../auth/login_screen.dart';
import 'medication_manage_page.dart';
import 'patient_info_page.dart';
import 'alerts_page.dart';
import 'schedule_manage_page.dart';
import 'appointment_manage_page.dart';
import 'reports_page.dart';
import '../common/settings_page.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  bool _isCheckingPairing = true;
  bool _isPaired = false;
  final TextEditingController _codeController = TextEditingController();
  bool _isPairing = false;

  @override
  void initState() {
    super.initState();
    _checkPairing();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkPairing() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('caregiver_patients')
          .select('id')
          .eq('caregiver_id', userId)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isPaired = data != null;
          _isCheckingPairing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingPairing = false);
      }
    }
  }

  Future<void> _pairPatient() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isPairing = true);

    try {
      await supabase.rpc('pair_caregiver', params: {'p_code': code});
      
      if (mounted) {
        setState(() {
          _isPaired = true;
          _isPairing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully paired with patient!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPairing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pairing failed. Check code. ($e)"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sign Out",
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _isCheckingPairing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  if (!_isPaired) _buildPairingBanner(),
                  DashboardCard(
                    title: "Medication Management",
                    icon: Icons.medication_liquid,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MedicationManagePage()),
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
                        MaterialPageRoute(
                            builder: (_) => const PatientInfoPage()),
                      );
                    },
                  ),
                  DashboardCard(
                    title: "Schedule Management",
                    icon: Icons.calendar_today,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScheduleManagePage()),
                      );
                    },
                  ),
                  DashboardCard(
                    title: "Appointment Manager",
                    icon: Icons.event_note,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AppointmentManagePage()),
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

  Widget _buildPairingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Link to a Patient",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter the 6-character code from the patient's dashboard to manage their care.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: "e.g., A1B2C3",
                    hintStyle: const TextStyle(color: Colors.white30),
                    counterText: "",
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isPairing ? null : _pairPatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isPairing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("PAIR"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
