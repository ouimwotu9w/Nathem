import 'package:flutter/material.dart';

// ============ أدوات تحويل آمنة من/إلى JSON ============

int asInt(dynamic v, int def) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

String asString(dynamic v, String def) => v is String ? v : def;

bool asBool(dynamic v, bool def) => v is bool ? v : def;

String newId() {
  final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final r = (DateTime.now().microsecond % 900 + 100).toString();
  return '$t$r';
}

// ============ الأولويات ============

enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.low => 'عادية',
        Priority.medium => 'متوسطة',
        Priority.high => 'عالية',
      };

  Color get color => switch (this) {
        Priority.low => const Color(0xFF8FA3C7),
        Priority.medium => const Color(0xFFE3C26B),
        Priority.high => const Color(0xFFEF8A8A),
      };
}

Priority priorityFromIndex(int i) =>
    Priority.values[asInt(i, 0).clamp(0, Priority.values.length - 1)];

// ============ التصنيفات ============

class CategoryDef {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const CategoryDef(this.key, this.label, this.icon, this.color);
}

const List<CategoryDef> kCategories = [
  CategoryDef('work', 'عمل', Icons.work_outline, Color(0xFF9FA8DA)),
  CategoryDef('home', 'البيت', Icons.home_outlined, Color(0xFF80CBC4)),
  CategoryDef('study', 'دراسة', Icons.school_outlined, Color(0xFFE3C26B)),
  CategoryDef('personal', 'شخصي', Icons.person_outline, Color(0xFFCE93D8)),
];

CategoryDef categoryByKey(String key) => kCategories.firstWhere(
      (c) => c.key == key,
      orElse: () => kCategories.first,
    );

// ============ المهمة اليومية ============

class Task {
  Task({
    required this.id,
    required this.title,
    this.note = '',
    this.priority = Priority.low,
    this.category = 'personal',
    required this.dateKey,
    this.done = false,
  });

  final String id;
  String title;
  String note;
  Priority priority;
  String category;
  String dateKey; // yyyy-MM-dd
  bool done;

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: asString(j['id'], newId()),
        title: asString(j['title'], 'مهمة'),
        note: asString(j['note'], ''),
        priority: priorityFromIndex(asInt(j['priority'], 0)),
        category: asString(j['category'], 'personal'),
        dateKey: asString(j['dateKey'], ''),
        done: asBool(j['done'], false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'priority': priority.index,
        'category': category,
        'dateKey': dateKey,
        'done': done,
      };
}

// ============ موعد الأسبوع المتكرر ============

class WeekAppointment {
  WeekAppointment({
    required this.id,
    required this.title,
    this.note = '',
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.reminderMinutesBefore = 0,
    this.active = true,
  });

  final String id;
  String title;
  String note;
  int weekday; // DateTime.monday=1 .. sunday=7
  int startMinutes; // دقائق من منتصف الليل
  int endMinutes;
  int reminderMinutesBefore; // 0 = بدون تذكير
  bool active;

  int get durationMinutes => (endMinutes - startMinutes).clamp(1, 24 * 60);

  int get notifyId => id.hashCode & 0x7fffffff;

  factory WeekAppointment.fromJson(Map<String, dynamic> j) => WeekAppointment(
        id: asString(j['id'], newId()),
        title: asString(j['title'], 'موعد'),
        note: asString(j['note'], ''),
        weekday: asInt(j['weekday'], 1).clamp(1, 7),
        startMinutes: asInt(j['startMinutes'], 17 * 60).clamp(0, 1439),
        endMinutes: asInt(j['endMinutes'], 19 * 60).clamp(1, 1440),
        reminderMinutesBefore: asInt(j['reminderMinutesBefore'], 0),
        active: asBool(j['active'], true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'weekday': weekday,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'reminderMinutesBefore': reminderMinutesBefore,
        'active': active,
      };
}

// ============ بند الروتين اليومي ============

class RoutineItem {
  RoutineItem({
    required this.id,
    required this.title,
    this.timeMinutes,
    Map<String, bool>? completions,
  }) : completions = completions ?? {};

  final String id;
  String title;
  int? timeMinutes; // null = بدون وقت محدد
  final Map<String, bool> completions; // dateKey -> تم

  bool isDoneOn(String dateKey) => completions[dateKey] ?? false;

  void setDoneOn(String dateKey, bool v) {
    if (v) {
      completions[dateKey] = true;
    } else {
      completions.remove(dateKey);
    }
  }

  factory RoutineItem.fromJson(Map<String, dynamic> j) {
    final raw = j['completions'];
    final map = <String, bool>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is bool) map[k] = v;
      });
    }
    final t = j['timeMinutes'];
    return RoutineItem(
      id: asString(j['id'], newId()),
      title: asString(j['title'], 'بند روتين'),
      timeMinutes: t == null ? null : asInt(t, 0),
      completions: map,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'timeMinutes': timeMinutes,
        'completions': completions,
      };
}
