import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/app_data.dart';
import 'screens/home_shell.dart';
import 'services/notifications.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await initializeDateFormatting('ar');
  final data = AppData();
  await data.load();
  runApp(NathimApp(data: data));
}

class NathimApp extends StatelessWidget {
  const NathimApp({super.key, required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: data,
      child: Consumer<AppData>(
        builder: (context, d, _) {
          return MaterialApp(
            title: 'ناظِم',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            darkTheme: AppTheme.dark(),
            themeMode: d.lightMode ? ThemeMode.light : ThemeMode.dark,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
