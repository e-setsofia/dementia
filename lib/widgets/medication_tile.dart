import 'package:flutter/material.dart';

class MedicationTile extends StatelessWidget {
  final String time;
  final String drug;
  final String dose;

  const MedicationTile({
    super.key,
    required this.time,
    required this.drug,
    required this.dose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text("$time - $drug"),
        subtitle: Text(dose),
      ),
    );
  }
}
