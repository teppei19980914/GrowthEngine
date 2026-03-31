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

import '../l10n/app_labels.dart';
import '../widgets/app_snackbar.dart';
import '../services/remote_config_service.dart';
import '../services/stripe_service.dart';
import '../services/trial_limit_service.dart';
import '../theme/app_theme.dart';

/// プレミアム機能の一覧（価値訴求）.
const _premiumFeatures = [
  (Icons.all_inclusive, AppLabels.upgradeFeature1Title, AppLabels.upgradeFeature1Desc),
  (Icons.view_timeline_outlined, AppLabels.upgradeFeature2Title, AppLabels.upgradeFeature2Desc),
  (Icons.insights, AppLabels.upgradeFeature3Title, AppLabels.upgradeFeature3Desc),
  (Icons.campaign_outlined, AppLabels.upgradeFeature4Title, AppLabels.upgradeFeature4Desc),
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
      showSuccessSnackBar(context, AppLabels.upgradeTrialStarted(trialDurationDays));
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
          showErrorSnackBar(context, AppLabels.upgradeCheckoutFailed);
        }
      }
    } on Exception {
      if (mounted) {
        showErrorSnackBar(context, AppLabels.errorRetryLater);
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
          const Expanded(child: Text(AppLabels.upgradeTitle)),
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
                AppLabels.upgradeSubtitle,
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
                                AppLabels.upgradePlanName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isTrialAvailable
                                    ? AppLabels.upgradeTrialDesc
                                    : AppLabels.upgradePaidDesc,
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
                            AppLabels.upgradePrice,
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
                          label: const Text(AppLabels.upgradeTrialButton),
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
                            _isLoading
                                ? AppLabels.upgradeProcessing
                                : AppLabels.upgradeSubscribeNow(
                                    AppLabels.upgradePrice),
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
                                ? AppLabels.upgradeProcessing
                                : AppLabels.upgradePlanSubscribe(
                                    AppLabels.upgradePrice),
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
          child: const Text(AppLabels.btnClose),
        ),
      ],
    );
  }
}
