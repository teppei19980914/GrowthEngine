/// 初回アクセス時のオンボーディングダイアログ.
///
/// ユーザーに夢を持つことの大切さとアプリの存在意義を伝える.
/// SharedPreferencesで初回表示フラグを管理し、1度だけ表示する.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const _onboardingCompletedKey = 'onboarding_completed';

/// オンボーディングが未完了かどうかを返す.
bool shouldShowOnboarding(SharedPreferences prefs) {
  return !(prefs.getBool(_onboardingCompletedKey) ?? false);
}

/// オンボーディングダイアログを表示する.
///
/// 初回アクセス時のみ表示し、完了後にSharedPreferencesにフラグを保存する.
/// 戻り値: ユーザーがオンボーディングを完了したかどうか.
Future<bool> showOnboardingDialog(
  BuildContext context,
  SharedPreferences prefs,
) async {
  if (!shouldShowOnboarding(prefs)) return false;

  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    barrierLabel: 'Onboarding',
    transitionDuration: const Duration(milliseconds: 600),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    pageBuilder: (context, animation, secondaryAnimation) =>
        _OnboardingDialog(prefs: prefs),
  );

  return result ?? false;
}

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog({required this.prefs});
  final SharedPreferences prefs;

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < _totalPages - 1) {
      _fadeController.reset();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    } else {
      await widget.prefs.setBool(_onboardingCompletedKey, true);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _fadeController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 500;

    return Dialog(
      backgroundColor: colors.bgPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 16 : 40,
        vertical: isSmall ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: isSmall ? screenSize.height * 0.85 : 600,
        ),
        child: Column(
          children: [
            // ページコンテンツ
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildPage1(theme, colors),
                  _buildPage2(theme, colors),
                  _buildPage3(theme, colors),
                  _buildPage4(theme, colors),
                ],
              ),
            ),

            // インジケーター + ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // ページインジケーター
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colors.accent
                              : colors.accent.withAlpha(60),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ナビゲーションボタン
                  Row(
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: _previousPage,
                          child: Text(
                            '戻る',
                            style: TextStyle(color: colors.textMuted),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      FilledButton(
                        onPressed: _nextPage,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage < _totalPages - 1 ? '次へ' : 'はじめる',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ページ 1: 問いかけ ──────────────────────────────────────
  Widget _buildPage1(ThemeData theme, AppColors colors) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _PageContent(
        colors: colors,
        icon: Icons.auto_awesome,
        iconColor: colors.accent,
        title: 'あなたには、\n「やりたいこと」がありますか？',
        body: '小さなことでも、大きなことでも。\n'
            '「こうなれたらいいな」と\n'
            '心に浮かんだことがあるはずです。',
        emphasis: 'その想いを、一歩ずつ形にしていこう。',
      ),
    );
  }

  // ── ページ 2: 気づき ───────────────────────────────────────
  Widget _buildPage2(ThemeData theme, AppColors colors) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _PageContent(
        colors: colors,
        icon: Icons.edit_note,
        iconColor: colors.accent,
        title: '書き出すことで、\n実現に向けて動き出します。',
        body: '言葉にして書き出すことで、\n'
            '脳はそれを「目標」として認識します。',
        emphasis: '文字にすることで、\n'
            '想いは「目標」へ変わる。',
      ),
    );
  }

  // ── ページ 3: 慣性の法則 ─────────────────────────────────────
  Widget _buildPage3(ThemeData theme, AppColors colors) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _PageContent(
        colors: colors,
        icon: Icons.rocket_launch,
        iconColor: colors.accent,
        title: '一歩踏み出せば、\n自然と前に進めます。',
        body: '動き出した人は、動き続けられる。\n'
            '最初の一歩さえ踏み出せば、\n'
            'あとは自然と進んでいけます。',
        emphasis: null,
      ),
    );
  }

  // ── ページ 4: アプリの存在意義 ──────────────────────────────────
  Widget _buildPage4(ThemeData theme, AppColors colors) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _PageContent(
        colors: colors,
        icon: Icons.favorite,
        iconColor: colors.accent,
        title: 'ユメログは、あなたの\n「最初の一歩」を支えます。',
        body: '夢を書き出し、目標に分解し、\n'
            '日々の行動に落とし込む。\n'
            '動き出したあなたと一緒に走り続けます。',
        emphasis: '自分の力で未来を切り拓こう。',
      ),
    );
  }
}

/// 各ページの共通レイアウト.
class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.colors,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.emphasis,
  });

  final AppColors colors;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withAlpha(25),
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(height: 20),

          // タイトル
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // 本文
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.7,
            ),
          ),

          // 強調テキスト
          if (emphasis != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withAlpha(40)),
              ),
              child: Text(
                emphasis!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
