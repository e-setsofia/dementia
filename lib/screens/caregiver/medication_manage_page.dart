// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../../core/patient_resolver.dart';

class MedicationManagePage extends StatefulWidget {
  const MedicationManagePage({super.key});

  @override
  State<MedicationManagePage> createState() => _MedicationManagePageState();
}

class _MedicationManagePageState extends State<MedicationManagePage> {
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  // ─── Palette ─────────────────────────────────────────────
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF6366F1);
  static const Color _accentLight = Color(0xFF818CF8);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _success = Color(0xFF10B981);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  // ─── Data layer ───────────────────────────────────────────

  Future<void> _fetchMedications() async {
    setState(() => _isLoading = true);
    try {
      final patientId = await PatientResolver.resolve();
      if (patientId == null) {
        setState(() {
          _medications = [];
          _isLoading = false;
        });
        return;
      }

      final data = await supabase
          .from('medications')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

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

  Future<void> _addMedication(
      String drug, String dose, String time) async {
    try {
      final patientId = await PatientResolver.resolve();
      if (patientId == null) throw Exception('No linked patient found.');

      await supabase.from('medications').insert({
        'patient_id': patientId,
        'drug': drug.trim(),
        'dose': dose.trim(),
        'time': time.trim(),
      });
      await _fetchMedications();
      if (!mounted) return;
      _showSuccess('Medication added successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to add medication: $e');
    }
  }

  Future<void> _updateMedication(
      String id, String drug, String dose, String time) async {
    try {
      await supabase.from('medications').update({
        'drug': drug.trim(),
        'dose': dose.trim(),
        'time': time.trim(),
      }).eq('id', id);
      await _fetchMedications();
      if (!mounted) return;
      _showSuccess('Medication updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to update medication: $e');
    }
  }

  Future<void> _deleteMedication(String id) async {
    try {
      await supabase.from('medications').delete().eq('id', id);
      await _fetchMedications();
      if (!mounted) return;
      _showSuccess('Medication deleted');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to delete medication: $e');
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

  void _openMedicationForm({Map<String, dynamic>? existing}) {
    final drugCtrl =
        TextEditingController(text: existing?['drug'] ?? '');
    final doseCtrl =
        TextEditingController(text: existing?['dose'] ?? '');
    final timeCtrl =
        TextEditingController(text: existing?['time'] ?? '');
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
                      isEditing ? 'Edit Medication' : 'Add Medication',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Drug name
                _buildField(
                  controller: drugCtrl,
                  label: 'Drug Name',
                  hint: 'e.g. Paracetamol',
                  icon: Icons.medication_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Dose
                _buildField(
                  controller: doseCtrl,
                  label: 'Dose',
                  hint: 'e.g. 500mg',
                  icon: Icons.science_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Time
                _buildField(
                  controller: timeCtrl,
                  label: 'Time / Period',
                  hint: 'e.g. Morning, 8:00 AM',
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
                            _updateMedication(
                              existing['id'],
                              drugCtrl.text,
                              doseCtrl.text,
                              timeCtrl.text,
                            );
                          } else {
                            _addMedication(
                              drugCtrl.text,
                              doseCtrl.text,
                              timeCtrl.text,
                            );
                          }
                        },
                        child: Text(isEditing ? 'Save Changes' : 'Add Medication'),
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

  void _confirmDelete(Map<String, dynamic> med) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _danger),
            SizedBox(width: 8),
            Text('Delete Medication', style: TextStyle(color: _textPrimary)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: _textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: med['drug'] ?? 'this medication',
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
              _deleteMedication(med['id']);
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
          'Manage Medications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchMedications,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMedicationForm(),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accentLight))
          : _medications.isEmpty
              ? _buildEmptyState()
              : _buildMedicationList(),
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
            child: const Icon(Icons.medication_outlined,
                size: 56, color: _accentLight),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Medications Yet',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add\nthe first medication.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openMedicationForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Medication'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        return _MedCard(
          medication: med,
          onEdit: () => _openMedicationForm(existing: med),
          onDelete: () => _confirmDelete(med),
        );
      },
    );
  }
}

// ─── Medication Card ─────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final Map<String, dynamic> medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedCard({
    required this.medication,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF6366F1);
  static const Color _accentLight = Color(0xFF818CF8);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  Color get _timeColor {
    final t = (medication['time'] as String? ?? '').toLowerCase();
    if (t.contains('morning')) return const Color(0xFFF59E0B);
    if (t.contains('afternoon') || t.contains('noon')) return const Color(0xFF06B6D4);
    if (t.contains('night') || t.contains('evening')) return const Color(0xFF8B5CF6);
    return _accent;
  }

  IconData get _timeIcon {
    final t = (medication['time'] as String? ?? '').toLowerCase();
    if (t.contains('morning')) return Icons.wb_sunny_outlined;
    if (t.contains('afternoon') || t.contains('noon')) return Icons.wb_cloudy_outlined;
    if (t.contains('night') || t.contains('evening')) return Icons.nights_stay_outlined;
    return Icons.access_time_outlined;
  }

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
          // Top row — drug name + time badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication,
                      color: _accentLight, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication['drug'] ?? 'Unknown Drug',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        medication['dose'] ?? '',
                        style: const TextStyle(
                            color: _textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Time badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _timeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _timeColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_timeIcon, color: _timeColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        medication['time'] ?? '',
                        style: TextStyle(
                          color: _timeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
                // Edit button
                _ActionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  color: _accent,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                // Delete button
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
