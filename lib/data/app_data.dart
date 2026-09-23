import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/notifications.dart';
import '../utils/date_utils.dart';

/// إحصائية يوم واحدة (لرسم آخر 7 أيام)
class DayStat {
  final String label;
  final int done;
  final int total;

  const DayStat(this.label, this.done, this.total);

  double get ratio => total == 0 ? 0 : done / total;
}

/// المخزن المركزي: كل بيانات المستخدم (مواعيد / مهام / روتين / إعدادات)
/// محفوظة في SharedPreferences كمستند JSON واحد + تصدير/استيراد.
class AppData extends ChangeNotifier {
  static const String _storageKey = 'nathim_data_v1';

  final List<WeekAppointment> _appointments = [];
  final List<Task> _tasks = [];
  final List<RoutineItem> _routine = [];
  bool _remindersEnabled = true;
  bool _lightMode = false;
  SharedPreferences? _prefs;
  bool _loaded = false;

  List<WeekAppointment> get appointments => List.unmodifiable(_appointments);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<RoutineItem> get routine => List.unmodifiable(_routine);
  bool get remindersEnabled => _remindersEnabled;
  bool get lightMode => _lightMode;

  // ================= التحميل والحفظ =================

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _applyJson(raw);
      } else {
        _seedSamples();
        await _save();
      }
    } catch (_) {
      _seedSamples();
    }
    notifyListeners();
  }

  void _applyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      _remindersEnabled = asBool(map['remindersEnabled'], true);
      _lightMode = asBool(map['lightMode'], false);
      _appointments
        ..clear()
        ..addAll(((map['appointments'] as List?) ?? const [])
            .map((e) => WeekAppointment.fromJson(Map<String, dynamic>.from(e as Map))));
      _tasks
        ..clear()
        ..addAll(((map['tasks'] as List?) ?? const [])
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map))));
      _routine
        ..clear()
        ..addAll(((map['routine'] as List?) ?? const [])
            .map((e) => RoutineItem.fromJson(Map<String, dynamic>.from(e as Map))));
    } catch (_) {}
  }

  void _seedSamples() {
    _appointments.add(WeekAppointment(
      id: newId(),
      title: 'زيارة الأهل',
      note: 'مثال — عدّله أو احذفه',
      weekday: 7, // الأحد
      startMinutes: 17 * 60,
      endMinutes: 19 * 60,
      reminderMinutesBefore: 30,
    ));
    final today = dateKey(DateTime.now());
    _tasks.add(Task(
      id: newId(),
      title: 'مهمة تجريبية: علّم عليها كمنجزة',
      note: 'مثال — عدّله أو احذفه',
      priority: Priority.medium,
      category: 'personal',
      dateKey: today,
    ));
    _routine.add(RoutineItem(
      id: newId(),
      title: 'قراءة ورد يومي',
      timeMinutes: 5 * 60 + 30,
    ));
  }

  Map<String, dynamic> toJson() => {
        'schema': 1,
        'remindersEnabled': _remindersEnabled,
        'lightMode': _lightMode,
        'appointments': _appointments.map((e) => e.toJson()).toList(),
        'tasks': _tasks.map((e) => e.toJson()).toList(),
        'routine': _routine.map((e) => e.toJson()).toList(),
      };

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  Future<bool> importJson(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      _applyJson(raw);
      await _save();
      notifyListeners();
      await refreshNotifications();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _save() async {
    try {
      await _prefs?.setString(_storageKey, jsonEncode(toJson()));
    } catch (_) {}
  }

  Future<void> refreshNotifications() async {
    await NotificationService.instance.rescheduleAll(_appointments, _remindersEnabled);
  }

  Future<void> clearAll() async {
    _appointments.clear();
    _tasks.clear();
    _routine.clear();
    await _save();
    notifyListeners();
    await refreshNotifications();
  }

  // ================= المواعيد الأسبوعية =================

  List<WeekAppointment> appointmentsForWeekday(int weekday) {
    final list = _appointments
        .where((a) => a.weekday == weekday && a.active)
        .toList()
      ..sort((x, y) => x.startMinutes.compareTo(y.startMinutes));
    return list;
  }

  int countForWeekday(int weekday) =>
      _appointments.where((a) => a.weekday == weekday && a.active).length;

  WeekAppointment? nextAppointmentToday(DateTime now) {
    for (final a in appointmentsForWeekday(now.weekday)) {
      if (a.endMinutes > minutesNow(now)) return a;
    }
    return null;
  }

  // ================= كشف تعارض المواعيد =================

  /// هل الموعدان [a] و [b] متقاطعان زمنيًا؟
  /// (التلاقي عند الحدود — نهاية أحدهم = بداية الآخر — ليس تعارضًا)
  static bool _overlaps(WeekAppointment a, WeekAppointment b) =>
      a.startMinutes < b.endMinutes && b.startMinutes < a.endMinutes;

  /// معرفات المواعيد المتعارضة زمنيًا في يوم معين من الأسبوع.
  Set<String> conflictIdsForWeekday(int weekday) {
    final apps = appointmentsForWeekday(weekday);
    final ids = <String>{};
    for (var i = 0; i < apps.length; i++) {
      for (var j = i + 1; j < apps.length; j++) {
        if (_overlaps(apps[i], apps[j])) {
          ids.add(apps[i].id);
          ids.add(apps[j].id);
        }
      }
    }
    return ids;
  }

  /// عدد المواعيد المتعارضة في يوم معين (لشارة التنبيه على أزرار الأيام)
  int conflictCountForWeekday(int weekday) =>
      conflictIdsForWeekday(weekday).length;

  /// هل التوقيت المطلوب سيتعارض مع موعد موجود؟
  /// [ignoreId] يُستثنى عند تعديل موعد قائم.
  bool hasConflictWith({
    required int weekday,
    required int start,
    required int end,
    String? ignoreId,
  }) {
    for (final a in _appointments) {
      if (!a.active || a.weekday != weekday || a.id == ignoreId) continue;
      if (start < a.endMinutes && a.startMinutes < end) return true;
    }
    return false;
  }

  Future<void> addAppointment(String title, String note, int weekday,
      int start, int end, int reminder) async {
    _appointments.add(WeekAppointment(
      id: newId(),
      title: title.trim(),
      note: note.trim(),
      weekday: weekday,
      startMinutes: start,
      endMinutes: end,
      reminderMinutesBefore: reminder,
    ));
    await _save();
    notifyListeners();
    await refreshNotifications();
  }

  Future<void> updateAppointment(
    WeekAppointment a, {
    String? title,
    String? note,
    int? weekday,
    int? start,
    int? end,
    int? reminder,
  }) async {
    if (title != null) a.title = title.trim();
    if (note != null) a.note = note.trim();
    if (weekday != null) a.weekday = weekday;
    if (start != null) a.startMinutes = start;
    if (end != null) a.endMinutes = end;
    if (reminder != null) a.reminderMinutesBefore = reminder;
    await _save();
    notifyListeners();
    await refreshNotifications();
  }

  Future<void> deleteAppointment(String id) async {
    _appointments.removeWhere((a) => a.id == id);
    await _save();
    notifyListeners();
    await refreshNotifications();
  }

  // ================= المهام اليومية =================

  List<Task> tasksForDate(String key) {
    final list = _tasks.where((t) => t.dateKey == key).toList()
      ..sort((a, b) {
        final c = b.priority.index.compareTo(a.priority.index);
        return c != 0 ? c : a.title.compareTo(b.title);
      });
    return list;
  }

  int doneCountForDate(String key) =>
      _tasks.where((t) => t.dateKey == key && t.done).length;

  Future<void> addTask(String title, String note, Priority priority,
      String category, String dateKey) async {
    _tasks.add(Task(
      id: newId(),
      title: title.trim(),
      note: note.trim(),
      priority: priority,
      category: category,
      dateKey: dateKey,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> updateTask(
    Task t, {
    String? title,
    String? note,
    Priority? priority,
    String? category,
    String? dateKey,
  }) async {
    if (title != null) t.title = title.trim();
    if (note != null) t.note = note.trim();
    if (priority != null) t.priority = priority;
    if (category != null) t.category = category;
    if (dateKey != null) t.dateKey = dateKey;
    await _save();
    notifyListeners();
  }

  Future<void> toggleTask(Task t) async {
    t.done = !t.done;
    await _save();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
  }

  // ================= الروتين اليومي =================

  List<RoutineItem> get routineSorted {
    final list = [..._routine]
      ..sort((a, b) => (a.timeMinutes ?? 9999).compareTo(b.timeMinutes ?? 9999));
    return list;
  }

  int routineDoneCountFor(String dateKey) =>
      _routine.where((r) => r.isDoneOn(dateKey)).length;

  Future<void> addRoutineItem(String title, int? timeMinutes) async {
    _routine.add(RoutineItem(
      id: newId(),
      title: title.trim(),
      timeMinutes: timeMinutes,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> updateRoutineItem(RoutineItem r,
      {String? title, int? timeMinutes}) async {
    if (title != null) r.title = title.trim();
    r.timeMinutes = timeMinutes;
    await _save();
    notifyListeners();
  }

  Future<void> toggleRoutineOn(RoutineItem r, String dateKey) async {
    r.setDoneOn(dateKey, !r.isDoneOn(dateKey));
    await _save();
    notifyListeners();
  }

  Future<void> deleteRoutineItem(String id) async {
    _routine.removeWhere((r) => r.id == id);
    await _save();
    notifyListeners();
  }

  // ================= الإعدادات =================

  Future<void> setRemindersEnabled(bool v) async {
    _remindersEnabled = v;
    await _save();
    notifyListeners();
    await refreshNotifications();
  }

  Future<void> setLightMode(bool v) async {
    _lightMode = v;
    await _save();
    notifyListeners();
  }

  // ================= الإحصائيات =================

  List<DayStat> last7DaysStats(DateTime now) {
    final out = <DayStat>[];
    for (var i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final key = dateKey(d);
      final dayTasks = _tasks.where((t) => t.dateKey == key).toList();
      out.add(DayStat(
        weekdayShort(d.weekday),
        dayTasks.where((t) => t.done).length,
        dayTasks.length,
      ));
    }
    return out;
  }

  Map<String, int> categoryCountsLast7(DateTime now) {
    final counts = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      final key = dateKey(d);
      for (final t in _tasks) {
        if (t.dateKey == key && t.done) {
          counts[t.category] = (counts[t.category] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  /// ساعات المواعيد لكل يوم [1..7] — الفهرس 0 غير مستخدم
  List<double> hoursPerWeekday() {
    final h = List<double>.filled(8, 0);
    for (final a in _appointments) {
      if (!a.active) continue;
      h[a.weekday.clamp(1, 7)] += a.durationMinutes / 60.0;
    }
    return h;
  }

  int streakDays(DateTime now) {
    var streak = 0;
    for (var i = 0; i < 366; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      final key = dateKey(d);
      final dayTasks = _tasks.where((t) => t.dateKey == key).toList();
      if (dayTasks.isEmpty) continue; // يوم بدون مهام لا يكسر السلسلة
      if (dayTasks.every((t) => t.done)) {
        streak++;
      } else {
        if (i == 0) continue; // النهاردة لسه ما خلصتش
        break;
      }
    }
    return streak;
  }
}
