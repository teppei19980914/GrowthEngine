/// ヘルプダイアログ（FAQ + 体験版の制限事項）.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_labels.dart';
import '../services/html_launcher_service.dart';
import '../services/release_notes_page_service.dart';
import '../services/trial_limit_service.dart';

/// ヘルプダイアログを表示する.
Future<void> showHelpDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _HelpDialog(),
  );
}

class _HelpDialog extends StatefulWidget {
  const _HelpDialog();

  @override
  State<_HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<_HelpDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _showTrialTab = isTrialMode && !isPremium;

  Future<void> _openReleaseNotes() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final html = generateReleaseNotesHtml(isDarkMode: isDark);
    await openHtmlInNewTab(html);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _showTrialTab ? 3 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text(AppLabels.helpTitle)),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: AppLabels.helpTabAbout),
                const Tab(text: AppLabels.helpTabFaq),
                if (_showTrialTab) const Tab(text: AppLabels.helpTabPlan),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const _AboutTab(),
                  const _FaqTab(),
                  if (_showTrialTab) const _TrialInfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: _openReleaseNotes,
          icon: const Icon(Icons.update, size: 16),
          label: const Text(AppLabels.helpUpdateInfo),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppLabels.btnClose),
        ),
      ],
    );
  }
}

// ── FAQ タブ ─────────────────────────────────────────────────

