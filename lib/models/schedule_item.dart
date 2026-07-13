class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.task,
    required this.hour,
    required this.minute,
  });

  final String id;
  final String task;
  final int hour; // 0-23, local time-of-day
  final int minute;

  String get formattedTime {
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  factory ScheduleItem.fromMap(String id, Map<String, dynamic> data) {
    return ScheduleItem(
      id: id,
      task: data['task'] as String? ?? '',
      hour: data['hour'] as int? ?? 8,
      minute: data['minute'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'hour': hour,
      'minute': minute,
    };
  }
}
