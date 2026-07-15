// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  // ─── Palette ──────────────────────────────────────────────
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFFF97316);
  static const Color _accentLight = Color(0xFFFB923C);
  static const Color _success = Color(0xFF10B981);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final patientId = supabase.auth.currentUser?.id;
      if (patientId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final data = await supabase
          .from('appointments')
          .select()
          .eq('patient_id', patientId)
          .order('appointment_time', ascending: true);
      if (!mounted) return;
      setState(() {
        _appointments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load appointments: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming =
        _appointments.where((a) => _apptDate(a).isAfter(now)).toList();
    final past =
        _appointments.where((a) => !_apptDate(a).isAfter(now)).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text('Appointments',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accentLight))
          : _appointments.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    // Next appointment hero card
                    if (upcoming.isNotEmpty) ...[
                      _buildNextAppointmentHero(upcoming.first),
                      const SizedBox(height: 20),
                    ],

                    if (upcoming.length > 1) ...[
                      _sectionLabel('Upcoming (${upcoming.length - 1})',
                          Icons.event_outlined, _accentLight),
                      const SizedBox(height: 10),
                      ...upcoming.skip(1).map(_appointmentCard),
                      const SizedBox(height: 20),
                    ],

                    if (past.isNotEmpty) ...[
                      _sectionLabel(
                          'Past (${past.length})', Icons.history, _textSecondary),
                      const SizedBox(height: 10),
                      ...past.map((a) => _appointmentCard(a, isPast: true)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_outlined,
                size: 52, color: _accentLight),
          ),
          const SizedBox(height: 20),
          const Text('No Appointments',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your caregiver hasn\'t scheduled\nany appointments yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentHero(Map<String, dynamic> appt) {
    final dt = _apptDate(appt);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF92400E), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentLight.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('NEXT APPOINTMENT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(appt['title'] ?? 'Appointment',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          if ((appt['doctor_name'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Dr. ${appt['doctor_name']}',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _infoChip(Icons.calendar_today_outlined,
                  '${dt.day} ${_month(dt.month)} ${dt.year}'),
              const SizedBox(width: 10),
              _infoChip(Icons.access_time_outlined,
                  '${_pad(dt.hour)}:${_pad(dt.minute)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appt, {bool isPast = false}) {
    final dt = _apptDate(appt);
    final attended = appt['attended'] == true;
    final color = isPast
        ? (attended ? _success : _textSecondary)
        : _accentLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${dt.day}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text(_month(dt.month).substring(0, 3),
                    style: TextStyle(color: color, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt['title'] ?? 'Appointment',
                    style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                if ((appt['doctor_name'] as String? ?? '').isNotEmpty)
                  Text('Dr. ${appt['doctor_name']}',
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12)),
                Text('${_pad(dt.hour)}:${_pad(dt.minute)}',
                    style: const TextStyle(
                        color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (isPast)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                attended ? 'Attended' : 'Missed',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ],
    );
  }

  DateTime _apptDate(Map<String, dynamic> a) {
    try {
      return DateTime.parse(a['appointment_time'].toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  String _month(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[(m - 1).clamp(0, 11)];
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
