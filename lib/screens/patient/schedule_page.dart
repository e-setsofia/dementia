import 'package:flutter/material.dart';

import '../../repositories/schedule_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/schedule_tile.dart';

/// Patient-facing, read-only schedule list. Caregivers manage the same
/// underlying data via ScheduleManagePage.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final repository = ScheduleRepository(patientId);

    return Scaffold(
      appBar: AppBar(title: const Text("Daily Schedule")),
      body: AsyncValueView(
        stream: repository.stream(),
        builder: (context, items) {
          if (items.isEmpty) {
            return const Center(child: Text("No schedule items added yet."));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in items)
                ScheduleTile(time: item.formattedTime, task: item.task),
            ],
          );
        },
      ),
    );
  }
}
