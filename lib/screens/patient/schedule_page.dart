// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // ─── Palette ──────────────────────────────────────────────
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF14B8A6);
  static const Color _accentLight = Color(0xFF2DD4BF);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  List<Map<String, dynamic>> _schedules = [];
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
          .from('schedules')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: true);
      if (!mounted) return;
      setState(() {
        _schedules = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[SchedulePage] Failed to load schedule: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load schedule: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text('Today\'s Schedule',
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
          : Column(
              children: [
                // Date header
                _buildDateHeader(today),
                Expanded(
                  child: _schedules.isEmpty
                      ? _buildEmpty()
                      : _buildTimeline(),
                ),
              ],
            ),
    );
  }

  Widget _buildDateHeader(String today) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withOpacity(0.15),
            _bg,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          bottom: BorderSide(color: _accentLight.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today_outlined,
                color: _accentLight, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(today,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text('${_schedules.length} activit${_schedules.length != 1 ? 'ies' : 'y'} planned',
                  style:
                      const TextStyle(color: _textSecondary, fontSize: 12)),
            ],
          ),
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
            child: const Icon(Icons.event_note_outlined,
                size: 52, color: _accentLight),
          ),
          const SizedBox(height: 20),
          const Text('No Activities Scheduled',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your caregiver hasn\'t created\nany activities yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final item = _schedules[index];
        final isLast = index == _schedules.length - 1;
        return _TimelineItem(
          task: item['task'] ?? 'Activity',
          time: item['time'] ?? '',
          isLast: isLast,
          accent: _accentLight,
          index: index,
        );
      },
    );
  }

  String _weekday(int w) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(w - 1).clamp(0, 6)];
  }

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}

// ─── Timeline Item ─────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final String task;
  final String time;
  final bool isLast;
  final Color accent;
  final int index;

  const _TimelineItem({
    required this.task,
    required this.time,
    required this.isLast,
    required this.accent,
    required this.index,
  });

  static const Color _surface = Color(0xFF1E293B);
  static const Color _textPrimary = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
    ];
    final dotColor = colors[index % colors.length];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline bar
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: dotColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: dotColor.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: dotColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task,
                            style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                  if (time.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: dotColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_outlined,
                              color: dotColor, size: 12),
                          const SizedBox(width: 4),
                          Text(time,
                              style: TextStyle(
                                  color: dotColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
