import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

/// تبويب المهام (التودو ليست) لوحدها:
/// شريط أيام سريع + منتقي تاريخ + فلاتر (الكل / اللي فاضل / المنجزة)
/// وبلاطات مهام مرتبة حسب الأولوية.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime _date = DateTime.now();
  String _filter = 'all'; // all | open | done

  final ScrollController _stripCtrl = ScrollController();
  static const double _itemExtent = 64;
  static const double _stripPadding = 16;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerStrip());
  }

  @override
  void dispose() {
    _stripCtrl.dispose();
    super.dispose();
  }

  /// يوسّط شريط الأيام على اليوم المختار
  void _centerStrip() {
    if (!_stripCtrl.hasClients) return;
    final w = _stripCtrl.position.viewportDimension;
    final d0 = DateTime(_date.year, _date.month, _date.day);
    final anchor = _anchorDate();
    final start = anchor.subtract(const Duration(days: 13));
    final idx = d0.difference(start).inDays;
    final target =
        _stripPadding + idx * _itemExtent + _itemExtent / 2 - w / 2;
    _stripCtrl.jumpTo(target.clamp(0.0, _stripCtrl.position.maxScrollExtent));
  }

  /// قاعدة شريط الأيام: النهاردة، أو التاريخ المختار لو بعيد عن النهاردة
  DateTime _anchorDate() {
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    final d0 = DateTime(_date.year, _date.month, _date.day);
    return d0.difference(today0).inDays.abs() > 13 ? d0 : today0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerStrip());
  }

  void _goToday() {
    setState(() => _date = DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerStrip());
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday = dateKey(_date) == dateKey(now);
    final key = dateKey(_date);
    final dayLabel = isToday ? 'النهاردة' : 'يوم ${formatDateShort(_date)}';

    final tasks = data.tasksForDate(key);
    final done = tasks.where((t) => t.done).length;
    final filtered = switch (_filter) {
      'open' => tasks.where((t) => !t.done).toList(),
      'done' => tasks.where((t) => t.done).toList(),
      _ => tasks,
    };
    final ratio = tasks.isEmpty ? 0.0 : done / tasks.length;

    // شريط الأيام: 27 يوم حول القاعدة
    final anchor = _anchorDate();
    final start = anchor.subtract(const Duration(days: 13));
    final days =
        List<DateTime>.generate(27, (i) => start.add(Duration(days: i)));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskSheet(context, initialDate: _date),
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Text(
                    'المهام',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (!isToday)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.today,
                          size: 16,
                          color: scheme.primary,
                        ),
                        label: const Text(
                          'النهاردة',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: _goToday,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month, size: 17),
                    label: Text(
                      formatDateShort(_date),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: ListView.builder(
                controller: _stripCtrl,
                scrollDirection: Axis.horizontal,
                itemExtent: _itemExtent,
                padding:
                    const EdgeInsets.symmetric(horizontal: _stripPadding),
                itemCount: days.length,
                itemBuilder: (context, i) {
                  final d = days[i];
                  final sel = dateKey(d) == key;
                  final open = data
                      .tasksForDate(dateKey(d))
                      .where((t) => !t.done)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _date = d),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sel
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  weekdayShort(d.weekday),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: sel
                                        ? scheme.onPrimaryContainer
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                if (open > 0) ...[
                                  const SizedBox(width: 3),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sel
                                          ? scheme.primary
                                          : scheme.tertiary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: sel
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 19,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tasks.isEmpty
                                  ? 'مافيش مهام $dayLabel'
                                  : 'أنجزت $done من ${tasks.length} مهمة $dayLabel',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '${(ratio * 100).round()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 7,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('الكل')),
                    ButtonSegment(value: 'open', label: Text('اللي فاضل')),
                    ButtonSegment(value: 'done', label: Text('المنجزة')),
                  ],
                  selected: {_filter},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _filter = s.first),
                ),
              ),
            ),
            Divider(
              indent: 16,
              endIndent: 16,
              height: 22,
              color: scheme.outlineVariant,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? tasks.isEmpty
                      ? EmptyState(
                          icon: Icons.checklist_rounded,
                          title: 'مافيش مهام $dayLabel',
                          subtitle:
                              'اضغط زر «مهمة جديدة» وحدد اليوم والأولوية والتصنيف — والمهام بترتب حسب الأولوية تلقائيًا.',
                        )
                      : const MiniEmpty(
                          title: 'مافيش مهام في الفلتر المختار',
                          subtitle: 'جرّب تغيّر الفلتر من فوق',
                        )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      children: [
                        ...filtered.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TaskTile(task: t),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'المهام بترتب حسب الأولوية — اضغط على المهمة تعلّم عليها منجزة، ومن زر القلم تعدّلها أو تحذفها.',
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
}

// ============ بلاطة مهمة محسّنة ============

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = context.read<AppData>();
    final cat = categoryByKey(task.category);

    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => data.toggleTask(task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // مربع الاختيار الدائري
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.done ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: task.done ? scheme.primary : scheme.outline,
                    width: 2,
                  ),
                ),
                child: task.done
                    ? Icon(Icons.check, size: 17, color: scheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: task.done
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (task.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _Pill(
                          icon: cat.icon,
                          label: cat.label,
                          color: cat.color,
                        ),
                        const SizedBox(width: 6),
                        _Pill(
                          icon: Icons.flag,
                          label: task.priority.label,
                          color: task.priority.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تعديل',
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () => showTaskSheet(context, existing: task),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ شارة صغيرة (تصنيف / أولوية) ============

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
