import 'package:intl/intl.dart';

// أسماء الأيام (DateTime.monday=1 .. sunday=7)
const List<String> kWeekdayNames = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const List<String> kWeekdayShort = [
  'إثنين',
  'ثلاثاء',
  'أربعاء',
  'خميس',
  'جمعة',
  'سبت',
  'أحد',
];

// ترتيب عرض الأسبوع يبدأ بالسبت (الأسبوع المصري)
const List<int> kWeekOrder = [6, 7, 1, 2, 3, 4, 5];

String weekdayName(int weekday) =>
    kWeekdayNames[(weekday - 1).clamp(0, 6)];

String weekdayShort(int weekday) =>
    kWeekdayShort[(weekday - 1).clamp(0, 6)];

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String formatDateLong(DateTime d) =>
    DateFormat('EEEE، d MMMM y', 'ar').format(d);

String formatDateShort(DateTime d) => DateFormat('d/M/y', 'ar').format(d);

int minutesNow(DateTime d) => d.hour * 60 + d.minute;

String formatMinutes(int m) {
  final h = (m ~/ 60).clamp(0, 23);
  final mm = m % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final suffix = h < 12 ? 'ص' : 'م';
  final two = mm.toString().padLeft(2, '0');
  return '$h12:$two $suffix';
}

String formatRange(int start, int end) =>
    '${formatMinutes(start)} — ${formatMinutes(end)}';

String formatDurationShort(int minutes) {
  if (minutes < 60) return '$minutes دقيقة';
  final h = minutes ~/ 60;
  final r = minutes % 60;
  if (r == 0) {
    if (h == 1) return 'ساعة';
    if (h == 2) return 'ساعتان';
    return '$h ساعات';
  }
  if (h == 1) return 'ساعة و$r دقيقة';
  return '$h ساعات و$r دقيقة';
}

const Map<int, String> kReminderLabels = {
  0: 'بدون تذكير',
  15: 'قبلها بـ 15 دقيقة',
  30: 'قبلها بنصف ساعة',
  60: 'قبلها بساعة',
  120: 'قبلها بساعتين',
  1440: 'قبلها بيوم',
};

const Map<int, String> kReminderShort = {
  0: 'بدون',
  15: '15 دقيقة',
  30: 'نصف ساعة',
  60: 'ساعة',
  120: 'ساعتين',
  1440: 'يوم',
};

const List<int> kReminderChoices = [0, 15, 30, 60, 120, 1440];

String reminderShort(int v) => kReminderShort[v] ?? '$v دقيقة';

String reminderLabel(int v) => kReminderLabels[v] ?? 'قبلها بـ $v دقيقة';
