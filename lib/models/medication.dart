class Medication {
  const Medication({
    required this.id,
    required this.drug,
    required this.dose,
    required this.timeLabel,
    required this.hour,
    required this.minute,
  });

  final String id;
  final String drug;
  final String dose;
  final String timeLabel; // e.g. "Morning" / "Afternoon" / "Night"
  final int hour; // 0-23, local time-of-day
  final int minute;

  /// Stable positive id derived from [id], used as the
  /// flutter_local_notifications notification id so the same medication
  /// always schedules/cancels the same reminder.
  int get notificationId => id.hashCode & 0x7fffffff;

  String get formattedTime {
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  factory Medication.fromMap(String id, Map<String, dynamic> data) {
    return Medication(
      id: id,
      drug: data['drug'] as String? ?? '',
      dose: data['dose'] as String? ?? '',
      timeLabel: data['timeLabel'] as String? ?? '',
      hour: data['hour'] as int? ?? 8,
      minute: data['minute'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'drug': drug,
      'dose': dose,
      'timeLabel': timeLabel,
      'hour': hour,
      'minute': minute,
    };
  }
}
