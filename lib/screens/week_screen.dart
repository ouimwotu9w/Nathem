import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

/// تبويب الأسبوع — قلب التطبيق:
/// اختر يومًا من أيام الأسبوع وأضف مواعيده المتكررة (من — إلى)
/// مع التذكير، وتكرار كل أسبوع تلقائيًا، وإمكانية التعديل في أي وقت.
class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late int _selected = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final scheme = Theme.of(context).colorScheme;
    final apps = data.appointmentsForWeekday(_selected);
    final totalMinutes =
        apps.fold<int>(0, (s, a) => s + a.durationMinutes);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showAppointmentSheet(context, initialWeekday: _selected),
        icon: const Icon(Icons.add),
        label: const Text('موعد جديد'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الأسبوع',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    totalMinutes == 0
                        ? 'حدد مواعيد أيامك'
                        : 'إجمالي ${formatDurationShort(totalMinutes)} أسبوعيًا',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: kWeekOrder.map((wd) {
                  final sel = wd == _selected;
                  final count = data.countForWeekday(wd);
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = wd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                sel ? scheme.primary : scheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weekdayName(wd),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 1),
                                decoration: BoxDecoration(
                                  color: scheme.tertiary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Divider(indent: 16, endIndent: 16, color: scheme.outlineVariant),
            Expanded(
              child: apps.isEmpty
                  ? EmptyState(
                      icon: Icons.event_available,
                      title: 'مافيش مواعيد يوم ${weekdayName(_selected)}',
                      subtitle:
                          'اضغط زر «موعد جديد» وحدد الوقت من — إلى، والموعد يتكرر كل أسبوع تلقائيًا وتقدر تعدّله في أي وقت.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                      children: [
                        ...apps.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppointmentTile(
                              appointment: a,
                              onTap: () =>
                                  showAppointmentSheet(context, existing: a),
                              onCopy: () => _copyToDay(a),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'المواعيد بتتكرر كل أسبوع في نفس اليوم. عدّل الوقت أو التذكير بالضغط على أي موعد.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant.withAlpha(170),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToDay(WeekAppointment a) async {
    final target = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('انسخ الموعد ليوم:'),
        children: kWeekOrder
            .where((w) => w != a.weekday)
            .map(
              (w) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, w),
                child: Text(weekdayName(w)),
              ),
            )
            .toList(),
      ),
    );
    if (target == null || !mounted) return;
    await context.read<AppData>().addAppointment(
          a.title,
          a.note,
          target,
          a.startMinutes,
          a.endMinutes,
          a.reminderMinutesBefore,
        );
    if (!mounted) return;
    showMsg(context, 'اتنسخ ليوم ${weekdayName(target)}');
  }
}
