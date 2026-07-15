// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';

class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  // ─── Palette ──────────────────────────────────────────────
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF6366F1);
  static const Color _accentLight = Color(0xFF818CF8);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _patientId = supabase.auth.currentUser?.id;
      if (_patientId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final data = await supabase
          .from('medications')
          .select()
          .eq('patient_id', _patientId!)
          .order('created_at');
      if (!mounted) return;
      setState(() {
        _medications = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load medications: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text('My Medications',
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
          : _medications.isEmpty
              ? _buildEmpty()
              : _buildList(),
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
            child: const Icon(Icons.medication_outlined,
                size: 52, color: _accentLight),
          ),
          const SizedBox(height: 20),
          const Text('No Medications Yet',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your caregiver hasn\'t added\nany medications yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildList() {
    // Group by time period
    final morning = _medications
        .where((m) => (m['time'] as String? ?? '').toLowerCase().contains('morning'))
        .toList();
    final afternoon = _medications
        .where((m) {
          final t = (m['time'] as String? ?? '').toLowerCase();
          return t.contains('afternoon') || t.contains('noon');
        })
        .toList();
    final night = _medications
        .where((m) {
          final t = (m['time'] as String? ?? '').toLowerCase();
          return t.contains('night') || t.contains('evening');
        })
        .toList();
    final other = _medications
        .where((m) {
          final t = (m['time'] as String? ?? '').toLowerCase();
          return !t.contains('morning') &&
              !t.contains('afternoon') &&
              !t.contains('noon') &&
              !t.contains('night') &&
              !t.contains('evening');
        })
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Summary banner
        _buildSummaryBanner(),
        const SizedBox(height: 20),
        if (morning.isNotEmpty) ...[
          _timeHeader('☀️  Morning', const Color(0xFFF59E0B)),
          ...morning.map(_medCard),
          const SizedBox(height: 16),
        ],
        if (afternoon.isNotEmpty) ...[
          _timeHeader('⛅  Afternoon', const Color(0xFF06B6D4)),
          ...afternoon.map(_medCard),
          const SizedBox(height: 16),
        ],
        if (night.isNotEmpty) ...[
          _timeHeader('🌙  Night', const Color(0xFF8B5CF6)),
          ...night.map(_medCard),
          const SizedBox(height: 16),
        ],
        if (other.isNotEmpty) ...[
          _timeHeader('🕐  Other', _accentLight),
          ...other.map(_medCard),
        ],
      ],
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3730A3), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentLight.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_medications.length} Medication${_medications.length != 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const Text('Prescribed by your caregiver',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withOpacity(0.3), thickness: 1)),
        ],
      ),
    );
  }

  Widget _medCard(Map<String, dynamic> med) {
    final t = (med['time'] as String? ?? '').toLowerCase();
    Color timeColor;
    IconData timeIcon;
    if (t.contains('morning')) {
      timeColor = const Color(0xFFF59E0B);
      timeIcon = Icons.wb_sunny_outlined;
    } else if (t.contains('afternoon') || t.contains('noon')) {
      timeColor = const Color(0xFF06B6D4);
      timeIcon = Icons.wb_cloudy_outlined;
    } else if (t.contains('night') || t.contains('evening')) {
      timeColor = const Color(0xFF8B5CF6);
      timeIcon = Icons.nights_stay_outlined;
    } else {
      timeColor = _accentLight;
      timeIcon = Icons.access_time_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentLight.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication, color: _accentLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['drug'] ?? 'Unknown',
                    style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(med['dose'] ?? '',
                    style:
                        const TextStyle(color: _textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: timeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: timeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(timeIcon, color: timeColor, size: 13),
                const SizedBox(width: 4),
                Text(med['time'] ?? '',
                    style: TextStyle(
                        color: timeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
