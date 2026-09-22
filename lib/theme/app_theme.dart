import 'package:flutter/material.dart';

/// الهوية الملكية: كحلي + فضي + لمسات ذهبية — ألوان ثابتة بدون fromSeed.
class AppTheme {
  AppTheme._();

  static const Color navy = Color(0xFF1A237E);
  static const Color gold = Color(0xFFE3C26B);
  static const Color silverText = Color(0xFFB9C2E8);
  static const Color darkBg = Color(0xFF0E1230);
  static const Color darkSurface = Color(0xFF141A3E);
  static const Color darkCard = Color(0xFF171E48);
  static const Color darkLine = Color(0xFF2B3263);
  static const Color onDark = Color(0xFFE9ECFA);
  static const Color primarySoft = Color(0xFF9FA8DA);

  static ThemeData dark() => _base(
        scheme: const ColorScheme.dark(
          primary: primarySoft,
          onPrimary: Color(0xFF0E1230),
          secondary: Color(0xFFC5CAE9),
          onSecondary: Color(0xFF0E1230),
          tertiary: gold,
          onTertiary: Color(0xFF1A237E),
          error: Color(0xFFEF9A9A),
          onError: Color(0xFF3B0D10),
          surface: darkSurface,
          onSurface: onDark,
          surfaceContainerHighest: darkCard,
          onSurfaceVariant: silverText,
          outline: darkLine,
          outlineVariant: darkLine,
          primaryContainer: Color(0xFF2A3468),
          onPrimaryContainer: Color(0xFFE9ECFA),
        ),
        scaffold: darkBg,
        cardColor: darkCard,
        navBg: const Color(0xFF10142E),
        sheet: const Color(0xFF12173A),
        inputFill: const Color(0xFF1A2148),
        snackbarBg: const Color(0xFF232A5C),
      );

  static ThemeData light() => _base(
        scheme: const ColorScheme.light(
          primary: navy,
          onPrimary: Colors.white,
          secondary: Color(0xFF3949AB),
          onSecondary: Colors.white,
          tertiary: Color(0xFFB58A2E),
          onTertiary: Colors.white,
          error: Color(0xFFC62828),
          onError: Colors.white,
          surface: Color(0xFFF4F5FB),
          onSurface: Color(0xFF191E45),
          surfaceContainerHighest: Colors.white,
          onSurfaceVariant: Color(0xFF5A6290),
          outline: Color(0xFFC3C8E8),
          outlineVariant: Color(0xFFDCDFF2),
          primaryContainer: Color(0xFFDFE2F7),
          onPrimaryContainer: Color(0xFF10163F),
        ),
        scaffold: const Color(0xFFF4F5FB),
        cardColor: Colors.white,
        navBg: Colors.white,
        sheet: Colors.white,
        inputFill: const Color(0xFFF0F1FA),
        snackbarBg: const Color(0xFF232A5C),
      );

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color cardColor,
    required Color navBg,
    required Color sheet,
    required Color inputFill,
    required Color snackbarBg,
  }) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStatePropertyAll<IconThemeData>(
          IconThemeData(color: scheme.onSurface),
        ),
        labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontFamily: 'Cairo',
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheet,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15,
          color: scheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheet,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackbarBg,
        contentTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: onDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: sheet,
        dialBackgroundColor: inputFill,
        hourMinuteColor: inputFill,
      ),
      datePickerTheme: DatePickerThemeData(backgroundColor: sheet),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : null,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
    );
  }
}
