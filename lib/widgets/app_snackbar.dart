/// アプリ共通の SnackBar 表示ヘルパー.
///
/// 成功・エラー・情報の3種類を統一的なスタイルで表示する.
library;

import 'package:flutter/material.dart';

/// 成功メッセージを表示する.
void showSuccessSnackBar(BuildContext context, String message) {
  _showStyledSnackBar(context, message, _SnackBarType.success);
}

/// エラーメッセージを表示する.
void showErrorSnackBar(BuildContext context, String message) {
  _showStyledSnackBar(context, message, _SnackBarType.error);
}

/// 情報メッセージを表示する.
void showInfoSnackBar(BuildContext context, String message) {
  _showStyledSnackBar(context, message, _SnackBarType.info);
}

enum _SnackBarType { success, error, info }

void _showStyledSnackBar(
  BuildContext context,
  String message,
  _SnackBarType type,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final (IconData icon, Color iconColor) = switch (type) {
    _SnackBarType.success => (Icons.check_circle, isDark ? const Color(0xFFA6E3A1) : const Color(0xFF40A02B)),
    _SnackBarType.error => (Icons.error_outline, isDark ? const Color(0xFFF38BA8) : const Color(0xFFD20F39)),
    _SnackBarType.info => (Icons.info_outline, isDark ? const Color(0xFF89B4FA) : const Color(0xFF1E66F5)),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: type == _SnackBarType.error
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3),
      ),
    );
}
