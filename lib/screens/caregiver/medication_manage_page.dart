import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../repositories/medication_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/medication_tile.dart';

/// Caregiver-facing medication list with add/edit/delete. Writes go to
/// the same Firestore subcollection the patient's read-only MedicationPage
/// streams from, so changes show up there immediately.
class MedicationManagePage extends StatelessWidget {
  const MedicationManagePage({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final repository = MedicationRepository(patientId);

    return Scaffold(
      appBar: AppBar(title: const Text("Medication Management")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMedicationForm(context, repository),
        child: const Icon(Icons.add),
      ),
      body: AsyncValueView(
        stream: repository.stream(),
        builder: (context, medications) {
          if (medications.isEmpty) {
            return const Center(child: Text("No medications yet. Tap + to add one."));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final medication in medications)
                MedicationTile(
                  timeLabel: medication.timeLabel,
                  drug: medication.drug,
                  dose: "${medication.dose}, ${medication.formattedTime}",
                  onEdit: () => _showMedicationForm(context, repository, existing: medication),
                  onDelete: () => repository.delete(medication.id),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showMedicationForm(
    BuildContext context,
    MedicationRepository repository, {
    Medication? existing,
  }) async {
    final drugController = TextEditingController(text: existing?.drug ?? '');
    final doseController = TextEditingController(text: existing?.dose ?? '');
    final timeLabelController = TextEditingController(text: existing?.timeLabel ?? '');
    TimeOfDay time = TimeOfDay(hour: existing?.hour ?? 8, minute: existing?.minute ?? 0);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(existing == null ? "Add Medication" : "Edit Medication"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: drugController,
                      decoration: const InputDecoration(labelText: "Drug name"),
                    ),
                    TextField(
                      controller: doseController,
                      decoration: const InputDecoration(labelText: "Dose"),
                    ),
                    TextField(
                      controller: timeLabelController,
                      decoration: const InputDecoration(labelText: "Time label (e.g. Morning)"),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text("Reminder time: ${time.format(dialogContext)}"),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: dialogContext, initialTime: time);
                            if (picked != null) setState(() => time = picked);
                          },
                          child: const Text("Change"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (drugController.text.trim().isEmpty) return;
                    final medication = Medication(
                      id: existing?.id ?? '',
                      drug: drugController.text.trim(),
                      dose: doseController.text.trim(),
                      timeLabel: timeLabelController.text.trim(),
                      hour: time.hour,
                      minute: time.minute,
                    );
                    if (existing == null) {
                      await repository.add(medication);
                    } else {
                      await repository.update(existing.id, medication);
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
