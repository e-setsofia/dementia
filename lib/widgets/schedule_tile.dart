import 'package:flutter/material.dart';

/// Read-only by default; pass [onEdit]/[onDelete] to show management
/// actions (used by the caregiver's manage screen, omitted on the
/// patient's read-only list).
class ScheduleTile extends StatelessWidget {
  const ScheduleTile({
    super.key,
    required this.time,
    required this.task,
    this.onEdit,
    this.onDelete,
  });

  final String time;
  final String task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.green),
        title: Text(task),
        subtitle: Text(time),
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
