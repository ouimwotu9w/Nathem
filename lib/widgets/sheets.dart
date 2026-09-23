import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../utils/date_utils.dart';
import 'common.dart';

// ============ دوال الفتح ============

Future<void> showAppointmentSheet(
  BuildContext context, {
  WeekAppointment? existing,
  int initialWeekday = 1,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AppointmentSheet(
      existing: existing,
      initialWeekday: initialWeekday,
    ),
  );
}

Future<void> showTaskSheet(
  BuildContext context, {
  Task? existing,
  DateTime? initialDate,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => TaskSheet(existing: existing, initialDate: initialDate),
  );
}

Future<void> showRoutineSheet(BuildContext context, {RoutineItem? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => RoutineSheet(existing: existing),
  );
}

DateTime _parseKey(String key) {
  final p = key.split('-');
  if (p.length == 3) {
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y != null && m != null && d != null) return DateTime(y, m, d);
  }
  return DateTime.now();
}

// ============ زر الوقت ============

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ ورقة الموعد ============

class AppointmentSheet extends StatefulWidget {
  const AppointmentSheet({super.key, this.existing, this.initialWeekday = 1});

  final WeekAppointment? existing;
  final int initialWeekday;

  @override
  State<AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<AppointmentSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');
  late int _weekday = widget.existing?.weekday ?? widget.initialWeekday;
  late int _start = widget.existing?.startMinutes ?? 17 * 60;
  late int _end = widget.existing?.endMinutes ?? 19 * 60;
  late int _reminder = widget.existing?.reminderMinutesBefore ?? 30;
  String? _error;

  bool get _editing => widget.existing != null;

