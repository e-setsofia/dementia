// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../../core/patient_resolver.dart';

class ScheduleManagePage extends StatefulWidget {
  const ScheduleManagePage({super.key});

  @override
  State<ScheduleManagePage> createState() => _ScheduleManagePageState();
}

class _ScheduleManagePageState extends State<ScheduleManagePage> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  // ─── Palette ─────────────────────────────────────────────
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF14B8A6); // Teal
  static const Color _accentLight = Color(0xFF2DD4BF);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _success = Color(0xFF10B981);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  // ─── Data layer ───────────────────────────────────────────

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final patientId = await PatientResolver.resolve();

      if (patientId == null) {
        setState(() {
          _schedules = [];
          _isLoading = false;
        });
        return;
      }

      final data = await supabase
          .from('schedules')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: true); // Chronological order of tasks

      setState(() {
        _schedules = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load schedules: $e');
    }
  }

  Future<void> _addSchedule(String task, String time) async {
    try {
      final patientId = await PatientResolver.resolve();

      if (patientId == null) {
        throw Exception("No patient profile found in database.");
      }

      await supabase.from('schedules').insert({
        'patient_id': patientId,
        'task': task.trim(),
        'time': time.trim(),
      });
      await _fetchSchedules();
      if (!mounted) return;
      _showSuccess('Activity added successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to add activity: $e');
    }
  }

  Future<void> _updateSchedule(String id, String task, String time) async {
    try {
      await supabase.from('schedules').update({
        'task': task.trim(),
        'time': time.trim(),
      }).eq('id', id);
      await _fetchSchedules();
      if (!mounted) return;
      _showSuccess('Activity updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to update activity: $e');
    }
  }

  Future<void> _deleteSchedule(String id) async {
    try {
      await supabase.from('schedules').delete().eq('id', id);
      await _fetchSchedules();
      if (!mounted) return;
      _showSuccess('Activity deleted');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to delete activity: $e');
    }
  }

  // ─── UI Helpers ───────────────────────────────────────────

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: _success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── Bottom sheet form (Add / Edit) ──────────────────────

  void _openScheduleForm({Map<String, dynamic>? existing}) {
    final taskCtrl = TextEditingController(text: existing?['task'] ?? '');
    final timeCtrl = TextEditingController(text: existing?['time'] ?? '');
    final formKey = GlobalKey<FormState>();
    final bool isEditing = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textSecondary.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note : Icons.add_circle_outline,
                        color: _accentLight,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Activity' : 'Add Activity',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Task
                _buildField(
                  controller: taskCtrl,
                  label: 'Activity / Task',
                  hint: 'e.g. Morning Walk, Breakfast',
                  icon: Icons.calendar_today_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Time
                _buildField(
                  controller: timeCtrl,
                  label: 'Time',
                  hint: 'e.g. 8:00 AM, 5:30 PM',
                  icon: Icons.access_time_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 28),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSecondary,
                          side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(context);
                          if (isEditing) {
                            _updateSchedule(
                              existing['id'],
                              taskCtrl.text,
                              timeCtrl.text,
                            );
                          } else {
                            _addSchedule(
                              taskCtrl.text,
                              timeCtrl.text,
                            );
                          }
                        },
                        child: Text(isEditing ? 'Save Changes' : 'Add Activity'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _textSecondary),
        hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: _accentLight, size: 20),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger, width: 1.5),
        ),
      ),
    );
  }

  // ─── Delete confirmation dialog ───────────────────────────

  void _confirmDelete(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _danger),
            SizedBox(width: 8),
            Text('Delete Activity', style: TextStyle(color: _textPrimary)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: _textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: schedule['task'] ?? 'this activity',
                style: const TextStyle(
                    color: _textPrimary, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? This action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteSchedule(schedule['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text(
          'Manage Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchSchedules,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScheduleForm(),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accentLight))
          : _schedules.isEmpty
              ? _buildEmptyState()
              : _buildScheduleList(),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(Icons.calendar_today_outlined,
                size: 56, color: _accentLight),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Activities Today",
            style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap the button below to add\ntoday's first task/activity.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openScheduleForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        return _ScheduleCard(
          schedule: schedule,
          onEdit: () => _openScheduleForm(existing: schedule),
          onDelete: () => _confirmDelete(schedule),
        );
      },
    );
  }
}

// ─── Schedule Card ─────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF14B8A6);
  static const Color _accentLight = Color(0xFF2DD4BF);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentLight.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.schedule,
                      color: _accentLight, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule['task'] ?? 'Unknown Activity',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              color: _textSecondary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            schedule['time'] ?? 'No time set',
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider + action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  color: _accent,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  color: _danger,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
