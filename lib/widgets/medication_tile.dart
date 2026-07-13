import 'package:flutter/material.dart';

/// Read-only by default; pass [onEdit]/[onDelete] to show management
/// actions (used by the caregiver's manage screen, omitted on the
/// patient's read-only list).
class MedicationTile extends StatelessWidget {
  const MedicationTile({
    super.key,
    required this.timeLabel,
    required this.drug,
    required this.dose,
    this.onEdit,
    this.onDelete,
  });

  final String timeLabel;
  final String drug;
  final String dose;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text("$timeLabel - $drug"),
        subtitle: Text(dose),
        trailing: onEdit == null && onDelete == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                ],
              ),
      ),
    );
  }
}
