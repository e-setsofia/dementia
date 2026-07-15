// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/supabase.dart';
import '../../core/patient_resolver.dart';

class PatientInfoPage extends StatefulWidget {
  const PatientInfoPage({super.key});

  @override
  State<PatientInfoPage> createState() => _PatientInfoPageState();
}

class _PatientInfoPageState extends State<PatientInfoPage>
    with SingleTickerProviderStateMixin {
  // ─── Palette ──────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0F172A);
  static const Color _surface = Color(0xFF1E293B);
  static const Color _surfaceAlt = Color(0xFF263148);
  static const Color _accent = Color(0xFF6366F1);
  static const Color _accentLight = Color(0xFF818CF8);
  static const Color _success = Color(0xFF10B981);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _bloodGroupCtrl;
  late final TextEditingController _conditionsCtrl;
  late final TextEditingController _allergiesCtrl;

  final _formKey = GlobalKey<FormState>();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _bloodGroupCtrl = TextEditingController();
    _conditionsCtrl = TextEditingController();
    _allergiesCtrl = TextEditingController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _conditionsCtrl.dispose();
    _allergiesCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Data layer ───────────────────────────────────────────────────────────

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final patientId = await PatientResolver.resolve();
      if (patientId == null) {
        setState(() {
          _profile = null;
          _isLoading = false;
        });
        return;
      }
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', patientId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _profile = data;
        _isLoading = false;
      });
      if (data != null) _populateControllers(data);
      _fadeController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load patient profile: $e');
    }
  }

  void _populateControllers(Map<String, dynamic> p) {
    _nameCtrl.text = p['name'] ?? '';
    _ageCtrl.text = p['age']?.toString() ?? '';
    _bloodGroupCtrl.text = p['blood_group'] ?? '';
    _conditionsCtrl.text = p['medical_conditions'] ?? '';
    _allergiesCtrl.text = p['allergies'] ?? '';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final patientId = _profile?['id'];
      if (patientId == null) throw Exception('No patient ID found');

      await supabase.from('profiles').update({
        'name': _nameCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text.trim()),
        'blood_group': _bloodGroupCtrl.text.trim(),
        'medical_conditions': _conditionsCtrl.text.trim(),
        'allergies': _allergiesCtrl.text.trim(),
      }).eq('id', patientId);

      await _fetchProfile();
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      _showSuccess('Patient information updated successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError('Failed to save: $e');
    }
  }

  // ─── Snack bars ───────────────────────────────────────────────────────────

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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accentLight))
          : _profile == null
              ? _buildNoPatient()
              : _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      foregroundColor: _textPrimary,
      title: const Text(
        'Patient Information',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        if (!_isEditing) ...[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchProfile,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded, size: 18, color: _accentLight),
            ),
            tooltip: 'Edit',
            onPressed: () => setState(() => _isEditing = true),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              _populateControllers(_profile!);
              setState(() => _isEditing = false);
            },
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _accentLight),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text('Save',
                      style: TextStyle(
                          color: _accentLight, fontWeight: FontWeight.bold)),
                ),
        ],
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildNoPatient() {
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
            child: const Icon(Icons.person_off_outlined,
                size: 56, color: _accentLight),
          ),
          const SizedBox(height: 20),
          const Text('No Patient Profile Found',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please ensure a patient account exists.',
              style: TextStyle(color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // ── Avatar header ─────────────────────────────────────────────
            _buildAvatarHeader(),
            const SizedBox(height: 24),

            // ── Section: Personal Details ─────────────────────────────────
            _sectionLabel('Personal Details', Icons.badge_outlined),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildField(
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                controller: _nameCtrl,
                isEditing: _isEditing,
                hint: 'e.g. John Doe',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              _divider(),
              _buildField(
                label: 'Age',
                icon: Icons.cake_outlined,
                controller: _ageCtrl,
                isEditing: _isEditing,
                hint: 'e.g. 72',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (int.tryParse(v.trim()) == null) return 'Enter a valid age';
                  return null;
                },
              ),
              _divider(),
              _buildBloodGroupField(),
            ]),
            const SizedBox(height: 20),

            // ── Section: Medical Information ──────────────────────────────
            _sectionLabel('Medical Information', Icons.medical_information_outlined),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildField(
                label: 'Medical Conditions',
                icon: Icons.monitor_heart_outlined,
                controller: _conditionsCtrl,
                isEditing: _isEditing,
                hint: 'e.g. Alzheimer\'s Stage 2, Hypertension',
                maxLines: 3,
                accentColor: _warning,
              ),
              _divider(),
              _buildField(
                label: 'Allergies',
                icon: Icons.warning_amber_rounded,
                controller: _allergiesCtrl,
                isEditing: _isEditing,
                hint: 'e.g. Penicillin, Peanuts',
                maxLines: 2,
                accentColor: _danger,
              ),
            ]),
            const SizedBox(height: 20),

            // ── Quick Summary Chips ───────────────────────────────────────
            if (!_isEditing) _buildQuickSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarHeader() {
    final name = _profile?['name'] ?? 'Patient';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'P';
    final bloodGroup = _profile?['blood_group'] ?? '';
    final age = _profile?['age'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3730A3), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentLight.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentLight, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (age != null) ...[
                      _chip('$age yrs', Icons.cake_outlined, _accentLight),
                      const SizedBox(width: 8),
                    ],
                    if (bloodGroup.isNotEmpty)
                      _chip(bloodGroup, Icons.bloodtype_outlined, _danger),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
    final conditions = (_profile?['medical_conditions'] as String?)
            ?.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final allergies = (_profile?['allergies'] as String?)
            ?.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    if (conditions.isEmpty && allergies.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Quick Summary', Icons.summarize_outlined),
        const SizedBox(height: 12),
        if (conditions.isNotEmpty) ...[
          _tagRow('Conditions', conditions, _warning),
          const SizedBox(height: 10),
        ],
        if (allergies.isNotEmpty) _tagRow('Allergies', allergies, _danger),
      ],
    );
  }

  Widget _tagRow(String label, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items.map((item) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(item,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accentLight, size: 18),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentLight.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
      height: 1, thickness: 1, color: _accentLight.withOpacity(0.07),
      indent: 16, endIndent: 16);

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isEditing,
    String hint = '',
    int maxLines = 1,
    Color? accentColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final color = accentColor ?? _accentLight;

    if (!isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment:
              maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
                  Text(label,
                      style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    controller.text.isNotEmpty ? controller.text : '—',
                    style: TextStyle(
                      color: controller.text.isNotEmpty
                          ? _textPrimary
                          : _textSecondary.withOpacity(0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Edit mode
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: color.withOpacity(0.8)),
          hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: color, size: 20),
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
            borderSide: BorderSide(color: color, width: 1.5),
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
      ),
    );
  }

  // Blood group has a dropdown
  final List<String> _bloodGroups = [
    'A+', 'A−', 'B+', 'B−', 'O+', 'O−', 'AB+', 'AB−'
  ];

  Widget _buildBloodGroupField() {
    if (!_isEditing) {
      return _buildField(
        label: 'Blood Group',
        icon: Icons.bloodtype_outlined,
        controller: _bloodGroupCtrl,
        isEditing: false,
        accentColor: _danger,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: DropdownButtonFormField<String>(
        value: _bloodGroups.contains(_bloodGroupCtrl.text.trim())
            ? _bloodGroupCtrl.text.trim()
            : null,
        dropdownColor: _surfaceAlt,
        style: const TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Blood Group',
          labelStyle: TextStyle(color: _danger.withOpacity(0.8)),
          prefixIcon: const Icon(Icons.bloodtype_outlined, color: _danger, size: 20),
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
            borderSide: const BorderSide(color: _danger, width: 1.5),
          ),
        ),
        hint: const Text('Select blood group',
            style: TextStyle(color: _textSecondary)),
        items: _bloodGroups
            .map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g, style: const TextStyle(color: _textPrimary)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) _bloodGroupCtrl.text = v;
        },
      ),
    );
  }
}
