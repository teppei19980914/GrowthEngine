/// 課金案内ダイアログ.
///
/// フィードバックによる制限解除が上限に達した後、
/// プレミアム機能へのアップグレードを案内する.
/// Stripe Checkout 経由でサブスクリプション契約を行う.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/remote_config_service.dart';
import '../services/stripe_service.dart';
import '../services/trial_limit_service.dart';
import '../theme/app_theme.dart';

/// プレミアム機能の一覧（価値訴求）.
const _premiumFeatures = [
  (Icons.all_inclusive, 'やりたいことを、制限なく追いかけられる', '夢・目標・タスク・書籍を好きなだけ登録'),
  (Icons.view_timeline_outlined, 'やるべきことが一目でわかる', 'ガントチャートで全体像を把握し、迷わず行動できる'),
  (Icons.insights, '自分の成長が見える', '活動統計で努力の積み重ねを実感できる'),
  (Icons.campaign_outlined, 'あなたの声が、新機能になる', 'フィードバックで要望した機能を最優先で利用可能'),
];

/// 課金案内ダイアログを表示する.
Future<void> showUpgradeDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _UpgradeDialog(),
  );
}

class _UpgradeDialog extends StatefulWidget {
  const _UpgradeDialog();

  @override
  State<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<_UpgradeDialog> {
  bool _isLoading = false;
  bool _isTrialAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkTrialAvailability();
  }

  Future<void> _checkTrialAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final stripeService = StripeService(prefs);
    if (mounted) {
      setState(() {
        _isTrialAvailable = !stripeService.isTrialStarted;
      });
    }
  }

  Future<void> _startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final stripeService = StripeService(prefs);
    await stripeService.startTrial();
    setTrialPremium(enabled: true);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '無料トライアルを開始しました（残り$trialDurationDays日間）',
          ),
        ),
      );
    }
  }

  Future<void> _subscribe(SharedPreferences? prefsArg) async {
    setState(() => _isLoading = true);

    try {
      final prefs = prefsArg ?? await SharedPreferences.getInstance();
      final stripeService = StripeService(prefs);
      final userKey = RemoteConfigService(prefs).savedUserKey;
      final checkoutUrl = await stripeService.createCheckoutUrl(
        userKey: userKey,
      );

      if (!mounted) return;

      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (kIsWeb) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('決済ページの取得に失敗しました。しばらく後にお試しください。')),
          );
        }
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エラーが発生しました。しばらく後にお試しください。')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star, size: 24, color: colors.accent),
          const SizedBox(width: 8),
          const Expanded(child: Text('もっと自由に、もっと先へ')),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ワンコインで、あなたの「やりたい」を全力でサポートします。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // プレミアム機能一覧
              ...(_premiumFeatures.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(f.$1, size: 20, color: colors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.$2,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              f.$3,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // プラン情報
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.accent.withAlpha(80)),
                  borderRadius: BorderRadius.circular(12),
                  color: colors.accent.withAlpha(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, size: 28, color: colors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'プレミアムプラン',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isTrialAvailable
                                    ? '初回7日間無料 ── まず試してみてください'
                                    : '月額ワンコインで全機能を利用可能',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accent.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '¥480/月',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isTrialAvailable) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _startTrial,
                          icon: const Icon(Icons.rocket_launch),
                          label: const Text('7日間無料で試してみる'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => _subscribe(null),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.payment),
                          label: Text(
                            _isLoading ? '処理中...' : 'すぐに申し込む（¥480/月）',
                          ),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : () => _subscribe(null),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.payment),
                          label: Text(
                            _isLoading
                                ? '処理中...'
                                : 'プレミアムプランに申し込む（¥480/月）',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
