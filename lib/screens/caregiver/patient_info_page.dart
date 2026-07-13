import 'package:flutter/material.dart';

import '../../models/patient_info.dart';
import '../../repositories/patient_info_repository.dart';
import '../../widgets/async_value_view.dart';

class PatientInfoPage extends StatelessWidget {
  const PatientInfoPage({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final repository = PatientInfoRepository();

    return Scaffold(
      appBar: AppBar(title: const Text("Patient Information")),
      body: AsyncValueView(
        stream: repository.stream(patientId),
        builder: (context, info) {
          return _PatientInfoForm(
            initial: info,
            onSave: (updated) => repository.save(patientId, updated),
          );
        },
      ),
    );
  }
}

class _PatientInfoForm extends StatefulWidget {
  const _PatientInfoForm({required this.initial, required this.onSave});

  final PatientInfo initial;
  final Future<void> Function(PatientInfo) onSave;

  @override
  State<_PatientInfoForm> createState() => _PatientInfoFormState();
}

class _PatientInfoFormState extends State<_PatientInfoForm> {
  late final nameController = TextEditingController(text: widget.initial.name);
  late final ageController =
      TextEditingController(text: widget.initial.age == 0 ? '' : '${widget.initial.age}');
  late final conditionController = TextEditingController(text: widget.initial.condition);
  late final bloodGroupController = TextEditingController(text: widget.initial.bloodGroup);

  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    conditionController.dispose();
    bloodGroupController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => isSaving = true);
    final info = PatientInfo(
      name: nameController.text.trim(),
      age: int.tryParse(ageController.text.trim()) ?? 0,
      condition: conditionController.text.trim(),
      bloodGroup: bloodGroupController.text.trim(),
    );
    await widget.onSave(info);
    if (mounted) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient information saved.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Name"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Age"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: conditionController,
            decoration: const InputDecoration(labelText: "Condition"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bloodGroupController,
            decoration: const InputDecoration(labelText: "Blood Group"),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isSaving ? null : save,
            child: isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Save"),
          ),
        ],
      ),
    );
  }
}
