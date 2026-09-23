import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_data.dart';
import '../services/notifications.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _importCtrl = TextEditingController();

  @override
  void dispose() {
    _importCtrl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final sm = ScaffoldMessenger.of(context);
    final json = context.read<AppData>().exportJson();
    try {
      await Share.share(json, subject: 'نسخة احتياطية — ناظِم');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: json));
      sm.showSnackBar(const SnackBar(
        content: Text('تعذر المشاركة — تم نسخ البيانات للحافظة'),
      ));
    }
  }

  Future<void> _copyData() async {
    final sm = ScaffoldMessenger.of(context);
    await Clipboard.setData(
        ClipboardData(text: context.read<AppData>().exportJson()));
    sm.showSnackBar(
        const SnackBar(content: Text('تم نسخ كل بياناتك إلى الحافظة')));
  }

  Future<void> _importDialog() async {
    final sm = ScaffoldMessenger.of(context);
    final data = context.read<AppData>();
    _importCtrl.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استيراد نسخة احتياطية'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: TextField(
            controller: _importCtrl,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'الصق هنا محتوى ملف النسخة الاحتياطية (JSON)',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('استيراد'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final text = _importCtrl.text.trim();
    if (text.isEmpty) return;
    final success = await data.importJson(text);
    sm.showSnackBar(SnackBar(
      content: Text(success
          ? 'تم الاستيراد بنجاح — أهلًا ببياناتك'
          : 'النص غير صالح، راجع النسخة وجرّب تاني'),
    ));
  }

  /// تجربة الإشعارات: طلب الصلاحيات ثم جدولة إشعار بعد 10 ثواني
  /// وعرض تقرير بحالة الصلاحيات على الجهاز
  Future<void> _testNotification() async {
    final sm = ScaffoldMessenger.of(context);
    await NotificationService.instance.requestPermissions();
    final res =
        await NotificationService.instance.scheduleTestNotification(seconds: 10);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تجربة الإشعارات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(
              ok: res.notificationsEnabled,
              text: res.notificationsEnabled
                  ? 'صلاحية الإشعارات: مفعّلة'
                  : 'صلاحية الإشعارات: متوقفة — فعّلها من إعدادات النظام (التطبيقات ← ناظِم ← الإشعارات)',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              ok: res.exactSchedulingWorked != false,
              neutral: res.exactSchedulingWorked == null,
              text: res.exactSchedulingWorked == null
                  ? 'التنبيهات الدقيقة: تعذّر فحصها — الإشعار هيوصل بس ممكن يتأخر شوية'
                  : res.exactSchedulingWorked!
                      ? 'التنبيهات الدقيقة: شغالة — الإشعارات هتوصل في وقتها بالظبط'
                      : 'التنبيهات الدقيقة: مش مسموحة — الإشعارات هتوصل بس ممكن تتأخر. اسمح بـ «المنبهات والتنبيهات» لإظهار ناظِم من إعدادات النظام',
            ),
            const Divider(height: 20),
            Text(
              res.scheduled
                  ? 'تم جدولة إشعار تجريبي بعد 10 ثواني — سيب التطبيق في الخلفية (أو اقفله) لحد ما يوصلك، عشان نتأكد إن التذكيرات شغالة على جهازك.'
                  : 'تعذّرت جدولة الإشعار على الجهاز ده. جرّب: السماح بالإشعارات من النظام، وتفعيل «المنبهات والتنبيهات» للتطبيق، ثم حاول تاني.',
              style: const TextStyle(fontSize: 13, height: 1.7),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
    if (res.notificationsEnabled || !res.scheduled) {
      sm.showSnackBar(const SnackBar(
        content: Text('لو الإشعار مش وصل خلال دقيقة، راجع إعدادات النظام من الزر اللي فوقه'),
      ));
    }
  }

  Future<void> _clearAll() async {
    final sm = ScaffoldMessenger.of(context);
    final data = context.read<AppData>();
    final ok = await confirmAction(
      context,
      title: 'مسح كل البيانات؟',
      message:
          'هتمسح كل المواعيد والمهام وبنود الروتين نهائيًا. الأفضل تصدّر نسخة احتياطية الأول.',
      confirmLabel: 'مسح الكل',
      danger: true,
    );
    if (!ok) return;
    await data.clearAll();
    sm.showSnackBar(const SnackBar(content: Text('تم مسح كل البيانات')));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          children: [
            Text(
              'الإعدادات',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'المظهر'),
                  SwitchListTile(
                    value: !data.lightMode,
                    onChanged: (v) => data.setLightMode(!v),
                    title: const Text('الوضع الداكن الملكي',
                        style: TextStyle(fontSize: 14.5)),
                    subtitle: Text(
                      'كحلي وفضي أنيق — أو استخدم الوضع الفاتح',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'التذكيرات'),
                  SwitchListTile(
                    value: data.remindersEnabled,
                    onChanged: (v) => data.setRemindersEnabled(v),
                    title: const Text('تذكيرات المواعيد',
                        style: TextStyle(fontSize: 14.5)),
                    subtitle: Text(
                      'إشعار قبل كل موعد بالمدة اللي تحددها له',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('التحقق من الصلاحيات',
                        style: TextStyle(fontSize: 14.5)),
                    subtitle: Text(
                      'السماح بالإشعارات والتنبيهات الدقيقة (مهم على أندرويد 13+)',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () async {
                      final sm = ScaffoldMessenger.of(context);
                      await NotificationService.instance.requestPermissions();
                      sm.showSnackBar(const SnackBar(
                        content: Text('لو ظهرت نافذة السماح، وافق عليها'),
                      ));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: const Text('جرّب إشعار تجريبي',
                        style: TextStyle(fontSize: 14.5)),
                    subtitle: Text(
                      'يوصلك إشعار بعد 10 ثواني عشان تتأكد إن التذكيرات شغالة',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: _testNotification,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('كيف تعمل التذكيرات؟',
                        style: TextStyle(fontSize: 14.5)),
                    subtitle: Text(
                      'مواعيدك المتكررة تتحفظ في نظام أندرويد نفسه، فيوصلك الإشعار «لديك موعد بعد كذا» حتى لو التطبيق مقفول.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('التذكيرات'),
                        content: const Text(
                          'عند إضافة موعد وتحديد تذكير له، يحفظ ناظِم إشعارًا في نظام أندرويد يتكرر كل أسبوع في نفس اليوم والساعة.\n\n'
                          'لو الإشعارات مش واصلة:\n'
                          '• استخدم زر «جرّب إشعار تجريبي» للتأكد بسرعة.\n'
                          '• وافق على صلاحية الإشعارات من الزر أعلاه.\n'
                          '• من إعدادات الهاتف: التطبيقات ← ناظِم ← الإشعارات وفعّلها.\n'
                          '• لو نظامك بيقفل تطبيقات الخلفية (شركات البطاريات)، اسمح للتطبيق بالعمل في الخلفية.',
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('فهمت'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'البيانات والنسخ الاحتياطي'),
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: const Text('تصدير نسخة احتياطية',
                        style: TextStyle(fontSize: 14.5)),
                    subtitle: Text(
                      'مشاركة ملف JSON فيه كل مواعيدك ومهامك وروتينك',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: _export,
                  ),
                  ListTile(
                    leading: const Icon(Icons.content_copy),
                    title: const Text('نسخ البيانات إلى الحافظة',
                        style: TextStyle(fontSize: 14.5)),
                    onTap: _copyData,
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('استيراد نسخة',
                        style: TextStyle(fontSize: 14.5)),
                    subtitle: Text(
                      'الصق محتوى النسخة الاحتياطية لاستعادة بياناتك',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: _importDialog,
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.delete_forever_outlined, color: scheme.error),
                    title: Text(
                      'مسح كل البيانات',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: scheme.error,
                      ),
                    ),
                    onTap: _clearAll,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'عن التطبيق'),
                  ListTile(
                    leading: Icon(Icons.auto_awesome,
                        color: scheme.tertiary, size: 22),
                    title: const Text('ناظِم — الإصدار 1.1',
                        style: TextStyle(fontSize: 14.5)),
                    subtitle: Text(
                      'منظم مهام ومواعيد أسبوعية متكررة — يعمل كليًا بدون إنترنت وبياناتك على جهازك فقط.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: scheme.onSurfaceVariant,
                      ),
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

// ============ صف حالة (صلاحيات الإشعارات) ============

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.ok, required this.text, this.neutral = false});

  final bool ok;
  final bool neutral;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = neutral ? scheme.tertiary : (ok ? Colors.green : scheme.error);
    final icon = neutral
        ? Icons.help_outline
        : (ok ? Icons.check_circle : Icons.cancel);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
      ],
    );
  }
}
