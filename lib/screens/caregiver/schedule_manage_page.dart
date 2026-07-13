import 'package:flutter/material.dart';

import '../../models/schedule_item.dart';
import '../../repositories/schedule_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/schedule_tile.dart';

/// Caregiver-facing schedule list with add/edit/delete. Writes go to the
/// same Firestore subcollection the patient's read-only SchedulePage
/// streams from, so changes show up there immediately.
class ScheduleManagePage extends StatelessWidget {
  const ScheduleManagePage({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final repository = ScheduleRepository(patientId);

    return Scaffold(
      appBar: AppBar(title: const Text("Daily Schedule")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleForm(context, repository),
        child: const Icon(Icons.add),
      ),
      body: AsyncValueView(
        stream: repository.stream(),
        builder: (context, items) {
          if (items.isEmpty) {
            return const Center(child: Text("No schedule items yet. Tap + to add one."));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in items)
                ScheduleTile(
                  time: item.formattedTime,
                  task: item.task,
                  onEdit: () => _showScheduleForm(context, repository, existing: item),
                  onDelete: () => repository.delete(item.id),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showScheduleForm(
    BuildContext context,
    ScheduleRepository repository, {
    ScheduleItem? existing,
  }) async {
    final taskController = TextEditingController(text: existing?.task ?? '');
    TimeOfDay time = TimeOfDay(hour: existing?.hour ?? 8, minute: existing?.minute ?? 0);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(existing == null ? "Add Schedule Item" : "Edit Schedule Item"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: taskController,
                    decoration: const InputDecoration(labelText: "Task"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text("Time: ${time.format(dialogContext)}"),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (taskController.text.trim().isEmpty) return;
                    final item = ScheduleItem(
                      id: existing?.id ?? '',
                      task: taskController.text.trim(),
                      hour: time.hour,
                      minute: time.minute,
                    );
                    if (existing == null) {
                      await repository.add(item);
                    } else {
                      await repository.update(existing.id, item);
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