class _FaqTab extends StatefulWidget {
  const _FaqTab();

  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> {
  String _searchQuery = '';

  static const _categoryOrder = [
    '基本的な使い方',
    'データ管理',
    'プラン・料金',
    '問い合わせ・感想',
    '端末・環境',
    'その他',
  ];

  static const _faqs = <_FaqItem>[
    // ── 基本的な使い方 ──
    _FaqItem(
      category: '基本的な使い方',
      question: AppLabels.helpFaqDreamGoalTaskQ,
      answer: AppLabels.helpFaqDreamGoalTaskA,
      keywords: ['夢', '目標', 'タスク', '違い', '使い分け', '階層'],
    ),
    _FaqItem(
      category: '基本的な使い方',
      question: AppLabels.helpFaqNoDreamQ,
      answer: AppLabels.helpFaqNoDreamA,
      keywords: ['夢がない', 'やりたいこと', '発見', 'ガイド', '目標だけ'],
    ),
    _FaqItem(
      category: '基本的な使い方',
      question: AppLabels.helpFaqScheduleQ,
      answer: AppLabels.helpFaqScheduleA,
      keywords: ['ガントチャート', 'ガント', 'スケジュール', 'チャート', 'タイムライン'],
    ),
    _FaqItem(
      category: '基本的な使い方',
      question: AppLabels.helpFaqActivityLogQ,
      answer: AppLabels.helpFaqActivityLogA,
      keywords: ['活動ログ', 'ログ', '記録', 'タイマー', '時間', '入力'],
    ),
    _FaqItem(
      category: '基本的な使い方',
      question: AppLabels.helpFaqConstellationQ,
      answer: AppLabels.helpFaqConstellationA,
      keywords: ['星座', '完成', '星', '輝く', '活動ログ', '時間'],
    ),
    _FaqItem(
      category: '基本的な使い方',
      question: AppLabels.helpFaqBookQ,
      answer: AppLabels.helpFaqBookA,
      keywords: ['書籍', '本', '登録', '追加', '読書'],
    ),

    // ── データ管理 ──
    _FaqItem(
      category: 'データ管理',
      question: AppLabels.helpFaqDataStorageQ,
      answer: AppLabels.helpFaqDataStorageA,
      keywords: ['データ', '保存', 'ローカル', 'ブラウザ', 'クラウド', '認証', 'プライバシー'],
    ),
    _FaqItem(
      category: 'データ管理',
      question: AppLabels.helpFaqDataStorageCloudQ,
      answer: AppLabels.helpFaqDataStorageCloudA,
      keywords: ['クラウド', '同期', 'バックアップ', '復元', 'メール', '認証', 'Firestore'],
    ),
    _FaqItem(
      category: 'データ管理',
      question: AppLabels.helpFaqDataStorageLocalQ,
      answer: AppLabels.helpFaqDataStorageLocalA,
      keywords: ['ブラウザ', 'ローカル', '消去', '削除', '匿名', '未認証'],
    ),
    _FaqItem(
      category: 'データ管理',
      question: AppLabels.helpFaqBackupQ,
      answer: AppLabels.helpFaqBackupA,
      keywords: ['バックアップ', 'エクスポート', 'インポート', '書き出し', '移行', 'データ管理'],
    ),
    _FaqItem(
      category: 'データ管理',
      question: AppLabels.helpFaqOtherBrowserQ,
      answer: AppLabels.helpFaqOtherBrowserA,
      keywords: ['ブラウザ', '端末', '移行', 'エクスポート', 'インポート', '同期', '別'],
    ),
    _FaqItem(
      category: 'データ管理',
      question: AppLabels.helpFaqAutoDeleteQ,
      answer: AppLabels.helpFaqAutoDeleteA,
      keywords: [
        '自動削除',
        '30日',
        '保持期間',
        '既読',
        '完了',
        'タスク',
        '通知',
        '受信ボックス',
        'エクスポート',
      ],
    ),

    // ── プラン・料金 ──
    _FaqItem(
      category: 'プラン・料金',
      question: AppLabels.helpFaqPremiumSubscribeQ,
      answer: AppLabels.helpFaqPremiumSubscribeA,
      keywords: ['プレミアム', '契約', '申し込み', '料金', '価格', '200', 'サブスク', 'アップグレード'],
    ),
    _FaqItem(
      category: 'プラン・料金',
      question: AppLabels.helpFaqStarterLimitQ,
      answer: AppLabels.helpFaqStarterLimitA,
      keywords: ['制限', '解除', 'フィードバック', 'プレミアム', '無料', 'スターター', 'アップグレード'],
    ),
    _FaqItem(
      category: 'プラン・料金',
      question: AppLabels.helpFaqPremiumCancelQ,
      answer: AppLabels.helpFaqPremiumCancelA,
      keywords: ['解約', 'キャンセル', '退会', '課金', '停止', 'やめる', '問い合わせ'],
    ),

    // ── 問い合わせ・感想 ──
    _FaqItem(
      category: '問い合わせ・感想',
      question: AppLabels.helpFaqInquiryQ,
      answer: AppLabels.helpFaqInquiryA,
      keywords: ['問い合わせ', 'お問い合わせ', '連絡', '相談', 'メール', 'アイコン'],
    ),
    _FaqItem(
      category: '問い合わせ・感想',
      question: AppLabels.helpFaqFeedbackQ,
      answer: AppLabels.helpFaqFeedbackA,
      keywords: ['フィードバック', '意見', '要望', '不具合', '報告', 'メール', '感想'],
    ),
    _FaqItem(
      category: '問い合わせ・感想',
      question: AppLabels.helpFaqFeedbackWhyQ,
      answer: AppLabels.helpFaqFeedbackWhyA,
      keywords: ['感想', '要望', '機能', 'ほしい', '改善', '一緒', '育てる', '声'],
    ),

    // ── 端末・環境 ──
    _FaqItem(
      category: '端末・環境',
      question: AppLabels.helpFaqSmartphoneQ,
      answer: AppLabels.helpFaqSmartphoneA,
      keywords: ['スマートフォン', 'スマホ', 'モバイル', '携帯', 'ホーム画面', 'iOS', 'Android'],
    ),
    _FaqItem(
      category: '端末・環境',
      question: AppLabels.helpFaqBrowserQ,
      answer: AppLabels.helpFaqBrowserA,
      keywords: ['ブラウザ', '対応', 'Chrome', 'Edge', 'Safari', 'Firefox', '推奨'],
    ),

    // ── その他 ──
    _FaqItem(
      category: 'その他',
      question: AppLabels.helpFaqQuitQ,
      answer: AppLabels.helpFaqQuitA,
      keywords: ['終了', '退会', 'やめる', '削除', 'アカウント', '解約', '利用停止'],
    ),
    _FaqItem(
      category: 'その他',
      question: AppLabels.helpFaqTutorialQ,
      answer: AppLabels.helpFaqTutorialA,
      keywords: ['チュートリアル', 'やり直し', '再開', '使い方', '操作方法'],
    ),
    _FaqItem(
      category: 'その他',
      question: AppLabels.helpFaqAchievementQ,
      answer: AppLabels.helpFaqAchievementA,
      keywords: ['実績', 'マイルストーン', 'トロフィー', '達成', 'バッジ'],
    ),
    _FaqItem(
      category: 'その他',
      question: AppLabels.helpFaqDevThoughtQ,
      answer: AppLabels.helpFaqDevThoughtA,
      keywords: ['開発者', '思い', 'コンセプト', '理念', 'メッセージ'],
    ),
  ];

  List<_FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    final query = _searchQuery.toLowerCase();
    return _faqs.where((faq) {
      return faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query) ||
          faq.keywords.any((k) => k.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredFaqs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: AppLabels.helpSearchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 40, color: theme.hintColor),
                      const SizedBox(height: 8),
                      Text(
                        AppLabels.helpFaqSearchNoResult,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                )
              : _searchQuery.isNotEmpty
                  // 検索時: フラットリスト
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) =>
                          _FaqExpansionTile(faq: filtered[index]),
                    )
                  // 通常時: カテゴリ別表示
                  : _buildCategorizedList(theme, filtered),
        ),
      ],
    );
  }

  Widget _buildCategorizedList(ThemeData theme, List<_FaqItem> faqs) {
    // カテゴリ順でグルーピング
    final grouped = <String, List<_FaqItem>>{};
    for (final faq in faqs) {
      (grouped[faq.category] ??= []).add(faq);
    }

    final children = <Widget>[];
    for (final category in _categoryOrder) {
      final items = grouped[category];
      if (items == null || items.isEmpty) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(
            category,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
      for (final faq in items) {
        children.add(_FaqExpansionTile(faq: faq));
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: children,
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
    required this.keywords,
  });
  final String category;
  final String question;
  final String answer;
  final List<String> keywords;
}

class _FaqExpansionTile extends StatelessWidget {
  const _FaqExpansionTile({required this.faq});
  final _FaqItem faq;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      leading: Icon(Icons.help, size: 20, color: theme.colorScheme.primary),
      title: Text(
        faq.question,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(faq.answer, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

// ── アプリについてタブ ──────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.security,
            color: Colors.orange,
            title: AppLabels.helpAboutAnonymousTitle,
            subtitle: AppLabels.helpAboutAnonymousDesc,
          ),
          _InfoRow(
            icon: Icons.warning_amber,
            color: Colors.amber,
            title: AppLabels.helpAboutDataDeleteTitle,
            subtitle: AppLabels.helpAboutDataDeleteDesc,
          ),
          _InfoRow(
            icon: Icons.devices,
            color: Colors.deepOrange,
            title: AppLabels.helpAboutDeviceTitle,
            subtitle: AppLabels.helpAboutDeviceDesc,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(30),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLabels.helpAboutBackupTip,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          // 開発者の思い
          Row(
            children: [
              Icon(Icons.favorite, size: 20,
                  color: theme.colorScheme.error.withAlpha(180)),
              const SizedBox(width: 8),
              Text(
                AppLabels.helpDevThoughtTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLabels.helpDevThoughtMessage,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 16),
          // ホームページリンクカード
          InkWell(
            onTap: () => launchUrl(
              Uri.parse(AppLabels.helpDevHomepageUrl),
              mode: LaunchMode.externalApplication,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(40),
                ),
                color: theme.colorScheme.primary.withAlpha(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, size: 28,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLabels.helpDevHomepageLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLabels.helpDevHomepageUrl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new, size: 18,
                      color: theme.colorScheme.primary.withAlpha(150)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── スタータープランタブ ──────────────────────────────────────

class _TrialInfoTab extends StatelessWidget {
  const _TrialInfoTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLabels.helpPlanRegistrationLimit,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.auto_awesome,
            color: Colors.blue,
            title: AppLabels.helpPlanDreamLimit,
            subtitle: null,
          ),
          _InfoRow(
            icon: Icons.flag,
            color: Colors.green,
            title: AppLabels.helpPlanGoalLimit,
            subtitle: null,
          ),
          _InfoRow(
            icon: Icons.menu_book,
            color: Colors.purple,
            title: AppLabels.helpPlanBookLimit,
            subtitle: null,
          ),
          _InfoRow(
            icon: Icons.lock_outline,
            color: Colors.red,
            title: AppLabels.helpPlanLockedFeatures,
            subtitle: AppLabels.helpPlanFeedbackUnlock,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(40),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium,
                    size: 28, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  AppLabels.helpPlanPremiumName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLabels.helpPlanPremiumDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLabels.helpPlanPremiumUpgradeHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
