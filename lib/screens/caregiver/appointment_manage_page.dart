// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../../core/patient_resolver.dart';

class AppointmentManagePage extends StatefulWidget {
  const AppointmentManagePage({super.key});

  @override
  State<AppointmentManagePage> createState() => _AppointmentManagePageState();
}

class _AppointmentManagePageState extends State<AppointmentManagePage> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  // ─── Palette ─────────────────────────────────────────────
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFFF97316); // Orange
  static const Color _accentLight = Color(0xFFFB923C);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _success = Color(0xFF10B981);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  // ─── Data layer ───────────────────────────────────────────

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final patientId = await PatientResolver.resolve();

      if (patientId == null) {
        setState(() {
          _appointments = [];
          _isLoading = false;
        });
        return;
      }

      final data = await supabase
          .from('appointments')
          .select()
          .eq('patient_id', patientId)
          .order('appointment_time', ascending: true);

      setState(() {
        _appointments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load appointments: $e');
    }
  }

  Future<void> _addAppointment(String title, String doctor, DateTime time) async {
    try {
      final patientId = await PatientResolver.resolve();

      if (patientId == null) {
        throw Exception("No patient profile found in database.");
      }

      await supabase.from('appointments').insert({
        'patient_id': patientId,
        'title': title.trim(),
        'doctor_name': doctor.trim(),
        'appointment_time': time.toUtc().toIso8601String(),
      });
      await _fetchAppointments();
      if (!mounted) return;
      _showSuccess('Appointment scheduled successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to schedule appointment: $e');
    }
  }

  Future<void> _updateAppointment(String id, String title, String doctor, DateTime time) async {
    try {
      await supabase.from('appointments').update({
        'title': title.trim(),
        'doctor_name': doctor.trim(),
        'appointment_time': time.toUtc().toIso8601String(),
      }).eq('id', id);
      await _fetchAppointments();
      if (!mounted) return;
      _showSuccess('Appointment updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to update appointment: $e');
    }
  }

  Future<void> _deleteAppointment(String id) async {
    try {
      await supabase.from('appointments').delete().eq('id', id);
      await _fetchAppointments();
      if (!mounted) return;
      _showSuccess('Appointment deleted');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to delete appointment: $e');
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

  // ─── Date Time Picker dialog helper ───────────────────────

  Future<DateTime?> _selectDateTime(BuildContext context, DateTime initial) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              onPrimary: Colors.white,
              surface: _surface,
              onSurface: _textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _accentLight),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return null;

    if (!context.mounted) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              onPrimary: Colors.white,
              surface: _surface,
              onSurface: _textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _accentLight),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  // ─── Bottom sheet form (Add / Edit) ──────────────────────

  void _openAppointmentForm({Map<String, dynamic>? existing}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final docCtrl = TextEditingController(text: existing?['doctor_name'] ?? '');
    final formKey = GlobalKey<FormState>();
    final bool isEditing = existing != null;
    DateTime selectedDateTime = existing != null
        ? DateTime.parse(existing['appointment_time']).toLocal()
        : DateTime.now().add(const Duration(hours: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                              isEditing ? Icons.edit_calendar : Icons.add_moderator,
                              color: _accentLight,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEditing ? 'Edit Appointment' : 'Add Appointment',
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title
                      _buildField(
                        controller: titleCtrl,
                        label: 'Reason / Title',
                        hint: 'e.g. Weekly Checkup, Dental Check',
                        icon: Icons.event,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Doctor Name
                      _buildField(
                        controller: docCtrl,
                        label: 'Doctor Name',
                        hint: 'e.g. Dr. Smith',
                        icon: Icons.person_search,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Time Display/Select Button
                      InkWell(
                        onTap: () async {
                          final selected = await _selectDateTime(context, selectedDateTime);
                          if (selected != null) {
                            setModalState(() {
                              selectedDateTime = selected;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _textSecondary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, color: _accentLight, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date & Time',
                                      style: TextStyle(color: _textSecondary, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedDateTime.toString().substring(0, 16),
                                      style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: _textSecondary),
                            ],
                          ),
                        ),
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
                                  _updateAppointment(
                                    existing['id'],
                                    titleCtrl.text,
                                    docCtrl.text,
                                    selectedDateTime,
                                  );
                                } else {
                                  _addAppointment(
                                    titleCtrl.text,
                                    docCtrl.text,
                                    selectedDateTime,
                                  );
                                }
                              },
                              child: Text(isEditing ? 'Save Changes' : 'Schedule'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  void _confirmDelete(Map<String, dynamic> appt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _danger),
            SizedBox(width: 8),
            Text('Delete Appointment', style: TextStyle(color: _textPrimary)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: _textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Are you sure you want to delete the appointment '),
              TextSpan(
                text: appt['title'] ?? 'this appointment',
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
              _deleteAppointment(appt['id']);
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
          'Appointment Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchAppointments,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAppointmentForm(),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accentLight))
          : _appointments.isEmpty
              ? _buildEmptyState()
              : _buildAppointmentList(),
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
            child: const Icon(Icons.event_available_outlined,
                size: 56, color: _accentLight),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Scheduled Appointments",
            style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap the button below to schedule\nyour patient's first appointment.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openAppointmentForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Appointment'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onEdit: () => _openAppointmentForm(existing: appointment),
          onDelete: () => _confirmDelete(appointment),
        );
      },
    );
  }
}

// ─── Appointment Card ──────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AppointmentCard({
    required this.appointment,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFFF97316);
  static const Color _accentLight = Color(0xFFFB923C);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final rawTime = appointment['appointment_time'];
    final formattedTime = rawTime != null
        ? DateTime.parse(rawTime).toLocal().toString().substring(0, 16)
        : 'N/A';

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
                  child: const Icon(Icons.event,
                      color: _accentLight, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['title'] ?? 'Reason Unknown',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: _textSecondary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            appointment['doctor_name'] ?? 'Doctor',
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_month,
                              color: _textSecondary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
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
