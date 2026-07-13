import 'package:flutter/material.dart';

import '../../repositories/medication_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/medication_tile.dart';

/// Patient-facing, read-only medication list. Caregivers manage the same
/// underlying data via MedicationManagePage; both read the identical
/// Firestore subcollection through MedicationRepository.
class MedicationPage extends StatelessWidget {
  const MedicationPage({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final repository = MedicationRepository(patientId);

    return Scaffold(
      appBar: AppBar(title: const Text("Medication")),
      body: AsyncValueView(
        stream: repository.stream(),
        builder: (context, medications) {
          if (medications.isEmpty) {
            return const Center(child: Text("No medications added yet."));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final medication in medications)
                MedicationTile(
                  timeLabel: medication.timeLabel,
                  drug: medication.drug,
                  dose: "${medication.dose}, ${medication.formattedTime}",
                ),
            ],
          );
        },
      ),
    );
  }
}
