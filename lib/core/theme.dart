import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens mirroring the Tailwind palette used by the reference design.
abstract final class AppColors {
  // Neutrals (slate)
  static const bg = Color(0xFFF8FAFC); // slate-50
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xCCE2E8F0); // slate-200/80
  static const borderStrong = Color(0xFFE2E8F0); // slate-200
  static const slate100 = Color(0xFFF1F5F9);
  static const slate300 = Color(0xFFCBD5E1);
  static const textStrong = Color(0xFF0F172A); // slate-900
  static const text = Color(0xFF1E293B); // slate-800
  static const text2 = Color(0xFF334155); // slate-700
  static const textMuted = Color(0xFF64748B); // slate-500
  static const textSubtle = Color(0xFF94A3B8); // slate-400
  static const tableHead = Color(0xFFF8FAFC);
  static const hover = Color(0xFFF8FAFC);

  // Primary (emerald)
  static const primary = Color(0xFF065F46); // emerald-800
  static const primaryDark = Color(0xFF064E3B); // emerald-900
  static const primary700 = Color(0xFF047857); // emerald-700
  static const emerald700 = Color(0xFF047857);
  static const success = Color(0xFF10B981); // emerald-500
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emeraldSoft = Color(0xFF8CC9AD); // allowance bar
  static const emeraldMist = Color(0xFFD3E8DE); // "siap dibayar" segment

  // Warning (amber)
  static const amber50 = Color(0xFFFFFBEB);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber200 = Color(0xFFFDE68A);
  static const amber600 = Color(0xFFD97706);
  static const amber700 = Color(0xFFB45309);
  static const amberSegment = Color(0xFFFCEFC7);

  // Danger (rose)
  static const rose50 = Color(0xFFFFF1F2);
  static const rose600 = Color(0xFFE11D48);
  static const rose700 = Color(0xFFBE123C);

  // Info (sky / indigo)
  static const sky50 = Color(0xFFF0F9FF);
  static const sky700 = Color(0xFF0369A1);
  static const indigo50 = Color(0xFFEEF2FF);
  static const indigo700 = Color(0xFF4338CA);
}

abstract final class AppRadius {
  static const card = 16.0; // rounded-2xl
  static const control = 10.0;
  static const badge = 6.0;
}

abstract final class AppText {
  static const _f = 'Inter';

  static const pageTitle = TextStyle(
    fontFamily: _f,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textStrong,
    letterSpacing: -0.6,
  );
  static const sectionTitle = TextStyle(
    fontFamily: _f,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textStrong,
    letterSpacing: -0.2,
  );
  static const body = TextStyle(
    fontFamily: _f,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.text2,
  );
  static const bodyStrong = TextStyle(
    fontFamily: _f,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textStrong,
  );
  static const small = TextStyle(
    fontFamily: _f,
    fontSize: 12.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
  static const tiny = TextStyle(
    fontFamily: _f,
    fontSize: 11.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
  static const overline = TextStyle(
    fontFamily: _f,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textSubtle,
    letterSpacing: 0.7,
  );
  static const tableHead = TextStyle(
    fontFamily: _f,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );
  static const statValue = TextStyle(
    fontFamily: _f,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w600,
    color: AppColors.textStrong,
    letterSpacing: -0.8,
  );
  static const money = TextStyle(
    fontFamily: _f,
    fontSize: 13.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textStrong,
      error: AppColors.rose600,
    );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.surface,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: const DividerThemeData(
        color: AppColors.borderStrong,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        bodyMedium: AppText.body,
        bodySmall: AppText.small,
        titleMedium: AppText.sectionTitle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: AppText.body.copyWith(color: AppColors.textSubtle),
        labelStyle: AppText.body.copyWith(color: AppColors.textMuted),
        floatingLabelStyle:
            AppText.body.copyWith(color: AppColors.primary, fontSize: 13),
        prefixIconColor: AppColors.textSubtle,
        border: border(AppColors.borderStrong),
        enabledBorder: border(AppColors.borderStrong),
        focusedBorder: border(AppColors.primary, 1.4),
        errorBorder: border(AppColors.rose600),
        focusedErrorBorder: border(AppColors.rose600, 1.4),
        errorStyle: AppText.tiny.copyWith(color: AppColors.rose600),
        errorMaxLines: 2,
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: AppColors.slate300, width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.slate100,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textSubtle,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.borderStrong,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x1A0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
        textStyle: AppText.body.copyWith(color: AppColors.text),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.slate300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textStrong,
        contentTextStyle:
            AppText.body.copyWith(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textStrong,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppText.tiny.copyWith(color: Colors.white),
        waitDuration: const Duration(milliseconds: 500),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      platform: defaultTargetPlatform,
    );
  }
}
