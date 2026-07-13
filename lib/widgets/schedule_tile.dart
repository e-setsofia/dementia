import 'package:flutter/material.dart';

class ScheduleTile extends StatelessWidget {
  final String time;
  final String task;

  const ScheduleTile({
    super.key,
    required this.time,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.green),
        title: Text(task),
        subtitle: Text(time),
      ),
    );
  }
}