  /// هل الوقت/اليوم المختار حاليًا يتعارض مع موعد قائم؟
  bool _timeConflictsWithExisting(BuildContext context) {
    if (_end <= _start) return false;
    return context.read<AppData>().hasConflictWith(
          weekday: _weekday,
          start: _start,
          end: _end,
          ignoreId: widget.existing?.id,
        );
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _validate() {
    if (_title.text.trim().isEmpty) {
      _error = 'اكتب عنوان الموعد';
      return;
    }
    if (_end <= _start) {
      _error = 'وقت النهاية لازم يكون بعد وقت البداية';
      return;
    }
    _error = null;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final base = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base ~/ 60, minute: base % 60),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final m = picked.hour * 60 + picked.minute;
      if (isStart) {
        _start = m;
        if (_end <= _start) _end = (_start + 120).clamp(0, 1439);
      } else {
        _end = m;
      }
    });
  }

  Future<void> _save() async {
    setState(_validate);
    if (_error != null) return;
    final data = context.read<AppData>();
    if (_editing) {
      await data.updateAppointment(
        widget.existing!,
        title: _title.text,
        note: _note.text,
        weekday: _weekday,
        start: _start,
        end: _end,
        reminder: _reminder,
      );
    } else {
      await data.addAppointment(
          _title.text, _note.text, _weekday, _start, _end, _reminder);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final a = widget.existing!;
    final ok = await confirmAction(
      context,
      title: 'حذف الموعد',
      message:
          'هتحذف «${a.title}» من يوم ${weekdayName(a.weekday)} كل أسبوع.',
      confirmLabel: 'حذف',
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.read<AppData>().deleteAppointment(a.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _editing ? 'تعديل الموعد' : 'موعد جديد',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (_editing)
                  IconButton(
                    tooltip: 'حذف',
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'عنوان الموعد',
                hintText: 'مثال: زيارة عمي أحمد',
              ),
              onChanged: (_) => setState(_validate),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
              ),
            ),
            const SizedBox(height: 16),
            Text('اليوم',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kWeekOrder
                  .map(
                    (wd) => ChoiceChip(
                      label: Text(weekdayName(wd)),
                      selected: _weekday == wd,
                      onSelected: (_) => setState(() => _weekday = wd),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('الوقت',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'من',
                    value: formatMinutes(_start),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(
                    label: 'إلى',
                    value: formatMinutes(_end),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            if (_timeConflictsWithExisting(context)) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withAlpha(90),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.error.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: scheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'في موعد آخر متعارض مع الوقت ده في نفس اليوم — عدّل الوقت أو هيبقوا فوق بعض',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _reminder,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'التذكير'),
              items: kReminderChoices
                  .map(
                    (v) => DropdownMenuItem<int>(
                      value: v,
                      child: Text(reminderLabel(v)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _reminder = v ?? 0),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(fontSize: 13, color: scheme.error),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(_editing ? 'حفظ التعديل' : 'إضافة الموعد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ ورقة المهمة ============

class TaskSheet extends StatefulWidget {
  const TaskSheet({super.key, this.existing, this.initialDate});

  final Task? existing;
  final DateTime? initialDate;

  @override
  State<TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<TaskSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');
  late Priority _priority = widget.existing?.priority ?? Priority.low;
  late String _category = widget.existing?.category ?? 'personal';
  late DateTime _date =
      widget.existing != null ? _parseKey(widget.existing!.dateKey) : (widget.initialDate ?? DateTime.now());
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _validate() {
    _error = _title.text.trim().isEmpty ? 'اكتب عنوان المهمة' : null;
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
  }

  Future<void> _save() async {
    setState(_validate);
    if (_error != null) return;
    final data = context.read<AppData>();
    if (_editing) {
      await data.updateTask(
        widget.existing!,
        title: _title.text,
        note: _note.text,
        priority: _priority,
        category: _category,
        dateKey: dateKey(_date),
      );
    } else {
      await data.addTask(
          _title.text, _note.text, _priority, _category, dateKey(_date));
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'حذف المهمة',
      message: 'هتحذف «${widget.existing!.title}» نهائيًا.',
      confirmLabel: 'حذف',
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.read<AppData>().deleteTask(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _editing ? 'تعديل المهمة' : 'مهمة جديدة',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (_editing)
                  IconButton(
                    tooltip: 'حذف',
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'عنوان المهمة',
                hintText: 'مثال: تسليم تقرير الشغل',
              ),
              onChanged: (_) => setState(_validate),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
              ),
            ),
            const SizedBox(height: 16),
            Text('الأولوية',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Priority.values
                  .map(
                    (p) => ChoiceChip(
                      label: Text(p.label),
                      selected: _priority == p,
                      onSelected: (_) => setState(() => _priority = p),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('التصنيف',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategories
                  .map(
                    (c) => ChoiceChip(
                      avatar: Icon(c.icon,
                          size: 16, color: _category == c.key ? null : c.color),
                      label: Text(c.label),
                      selected: _category == c.key,
                      onSelected: (_) => setState(() => _category = c.key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('التاريخ:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(formatDateShort(_date)),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(fontSize: 13, color: scheme.error),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(_editing ? 'حفظ التعديل' : 'إضافة المهمة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ ورقة الروتين ============

class RoutineSheet extends StatefulWidget {
  const RoutineSheet({super.key, this.existing});

  final RoutineItem? existing;

  @override
  State<RoutineSheet> createState() => _RoutineSheetState();
}

class _RoutineSheetState extends State<RoutineSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late bool _hasTime = widget.existing?.timeMinutes != null;
  late int _time = widget.existing?.timeMinutes ?? 8 * 60;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _validate() {
    _error = _title.text.trim().isEmpty ? 'اكتب عنوان البند' : null;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _time ~/ 60, minute: _time % 60),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked.hour * 60 + picked.minute);
  }

  Future<void> _save() async {
    setState(_validate);
    if (_error != null) return;
    final data = context.read<AppData>();
    if (_editing) {
      await data.updateRoutineItem(
        widget.existing!,
        title: _title.text,
        timeMinutes: _hasTime ? _time : null,
      );
    } else {
      await data.addRoutineItem(_title.text, _hasTime ? _time : null);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'حذف البند',
      message: 'هتحذف «${widget.existing!.title}» من الروتين اليومي.',
      confirmLabel: 'حذف',
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.read<AppData>().deleteRoutineItem(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _editing ? 'تعديل البند' : 'بند روتين جديد',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (_editing)
                  IconButton(
                    tooltip: 'حذف',
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'عنوان البند',
                hintText: 'مثال: قراءة ورد يومي',
              ),
              onChanged: (_) => setState(_validate),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: _hasTime,
              onChanged: (v) => setState(() => _hasTime = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('موعد ثابت يوميًا',
                  style: TextStyle(fontSize: 14.5)),
              subtitle: const Text('بيظهر في نفس الترتيب كل يوم',
                  style: TextStyle(fontSize: 12)),
            ),
            if (_hasTime)
              Row(
                children: [
                  Text('الوقت:',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(width: 10),
                  _TimeButton(
                    label: 'يوميًا الساعة',
                    value: formatMinutes(_time),
                    onTap: _pickTime,
                  ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(fontSize: 13, color: scheme.error),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(_editing ? 'حفظ التعديل' : 'إضافة البند'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
