import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart' as m;
import '../utils/date_utils.dart';

/// خدمة التذكيرات: جدولة إشعارات أندرويد المحلية للمواعيد المتكررة أسبوعيًا.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const String _channelId = 'nathim_reminders';
  static const String _channelName = 'تذكيرات المواعيد';

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
        } catch (_) {
          // تجاهل: سيستخدم النظام UTC كخيار أخير
        }
      }
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      // فشل التهيئة لا يعطل التطبيق
    }
  }

  /// طلب صلاحيات الإشعارات والتنبيهات الدقيقة (أندرويد 13+)
  Future<void> requestPermissions() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  DateTime? _nextOccurrence(m.WeekAppointment a, DateTime now) {
    for (var i = 0; i < 8; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (day.weekday == a.weekday) {
        return DateTime(
          day.year,
          day.month,
          day.day,
          a.startMinutes ~/ 60,
          a.startMinutes % 60,
        );
      }
    }
    return null;
  }

  /// إعادة جدولة كل التذكيرات: يُستدعى بعد أي تعديل على المواعيد وعند فتح التطبيق.
  Future<void> rescheduleAll(
      List<m.WeekAppointment> appointments, bool enabled) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (!enabled) return;
      final now = DateTime.now();
      for (final a in appointments) {
        if (!a.active || a.reminderMinutesBefore <= 0) continue;
        final occ = _nextOccurrence(a, now);
        if (occ == null) continue;
        final fireAt = occ.subtract(Duration(minutes: a.reminderMinutesBefore));
        if (!fireAt.isAfter(now)) continue;

        final body =
            'لديك موعد «${a.title}» بعد ${reminderShort(a.reminderMinutesBefore)}'
            ' — ${formatRange(a.startMinutes, a.endMinutes)}';
        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'إشعار قبل مواعيدك الأسبوعية المتكررة',
            importance: Importance.max,
            priority: Priority.max,
            styleInformation: BigTextStyleInformation(body),
            autoCancel: true,
          ),
        );
        final tzTime = tz.TZDateTime.from(fireAt, tz.local);
        try {
          await _plugin.zonedSchedule(
            a.notifyId,
            'تذكير بموعد',
            body,
            tzTime,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (_) {
          try {
            await _plugin.zonedSchedule(
              a.notifyId,
              'تذكير بموعد',
              body,
              tzTime,
              details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          } catch (_) {
            // تعذر الجدولة على هذا الجهاز — نتجاهل بهدوء
          }
        }
      }
    } catch (_) {}
  }
}
