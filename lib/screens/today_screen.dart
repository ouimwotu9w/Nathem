import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // تحديث بطاقة «موعدك القادم» كل نصف دقيقة
  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(() {});
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final key = dateKey(now);
    final tasks = data.tasksForDate(key);
    final done = tasks.where((t) => t.done).length;
    final apps = data.appointmentsForWeekday(now.weekday);
    final routine = data.routineSorted;
    final routineDone = data.routineDoneCountFor(key);
    final next = data.nextAppointmentToday(now);
    final totalItems = tasks.length + routine.length;
    final doneItems = done + routineDone;
    final ratio = totalItems == 0 ? 0.0 : doneItems / totalItems;
    final streak = data.streakDays(now);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskSheet(context, initialDate: now),
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDateLong(now),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'يومك تحت السيطرة',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withAlpha(110),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 17,
                        color: scheme.tertiary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        streak > 0 ? 'سلسلة $streak يوم' : 'ابدأ سلسلتك',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ProgressRing(
                      value: ratio,
                      label: '${(ratio * 100).round()}%',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أنجزت $doneItems من $totalItems',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مهام: $done من ${tasks.length} • روتين: $routineDone من ${routine.length}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مواعيد النهاردة: ${apps.length}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 14),
              _NextAppointmentCard(appointment: next, now: now),
            ],
            const SectionHeader(title: 'مواعيد اليوم'),
            if (apps.isEmpty)
              const MiniEmpty(
                title: 'مافيش مواعيد النهاردة',
                subtitle: 'من تاب «الأسبوع» تقدر تحدد مواعيد كل يوم تتكرر أسبوعيًا',
              )
            else
              ...apps.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppointmentTile(
                    appointment: a,
                    onTap: () => showAppointmentSheet(context, existing: a),
                  ),
                ),
              ),
            SectionHeader(
              title: 'الروتين اليومي',
              trailing: IconButton(
                tooltip: 'إضافة بند روتين',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => showRoutineSheet(context),
              ),
            ),
            if (routine.isEmpty)
              const MiniEmpty(
                title: 'أضف بنود روتينك الثابت',
                subtitle: 'مثال: قراءة ورد، رياضة، مراجعة دروس',
              )
            else
              ...routine.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      onTap: () => data.toggleRoutineOn(r, key),
                      leading: Icon(
                        r.isDoneOn(key)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: r.isDoneOn(key)
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      title: Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: r.isDoneOn(key)
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          decoration: r.isDoneOn(key)
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: r.timeMinutes == null
                          ? null
                          : Text(
                              formatMinutes(r.timeMinutes!),
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                      trailing: IconButton(
                        tooltip: 'تعديل',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => showRoutineSheet(context, existing: r),
                      ),
                    ),
                  ),
                ),
              ),
            SectionHeader(
              title: 'مهام اليوم',
              trailing: IconButton(
                tooltip: 'إضافة مهمة',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => showTaskSheet(context, initialDate: now),
              ),
            ),
            if (tasks.isEmpty)
              const MiniEmpty(
                title: 'مافيش مهام النهاردة',
                subtitle: 'اضغط زر «مهمة جديدة» بالأسفل',
              )
            else
              ...tasks.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskTile(task: t),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============ بطاقة الموعد القادم ============

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.appointment, required this.now});

  final WeekAppointment appointment;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final diff = a.startMinutes - minutesNow(now);
    final starting = diff <= 0;
    final when = starting
        ? 'جاري الآن — ينتهي ${formatDurationShort((a.endMinutes - minutesNow(now)).clamp(1, 24 * 60))}'
        : 'بعد ${formatDurationShort(diff)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF303F9F)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE3C26B).withAlpha(50),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.schedule,
              color: Color(0xFFE3C26B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'موعدك القادم',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB9C2E8),
                  ),
                ),
                Text(
                  a.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE9ECFA),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatRange(a.startMinutes, a.endMinutes)} — $when',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB9C2E8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ بلاطة مهمة ============

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = context.read<AppData>();
    final cat = categoryByKey(task.category);
    return Card(
      child: ListTile(
        onTap: () => data.toggleTask(task),
        leading: Icon(
          task.done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.done ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: task.done ? scheme.onSurfaceVariant : scheme.onSurface,
            decoration:
                task.done ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: task.note.isEmpty
            ? null
            : Text(
                task.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, size: 15, color: cat.color),
            const SizedBox(width: 6),
            Icon(Icons.flag, size: 15, color: task.priority.color),
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'تعديل',
              icon: const Icon(Icons.edit_outlined, size: 17),
              onPressed: () => showTaskSheet(context, existing: task),
            ),
          ],
        ),
      ),
    );
  }
}
