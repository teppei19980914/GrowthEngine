/// Web体験版の注意バナー.
///
/// Web版アプリでのみ表示し、データの取り扱いに関する注意事項を表示する.
/// 現在の解除レベルに応じた制限値を表示する.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/feedback_service.dart';
import '../../services/invite_service.dart';
import '../../services/trial_limit_service.dart';

const _webBannerDismissedKey = 'web_trial_banner_dismissed';
const _webDialogShownKey = 'web_trial_dialog_shown';

/// Web体験版バナー（ダッシュボード上部に表示）.
class WebTrialBanner extends StatefulWidget {
  /// WebTrialBannerを作成する.
  const WebTrialBanner({required this.prefs, super.key});

  /// SharedPreferences.
  final SharedPreferences prefs;

  @override
  State<WebTrialBanner> createState() => _WebTrialBannerState();
}

class _WebTrialBannerState extends State<WebTrialBanner> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _dismissed = widget.prefs.getBool(_webBannerDismissedKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inviteStatus = InviteService(widget.prefs).getStatus();
    final level = FeedbackService(widget.prefs).unlockLevel;
    final isUnlimited = level >= feedbackMaxLevel;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A40)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF4A4A6A)
              : const Color(0xFFFFE082),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: isDark
                ? const Color(0xFFFFD54F)
                : const Color(0xFFF9A825),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inviteStatus.isActive
                      ? '招待プラン利用中です'
                      : 'Web体験版をご利用中です',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inviteStatus.isActive
                      ? '全機能をご利用いただけます。'
                          '残り${inviteStatus.remainingDays}日'
                      : isUnlimited
                          ? '基本機能の制限は完全に解除されています。'
                              'ガントチャート等のプレミアム機能はネイティブアプリをご利用ください。'
                          : '夢${maxDreams(level)}個・'
                              '目標${maxGoalsPerDream(level)}個/夢・'
                              '書籍${maxBooks(level)}冊まで'
                              '（レベル$level / $feedbackMaxLevel）。'
                              'ガントチャート等のプレミアム機能はネイティブアプリをご利用ください。',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _dismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: '閉じる',
          ),
        ],
      ),
    );
  }

  void _dismiss() {
    setState(() => _dismissed = true);
    widget.prefs.setBool(_webBannerDismissedKey, true);
  }
}

/// Web体験版のダイアログを表示する（設定画面などから手動表示用）.
Future<void> showWebTrialDialog(
  BuildContext context,
  SharedPreferences prefs,
) async {
  final level = FeedbackService(prefs).unlockLevel;
  await _showTrialDialog(context, unlockLevel: level, barrierDismissible: true);
}

/// Web体験版の初回ダイアログを表示する.
///
/// 初回のみ表示し、以降はSharedPreferencesで制御する.
/// ダイアログが表示された場合は`true`を返す.
Future<bool> showWebTrialDialogIfNeeded(
  BuildContext context,
  SharedPreferences prefs,
) async {
  if (!kIsWeb) return false;
  if (prefs.getBool(_webDialogShownKey) ?? false) return false;

  await prefs.setBool(_webDialogShownKey, true);

  if (!context.mounted) return false;

  final level = FeedbackService(prefs).unlockLevel;
  await _showTrialDialog(
    context,
    unlockLevel: level,
    barrierDismissible: false,
  );
  return true;
}

Future<void> _showTrialDialog(
  BuildContext context, {
  required int unlockLevel,
  required bool barrierDismissible,
}) async {
  final isUnlimited = unlockLevel >= feedbackMaxLevel;

  await showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.language, size: 24),
          SizedBox(width: 8),
          Text('Web体験版について'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'このアプリはWeb体験版です。デスクトップ版のインストール前に'
            '機能をお試しいただけます。',
          ),
          const SizedBox(height: 16),
          const _NoticeItem(
            icon: Icons.shield_outlined,
            text: '完全匿名でご利用いただけます。\n'
                'ユーザー登録・ログインは不要です。入力したデータは全て'
                'お使いのブラウザ内にのみ保存され、開発者を含む第三者に'
                '送信・公開されることはありません。',
          ),
          const SizedBox(height: 8),
          const _NoticeItem(
            icon: Icons.warning_amber_outlined,
            text: 'ブラウザのキャッシュ/データを削除すると、'
                '全ての活動記録が消えます。',
          ),
          const SizedBox(height: 8),
          const _NoticeItem(
            icon: Icons.devices_outlined,
            text: '別の端末や別のブラウザからアクセスすると、'
                'データは引き継がれません。\n'
                '(設定画面のエクスポート/インポート機能で移行可能)',
          ),
          const SizedBox(height: 12),
          _NoticeItem(
            icon: Icons.lock_outline,
            text: isUnlimited
                ? '制限は完全に解除されています。'
                : '体験版の登録上限（レベル$unlockLevel / $feedbackMaxLevel）: '
                    '夢${maxDreams(unlockLevel)}個、'
                    '目標${maxGoalsPerDream(unlockLevel)}個/夢、'
                    '書籍${maxBooks(unlockLevel)}冊',
          ),
          const SizedBox(height: 16),
          const Text(
            'ネイティブアプリをインストールすると、ガントチャート・'
            '高度な統計等のプレミアム機能も含め全機能を制限なくご利用いただけます。',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'この情報は設定画面からいつでも確認できます。',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('理解しました'),
        ),
      ],
    ),
  );
}

/// 注意事項の項目表示.
class _NoticeItem extends StatelessWidget {
  const _NoticeItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFF9A825)),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
