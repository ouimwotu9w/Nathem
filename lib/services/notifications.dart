import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart' as m;
import '../utils/date_utils.dart';

/// نتيجة تجربة الإشعار: حالة الصلاحيات + هل تمت الجدولة فعلًا
class NotificationTestResult {
  const NotificationTestResult({
    required this.ready,
    required this.notificationsEnabled,
    required this.exactSchedulingWorked,
    required this.scheduled,
  });

  final bool ready; // هل نجحت تهيئة خدمة الإشعارات أصلًا
  final bool notificationsEnabled; // صلاحية إشعارات النظام (أندرويد 13+)
  final bool? exactSchedulingWorked; // هل نجحت الجدولة الدقيقة (exact)
  final bool scheduled; // هل تم جدولة الإشعار التجريبي بنجاح
}

/// خدمة التذكيرات: جدولة إشعارات أندرويد المحلية للمواعيد المتكررة أسبوعيًا.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const String _channelId = 'nathim_reminders';
  static const String _channelName = 'تذكيرات المواعيد';

  static const int _testNotificationId = 424242;
  static const String _testChannelId = 'nathim_test';
  static const String _testChannelName = 'إشعار تجريبي';

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

  /// جدولة إشعار تجريبي بعد [seconds] ثانية + فحص الصلاحيات،
  /// ليقدر المستخدم يتأكد بنفسه إن التذكيرات شغالة على جهازه.
  Future<NotificationTestResult> scheduleTestNotification(
      {int seconds = 10}) async {
    await init();

    // فحص صلاحية إشعارات النظام
    var notificationsEnabled = false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      notificationsEnabled = await android?.areNotificationsEnabled() ?? false;
    } catch (_) {}

    if (!_ready) {
      return NotificationTestResult(
        ready: false,
        notificationsEnabled: notificationsEnabled,
        exactSchedulingWorked: null,
        scheduled: false,
      );
    }

    var scheduled = false;
    bool? exactWorked;
    try {
      final fire = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
      const body = 'لو الإشعار ده وصلك، يبقى تذكيرات ناظِم شغالة تمام — '
          'هتوصلك تنبيهات مواعيدك في وقتها.';
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _testChannelId,
          _testChannelName,
          channelDescription: 'إشعار تجريبي للتأكد من عمل التذكيرات',
          importance: Importance.max,
          priority: Priority.max,
          styleInformation: BigTextStyleInformation(body),
          autoCancel: true,
        ),
      );
      Future<void> trySchedule(AndroidScheduleMode mode) =>
          _plugin.zonedSchedule(
            _testNotificationId,
            'إشعار تجريبي — ناظِم',
            body,
            fire,
            details,
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
      try {
        await trySchedule(AndroidScheduleMode.exactAllowWhileIdle);
        scheduled = true;
        exactWorked = true;
      } catch (_) {
        try {
          await trySchedule(AndroidScheduleMode.inexactAllowWhileIdle);
          scheduled = true;
          exactWorked = false;
        } catch (_) {
          scheduled = false;
          exactWorked = null;
        }
      }
    } catch (_) {
      scheduled = false;
      exactWorked = null;
    }

    return NotificationTestResult(
      ready: true,
      notificationsEnabled: notificationsEnabled,
      exactSchedulingWorked: exactWorked,
      scheduled: scheduled,
    );
  }
}
