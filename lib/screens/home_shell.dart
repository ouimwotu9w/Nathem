import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../services/notifications.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'tasks_screen.dart';
import 'today_screen.dart';
import 'week_screen.dart';

/// الهيكل الرئيسي: 5 تبويبات سفلية — اليوم / الأسبوع / المهام / الإحصائيات / الإعدادات
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.init();
      if (!mounted) return;
      await context.read<AppData>().refreshNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TodayScreen(
            onOpenTasks: () => setState(() => _index = 2),
          ),
          const WeekScreen(),
          const TasksScreen(),
          const StatsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'اليوم',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_repeat_outlined),
            selectedIcon: Icon(Icons.event_repeat),
            label: 'الأسبوع',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'المهام',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'الإحصائيات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
