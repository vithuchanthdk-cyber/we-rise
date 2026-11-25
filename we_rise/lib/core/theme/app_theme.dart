import 'package:flutter/material.dart';

/// WE RISE design tokens — civic, clean, accessible.
///
/// Primary: deep teal (action / trust)
/// Secondary: saffron-orange (energy / urgency)
/// Error: red-700 (danger / escalation)
/// Success: green-700 (resolved)
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF006D77);       // deep teal
  static const primaryDark = Color(0xFF004D56);
  static const primaryLight = Color(0xFF83C5BE);
  static const secondary = Color(0xFFE29225);     // saffron
  static const secondaryDark = Color(0xFFB36B00);

  // Semantic
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57C00);
  static const error = Color(0xFFC62828);
  static const info = Color(0xFF1565C0);

  // Status colours (complaint timeline)
  static const statusPending = Color(0xFF9E9E9E);
  static const statusVerified = Color(0xFF1976D2);
  static const statusAssigned = Color(0xFF7B1FA2);
  static const statusWorkStarted = Color(0xFFF57C00);
  static const statusResolved = Color(0xFF388E3C);
  static const statusEscalated = Color(0xFFD32F2F);
  static const statusRejected = Color(0xFF757575);

  // Priority heat
  static const priorityLow = Color(0xFF43A047);
  static const priorityMedium = Color(0xFFFB8C00);
  static const priorityHigh = Color(0xFFE53935);

  // Neutral
  static const surface = Color(0xFFF8F9FA);
  static const surfaceDark = Color(0xFF1A1C1E);
  static const divider = Color(0xFFE0E0E0);
  static const textPrimary = Color(0xFF1A1C1E);
  static const textSecondary = Color(0xFF49454F);
  static const textDisabled = Color(0xFF9E9E9E);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}

abstract final class AppTextStyles {
  static const _baseFamily = 'Inter';
  static const _tamilFamily = 'NotoSansTamil';

  static const displayLarge = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const displayMedium = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const titleLarge = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const titleMedium = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const titleSmall = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const bodyLarge = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const labelLarge = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const caption = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // Tamil script overrides — Noto Sans Tamil
  static const tamilBody = TextStyle(
    fontFamily: _tamilFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const tamilTitle = TextStyle(
    fontFamily: _tamilFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
  static const xl = Radius.circular(24);
  static const full = Radius.circular(999);
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark ? _darkScheme : _lightScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadius.md),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadius.md),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadius.md),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
        side: BorderSide.none,
        labelStyle: AppTextStyles.bodySmall,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.md),
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.caption,
      ),
    );
  }

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: Color(0xFFB2DFDB),
    onPrimaryContainer: Color(0xFF003A3E),
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: Color(0xFFFFE0B2),
    onSecondaryContainer: Color(0xFF5D3A00),
    tertiary: Color(0xFF4A6572),
    onTertiary: AppColors.white,
    tertiaryContainer: Color(0xFFCFE8F3),
    onTertiaryContainer: Color(0xFF0D2F3A),
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: Color(0xFFE6E0E9),
    onSurfaceVariant: AppColors.textSecondary,
    outline: Color(0xFF79747E),
    outlineVariant: AppColors.divider,
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: AppColors.primaryLight,
    shadow: AppColors.black,
    scrim: AppColors.black,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    onPrimary: Color(0xFF003A3E),
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: Color(0xFFFFB74D),
    onSecondary: Color(0xFF5D3A00),
    secondaryContainer: Color(0xFF7D4B00),
    onSecondaryContainer: Color(0xFFFFDDB4),
    tertiary: Color(0xFFB1CBD6),
    onTertiary: Color(0xFF1C3A47),
    tertiaryContainer: Color(0xFF334E5A),
    onTertiaryContainer: Color(0xFFCFE8F3),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.surfaceDark,
    onSurface: Color(0xFFE6E1E5),
    surfaceContainerHighest: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: AppColors.primary,
    shadow: AppColors.black,
    scrim: AppColors.black,
  );
}
