import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';

/// Wraps flutter_local_notifications and the timezone package so the rest
/// of the app only ever calls scheduleDaily/cancel/reconcile, never the
/// plugin directly. This is the single place daily medication reminders
/// are created, updated, or removed.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_localFixedOffsetZoneName()));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  Future<void> scheduleDaily(Medication medication) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      medication.hour,
      medication.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      medication.notificationId,
      "Medication reminder",
      "${medication.drug} (${medication.dose})",
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders to take scheduled medication',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Cancels every previously-scheduled reminder and re-schedules from
  /// [medications]. Called on each patient dashboard load rather than
  /// diffing individual adds/edits/deletes: at this app's scale (a handful
  /// of medications) a full reconcile is simpler and avoids drift bugs
  /// from partial failures.
  Future<void> reconcile(List<Medication> medications) async {
    await cancelAll();
    for (final medication in medications) {
      await scheduleDaily(medication);
    }
  }
}

/// Resolves the device's local UTC offset (via Dart's own DateTime, no
/// native plugin needed) to one of the timezone package's fixed-offset
/// "Etc/GMT" zones. Note the IANA Etc/GMT sign convention is inverted from
/// normal usage: Etc/GMT-2 means UTC+2. Offsets are rounded to the nearest
/// whole hour, so places with half-hour offsets (e.g. India, UTC+5:30) get
/// approximated, and daylight-saving transitions aren't tracked since a
/// fixed offset has no DST rules. Both are acceptable v1 limitations for a
/// reminder that only needs to land within the right hour.
String _localFixedOffsetZoneName() {
  final offsetHours = (DateTime.now().timeZoneOffset.inMinutes / 60).round();
  final clamped = offsetHours.clamp(-12, 14);
  if (clamped == 0) return 'Etc/GMT';
  final sign = clamped > 0 ? '-' : '+';
  return 'Etc/GMT$sign${clamped.abs()}';
}
