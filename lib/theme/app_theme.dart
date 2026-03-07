/// Material 3 テーマ定義.
///
/// Catppuccinカラーパレットを使用してMaterial 3テーマを構築する.
library;

import 'package:flutter/material.dart';

import 'catppuccin_colors.dart';
export 'catppuccin_colors.dart' show AppColors;

/// テーマタイプ.
enum ThemeType {
  /// ダークテーマ.
  dark,

  /// ライトテーマ.
  light,
}

/// アプリケーションテーマを構築するユーティリティ.
class AppTheme {
  AppTheme._();

  /// ダークテーマを取得する.
  static ThemeData get darkTheme => _buildTheme(catppuccinMocha, Brightness.dark);

  /// ライトテーマを取得する.
  static ThemeData get lightTheme =>
      _buildTheme(catppuccinLatte, Brightness.light);

  /// テーマタイプからThemeDataを取得する.
  static ThemeData fromType(ThemeType type) {
    return type == ThemeType.dark ? darkTheme : lightTheme;
  }

  /// テーマタイプからAppColorsを取得する.
  static AppColors colorsFromType(ThemeType type) {
    return type == ThemeType.dark ? catppuccinMocha : catppuccinLatte;
  }

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: brightness == Brightness.dark
          ? colors.bgPrimary
          : Colors.white,
      primaryContainer: colors.accentHover,
      onPrimaryContainer: colors.textPrimary,
      secondary: colors.accentHover,
      onSecondary: brightness == Brightness.dark
          ? colors.bgPrimary
          : Colors.white,
      secondaryContainer: colors.bgSurface,
      onSecondaryContainer: colors.textPrimary,
      tertiary: colors.success,
      onTertiary: colors.bgPrimary,
      error: colors.error,
      onError: Colors.white,
      surface: colors.bgPrimary,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.bgSurface,
      outline: colors.border,
      outlineVariant: colors.bgHover,
      shadow: Colors.black26,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: colors.bgPrimary,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgSecondary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),

      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        width: 260,
      ),

      // Card
      cardTheme: CardThemeData(
        color: colors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: brightness == Brightness.dark
              ? colors.bgPrimary
              : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: brightness == Brightness.dark
            ? colors.bgPrimary
            : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgSurface,
        hintStyle: TextStyle(color: colors.textMuted),
        labelStyle: TextStyle(color: colors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.error),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),

      // ProgressIndicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.bgSurface,
        circularTrackColor: colors.bgSurface,
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        textColor: colors.textPrimary,
        iconColor: colors.textSecondary,
        selectedColor: colors.accent,
        selectedTileColor: colors.accent.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),

      // NavigationDrawer
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.accent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colors.bgPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            );
          }
          return TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.bgPrimary);
          }
          return IconThemeData(color: colors.textSecondary);
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: colors.bgSurface,
        selectedColor: colors.accent,
        labelStyle: TextStyle(color: colors.textPrimary, fontSize: 12),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.bgSurface,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: brightness == Brightness.dark
            ? colors.bgPrimary
            : Colors.white,
        unselectedLabelColor: colors.textSecondary,
        indicator: BoxDecoration(
          color: colors.accent,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(8),
          ),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent;
          }
          return colors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent.withAlpha(80);
          }
          return colors.bgSurface;
        }),
      ),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: colors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
        textStyle: TextStyle(color: colors.textPrimary),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        textStyle: TextStyle(color: colors.textPrimary, fontSize: 12),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(color: colors.textPrimary),
        displayMedium: TextStyle(color: colors.textPrimary),
        displaySmall: TextStyle(color: colors.textPrimary),
        headlineLarge: TextStyle(color: colors.textPrimary),
        headlineMedium: TextStyle(color: colors.textPrimary),
        headlineSmall: TextStyle(color: colors.textPrimary),
        titleLarge: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        titleSmall: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: colors.textPrimary, fontSize: 13),
        bodySmall: TextStyle(color: colors.textSecondary, fontSize: 12),
        labelLarge: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        labelMedium: TextStyle(color: colors.textSecondary, fontSize: 12),
        labelSmall: TextStyle(color: colors.textMuted, fontSize: 11),
      ),
    );
  }
}

/// ThemeDataのExtension — AppColorsへのアクセスを提供する.
extension ThemeDataExtension on ThemeData {
  /// テーマに対応するAppColorsを取得する.
  AppColors get appColors {
    return brightness == Brightness.dark ? catppuccinMocha : catppuccinLatte;
  }
}
