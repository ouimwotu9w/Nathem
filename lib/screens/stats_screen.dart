import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final dayStats = data.last7DaysStats(now);
    final catCounts = data.categoryCountsLast7(now);
    final streak = data.streakDays(now);
    final hours = data.hoursPerWeekday();
    final totalDone7 = dayStats.fold<int>(0, (s, d) => s + d.done);
    final totalTasks7 = dayStats.fold<int>(0, (s, d) => s + d.total);
    final totalHours =
        hours.fold<double>(0, (s, h) => s + h);

    final slices = <DonutSlice>[];
    for (final c in kCategories) {
      final v = catCounts[c.key] ?? 0;
      if (v > 0) {
        slices.add(DonutSlice(color: c.color, value: v.toDouble(), label: c.label));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          children: [
            Text(
              'الإحصائيات',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            Text(
              'نشاطك في آخر 7 أيام',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    iconColor: scheme.tertiary,
                    title: 'سلسلة الالتزام',
                    value: streak > 0 ? '$streak يوم' : '—',
                    sub: streak > 0
                        ? 'كمّل كده، ما تكسرهاش!'
                        : 'أنجز كل مهام يوم لتبدأ السلسلة',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.task_alt,
                    iconColor: scheme.primary,
                    title: 'مهام منجزة',
                    value: '$totalDone7',
                    sub: 'من $totalTasks7 مهمة خلال أسبوع',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'إنجاز المهام — آخر 7 أيام',
                      subtitle: 'اللون الأساسي = يوم مكتمل بالكامل',
                    ),
                    WeekBars(days: dayStats),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'توزيع مهامك المنجزة حسب التصنيف',
                    ),
                    if (slices.isEmpty)
                      const MiniEmpty(
                        title: 'لسه مافيش مهام منجزة هذا الأسبوع',
                        subtitle: 'علّم على مهامك من تاب اليوم وهتظهر هنا',
                      )
                    else
                      Row(
                        children: [
                          DonutChart(slices: slices),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: slices
                                  .map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: s.color,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              s.label,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: scheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${s.value.round()}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'ساعات مواعيدك في الأسبوع',
                      subtitle: totalHours <= 0
                          ? 'أضف مواعيد من تاب الأسبوع'
                          : 'إجمالي ${formatDurationShort((totalHours * 60).round())} موزعة على الأسبوع',
                    ),
                    if (totalHours > 0) HoursBars(hours: hours),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
