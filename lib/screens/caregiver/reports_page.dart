// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../../core/patient_resolver.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  // ─── Palette ──────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF6366F1);
  static const Color _accentLight = Color(0xFF818CF8);
  static const Color _success = Color(0xFF10B981);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _info = Color(0xFF06B6D4);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  late TabController _tabController;

  // Report data
  int _medTaken = 0;
  int _medMissed = 0;
  int _emergencyCalls = 0;
  int _appointmentsAttended = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _medLogs = [];
  List<Map<String, dynamic>> _emergencyLogs = [];
  List<Map<String, dynamic>> _appointmentLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Data layer ───────────────────────────────────────────────────────────

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      // Get patient ID
      final patientId = await PatientResolver.resolve();

      if (patientId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch medication logs
      final medLogsRaw = await supabase
          .from('medication_logs')
          .select('*, medications(drug, dose, time)')
          .eq('patient_id', patientId)
          .order('logged_at', ascending: false);
      final medLogs = List<Map<String, dynamic>>.from(medLogsRaw);

      // Fetch emergency alerts
      final emergencyRaw = await supabase
          .from('emergency_alerts')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);
      final emergencyLogs = List<Map<String, dynamic>>.from(emergencyRaw);

      // Fetch appointments
      final apptRaw = await supabase
          .from('appointments')
          .select()
          .eq('patient_id', patientId)
          .order('appointment_time', ascending: false);
      final apptLogs = List<Map<String, dynamic>>.from(apptRaw);

      if (!mounted) return;
      setState(() {
        _medLogs = medLogs;
        _medTaken =
            medLogs.where((l) => l['status'] == 'taken').length;
        _medMissed =
            medLogs.where((l) => l['status'] == 'missed').length;
        _emergencyLogs = emergencyLogs;
        _emergencyCalls = emergencyLogs.length;
        _appointmentLogs = apptLogs;
        _appointmentsAttended =
            apptLogs.where((a) => a['attended'] == true).length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load reports: $e'),
        backgroundColor: _danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text('Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchReports,
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: _accentLight,
          unselectedLabelColor: _textSecondary,
          indicatorColor: _accentLight,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Medications'),
            Tab(text: 'Emergencies'),
            Tab(text: 'Appointments'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accentLight))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverview(),
                _buildMedicationTab(),
                _buildEmergencyTab(),
                _buildAppointmentTab(),
              ],
            ),
    );
  }

  // ─── Overview Tab ─────────────────────────────────────────────────────────

  Widget _buildOverview() {
    final total = _medTaken + _medMissed;
    final adherence =
        total > 0 ? (_medTaken / total * 100).toStringAsFixed(0) : '—';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Adherence banner
        _buildAdherenceBanner(adherence, total),
        const SizedBox(height: 20),

        // Summary cards grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _summaryCard(
              icon: Icons.medication_outlined,
              label: 'Medication\nTaken',
              value: '$_medTaken',
              color: _success,
            ),
            _summaryCard(
              icon: Icons.medication_liquid_outlined,
              label: 'Medication\nMissed',
              value: '$_medMissed',
              color: _danger,
            ),
            _summaryCard(
              icon: Icons.emergency_outlined,
              label: 'Emergency\nCalls',
              value: '$_emergencyCalls',
              color: _warning,
            ),
            _summaryCard(
              icon: Icons.event_available_outlined,
              label: 'Appointments\nAttended',
              value: '$_appointmentsAttended',
              color: _info,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Recent activity
        _sectionHeader('Recent Activity'),
        const SizedBox(height: 10),
        ..._buildRecentActivity(),
      ],
    );
  }

  Widget _buildAdherenceBanner(String adherence, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3730A3), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication Adherence',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  adherence == '—' ? 'No data yet' : '$adherence%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total > 0 ? 'Based on $total medication events' : 'Start tracking medications',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pie_chart_outline_rounded,
                color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                color: _textSecondary, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentActivity() {
    final activities = <Map<String, dynamic>>[];

    for (final log in _medLogs.take(3)) {
      activities.add({
        'icon': log['status'] == 'taken'
            ? Icons.check_circle_outline
            : Icons.cancel_outlined,
        'color': log['status'] == 'taken' ? _success : _danger,
        'title': log['status'] == 'taken'
            ? 'Medication Taken'
            : 'Medication Missed',
        'subtitle': log['medications']?['drug'] ?? 'Unknown drug',
        'time': _formatDateTime(log['logged_at']?.toString()),
      });
    }
    for (final alert in _emergencyLogs.take(2)) {
      activities.add({
        'icon': Icons.emergency_outlined,
        'color': _warning,
        'title': 'Emergency Alert',
        'subtitle': 'Status: ${alert['status'] ?? 'active'}',
        'time': _formatDateTime(alert['created_at']?.toString()),
      });
    }

    activities.sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));

    if (activities.isEmpty) {
      return [_emptyState('No recent activity recorded.')];
    }

    return activities
        .take(5)
        .map((a) => _activityTile(
              icon: a['icon'] as IconData,
              color: a['color'] as Color,
              title: a['title'] as String,
              subtitle: a['subtitle'] as String,
              time: a['time'] as String,
            ))
        .toList();
  }

  Widget _activityTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(time,
              style:
                  const TextStyle(color: _textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Medication Tab ───────────────────────────────────────────────────────

  Widget _buildMedicationTab() {
    if (_medLogs.isEmpty) {
      return _emptyState('No medication logs recorded yet.');
    }

    final taken = _medLogs.where((l) => l['status'] == 'taken').toList();
    final missed = _medLogs.where((l) => l['status'] == 'missed').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mini stats row
        Row(
          children: [
            Expanded(
              child: _miniStat('Taken', '$_medTaken', _success,
                  Icons.check_circle_outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _miniStat('Missed', '$_medMissed', _danger,
                  Icons.cancel_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (taken.isNotEmpty) ...[
          _sectionHeader('✅  Medications Taken (${taken.length})'),
          const SizedBox(height: 8),
          ...taken.map((l) => _medLogTile(l, taken: true)),
          const SizedBox(height: 20),
        ],

        if (missed.isNotEmpty) ...[
          _sectionHeader('❌  Medications Missed (${missed.length})'),
          const SizedBox(height: 8),
          ...missed.map((l) => _medLogTile(l, taken: false)),
        ],
      ],
    );
  }

  Widget _miniStat(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: _textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medLogTile(Map<String, dynamic> log, {required bool taken}) {
    final color = taken ? _success : _danger;
    final drug = log['medications']?['drug'] ?? 'Unknown drug';
    final dose = log['medications']?['dose'] ?? '';
    final time = _formatDateTime(log['logged_at']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              taken ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drug,
                    style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (dose.isNotEmpty)
                  Text(dose,
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  taken ? 'Taken' : 'Missed',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(time,
                  style: const TextStyle(
                      color: _textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Emergency Tab ────────────────────────────────────────────────────────

  Widget _buildEmergencyTab() {
    if (_emergencyLogs.isEmpty) {
      return _emptyState('No emergency alerts recorded.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencyLogs.length,
      itemBuilder: (context, i) {
        final alert = _emergencyLogs[i];
        final status = alert['status'] ?? 'active';
        final isResolved = status == 'resolved';
        final color = isResolved ? _success : _danger;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isResolved
                      ? Icons.check_circle_outline
                      : Icons.emergency_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Alert #${i + 1}',
                        style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(alert['created_at']?.toString()),
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  isResolved ? 'Resolved' : 'Active',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Appointment Tab ──────────────────────────────────────────────────────

  Widget _buildAppointmentTab() {
    if (_appointmentLogs.isEmpty) {
      return _emptyState('No appointments recorded.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointmentLogs.length,
      itemBuilder: (context, i) {
        final appt = _appointmentLogs[i];
        final attended = appt['attended'] == true;
        final color = attended ? _success : _info;
        final title = appt['title'] ?? 'Appointment';
        final doctor = appt['doctor_name'] ?? '';
        final time = _formatDateTime(appt['appointment_time']?.toString());

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  attended
                      ? Icons.event_available_outlined
                      : Icons.event_note_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    if (doctor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Dr. $doctor',
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 12)),
                    ],
                    const SizedBox(height: 2),
                    Text(time,
                        style: const TextStyle(
                            color: _textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  attended ? 'Attended' : 'Scheduled',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _emptyState(String msg) {
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
            child: const Icon(Icons.bar_chart_outlined,
                size: 52, color: _accentLight),
          ),
          const SizedBox(height: 16),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDateTime(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} · $hour:$minute $amPm';
    } catch (_) {
      return raw;
    }
  }
}
