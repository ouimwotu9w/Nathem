import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

/// تبويب اليوم: الموعد القادم + مواعيد النهاردة + الروتين
/// (المهام ليها تبويب مستقل — [onOpenTasks] ينقل المستخدم له)
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.onOpenTasks});

  final VoidCallback? onOpenTasks;

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
    final conflicts = data.conflictIdsForWeekday(now.weekday);
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
              _NextAppointmentCard(
                appointment: next,
                now: now,
                conflict: conflicts.contains(next.id),
                onEdit: () => showAppointmentSheet(context, existing: next),
              ),
            ],
            const SizedBox(height: 6),
            const SectionHeader(title: 'مواعيد اليوم'),
            if (apps.isEmpty)
              const MiniEmpty(
                title: 'مافيش مواعيد النهاردة',
                subtitle: 'من تاب «الأسبوع» تقدر تحدد مواعيد كل يوم تتكرر أسبوعيًا',
              )
            else ...[
              if (conflicts.isNotEmpty) ...[
                _ConflictBanner(count: conflicts.length, dayName: 'النهاردة'),
                const SizedBox(height: 10),
              ],
              ...apps.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppointmentTile(
                    appointment: a,
                    conflict: conflicts.contains(a.id),
                    onTap: () => showAppointmentSheet(context, existing: a),
                  ),
                ),
              ),
            ],
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
            const SizedBox(height: 6),
            // ملخص المهام — ينقل لتبويب المهام المستقل
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onOpenTasks,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withAlpha(120),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.checklist_rounded,
                          size: 21,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مهام النهاردة: $done من ${tasks.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              'التودو ليست كاملة في تبويب المهام',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_left,
                        size: 22,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ لافتة تحذير التعارض ============

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.count, required this.dayName});

  final int count;
  final String dayName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.error.withAlpha(130)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 2
                  ? 'فيه موعدين متعارضين $dayName — اضغط على أي واحد فيهم وعدّل وقته'
                  : 'فيه $count مواعيد متعارضة $dayName — عدّل أوقاتها',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ بطاقة الموعد القادم (تصميم محسّن) ============

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({
    required this.appointment,
    required this.now,
    this.conflict = false,
    this.onEdit,
  });

  final WeekAppointment appointment;
  final DateTime now;
  final bool conflict;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final mins = minutesNow(now);
    final ongoing = mins >= a.startMinutes && mins < a.endMinutes;
    final diff = a.startMinutes - mins;
    final when = ongoing
        ? 'جاري الآن'
        : diff > 0
            ? 'بعد ${formatDurationShort(diff)}'
            : 'انتهى';
    final progress = ongoing
        ? ((mins - a.startMinutes) / a.durationMinutes).clamp(0.0, 1.0)
        : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF303F9F)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        boxShadow: [
          BoxShadow(
            color: conflict
                ? const Color(0xFFEF5350).withAlpha(110)
                : const Color(0xFF1A237E).withAlpha(90),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: conflict
              ? const Color(0xFFEF5350).withAlpha(220)
              : const Color(0xFFE3C26B).withAlpha(60),
          width: conflict ? 1.6 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            child: Stack(
              children: [
                // زخارف دائرية خفيفة
                PositionedDirectional(
                  top: -28,
                  end: -20,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE3C26B).withAlpha(22),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: -34,
                  start: -18,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3C26B).withAlpha(45),
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
                                Text(
                                  ongoing ? 'موعد جارٍ الآن' : 'موعدك القادم',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: Color(0xFFE3C26B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  a.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE9ECFA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // شارة العد التنازلي
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: ongoing
                                  ? const Color(0xFF4CAF50).withAlpha(60)
                                  : const Color(0xFFE3C26B).withAlpha(38),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              when,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: ongoing
                                    ? const Color(0xFFC8F0CC)
                                    : const Color(0xFFE3C26B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.timelapse,
                            size: 14,
                            color: Color(0xFFB9C2E8),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              formatRange(a.startMinutes, a.endMinutes),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFFB9C2E8),
                              ),
                            ),
                          ),
                          if (a.reminderMinutesBefore > 0) ...[
                            const Icon(
                              Icons.alarm,
                              size: 14,
                              color: Color(0xFFB9C2E8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'تذكير قبلها بـ ${reminderShort(a.reminderMinutesBefore)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFB9C2E8),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (ongoing && progress != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white.withAlpha(40),
                            color: const Color(0xFFE3C26B),
                          ),
                        ),
                      ],
                      if (conflict) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 15,
                              color: Color(0xFFFF8A80),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'الموعد ده متعارض مع موعد آخر في نفس الوقت — اضغط وعدّل وقته',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                  color: const Color(0xFFFF8A80).withAlpha(230),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
