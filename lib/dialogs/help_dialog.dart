/// ヘルプダイアログ（FAQ + 体験版の制限事項）.
library;

import 'package:flutter/material.dart';
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
          const Expanded(child: Text('ヘルプ')),
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
                const Tab(text: 'アプリについて'),
                const Tab(text: 'FAQ'),
                if (_showTrialTab) const Tab(text: 'スタータープラン'),
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
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
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

  static const _faqs = <_FaqItem>[
    // ── 基本的な使い方 ──
    _FaqItem(
      question: '夢・目標・タスクの違いは何ですか？',
      answer: '「夢」は最終的に達成したい大きなビジョンです。\n'
          '「目標」は夢を実現するための具体的なステップです。\n'
          '「タスク」は目標を達成するための日々のアクションです。\n\n'
          '例: 夢「ITエンジニアになる」→ 目標「基本情報技術者を取得する」'
          '→ タスク「午前問題を毎日10問解く」',
      keywords: ['夢', '目標', 'タスク', '違い', '使い分け', '階層'],
    ),
    _FaqItem(
      question: '夢がなくても使えますか？',
      answer: '夢を登録せずに、目標やタスクだけで利用できます。\n'
          'また、「やりたいこと発見ガイド」を使えば、'
          '質問に答えるだけでやりたいことを見つける手助けができます。\n'
          '夢ページの「発見ガイド」ボタンからお試しください。',
      keywords: ['夢がない', 'やりたいこと', '発見', 'ガイド', '目標だけ'],
    ),
    _FaqItem(
      question: 'ガントチャートとは何ですか？',
      answer: 'タスクのスケジュールを横棒グラフで表示する機能です。'
          '各タスクの開始日・終了日・進捗を視覚的に確認でき、'
          'プロジェクト全体のスケジュール管理に役立ちます。\n'
          'プレミアムプランでご利用いただけます。',
      keywords: ['ガントチャート', 'ガント', 'スケジュール', 'チャート', 'タイムライン'],
    ),
    _FaqItem(
      question: '活動ログはどうやって記録しますか？',
      answer: 'ガントチャートのタスクをタップし、「活動時間を記録」を選択します。'
          '手動で時間を入力するか、タイマー機能を使って記録できます。\n'
          'ダッシュボードの「活動を記録」ボタンからも記録できます。',
      keywords: ['活動ログ', 'ログ', '記録', 'タイマー', '時間', '入力'],
    ),
    _FaqItem(
      question: '星座はどうすれば完成しますか？',
      answer: '活動ログを記録すると、活動時間に応じて星座の星が一つずつ輝きます。'
          '5時間ごとに1つの星が灯り、必要な星を全て集めると星座が完成します。',
      keywords: ['星座', '完成', '星', '輝く', '活動ログ', '時間'],
    ),

    // ── データ管理 ──
    _FaqItem(
      question: 'データはどこに保存されますか？',
      answer: 'すべてのデータはお使いのブラウザ内（ローカルストレージ）に保存されます。'
          'サーバーにデータが送信されることはありません。\n'
          'ただし、ブラウザのデータを消去するとアプリのデータも削除されます。',
      keywords: ['データ', '保存', 'ローカル', 'ブラウザ', '消去', '削除', 'プライバシー'],
    ),
    _FaqItem(
      question: 'データのバックアップはできますか？',
      answer: '設定ページの「データ管理」→「データをエクスポート」から'
          'JSON形式でバックアップできます。\n'
          'プレミアムプランでは、エクスポートしたファイルを'
          '「データをインポート」から復元できます。',
      keywords: ['バックアップ', 'エクスポート', 'インポート', '書き出し', '移行', 'データ管理'],
    ),
    _FaqItem(
      question: '別のブラウザや端末でデータを使えますか？',
      answer: 'データはブラウザごとに独立して保存されます。\n'
          '別のブラウザで使う場合は、設定ページからデータをエクスポートし、'
          '新しいブラウザでインポートしてください（プレミアムプラン）。',
      keywords: ['ブラウザ', '端末', '移行', 'エクスポート', 'インポート', '同期', '別'],
    ),

    // ── プラン・料金 ──
    _FaqItem(
      question: 'プレミアムプランを契約したい場合はどうすればよいですか？',
      answer: '画面右上のメールアイコン横の実績アイコンの隣にある'
          '設定ページの「プランのアップグレード」から申し込めます。\n'
          '月額480円（税込）で全機能をご利用いただけます。\n'
          '初回7日間の無料トライアルもご用意しています。',
      keywords: ['プレミアム', '契約', '申し込み', '料金', '価格', '480', 'サブスク', 'アップグレード'],
    ),
    _FaqItem(
      question: 'スタータープランの制限を解除するには？',
      answer: 'フィードバックを送信すると段階的に制限が解除されます。\n\n'
          'すべての機能を制限なく使うには、プレミアムプランへの'
          'アップグレードをご検討ください。\n\n'
          '【アップグレード手順】\n'
          '1. 設定ページを開く\n'
          '2.「プランのアップグレード」をタップ\n'
          '3.「7日間無料で試してみる」または「今すぐ申し込む」を選択\n'
          '4. Stripeの決済画面でカード情報を入力',
      keywords: ['制限', '解除', 'フィードバック', 'プレミアム', '無料', 'スターター', 'アップグレード'],
    ),
    _FaqItem(
      question: 'プレミアムプランを解約したい場合はどうすればよいですか？',
      answer: '画面右上のメールアイコンから「お問い合わせ」を選択し、'
          '解約希望の旨をお伝えください。\n'
          'その際、プレミアムプラン申込時に入力したメールアドレスを'
          '必ずご記載ください（契約の特定に必要です）。\n\n'
          '解約後は次回更新日以降に課金が停止され、'
          'スタータープランに移行します。\n'
          '登録済みのデータはそのまま残ります。',
      keywords: ['解約', 'キャンセル', '退会', '課金', '停止', 'やめる', '問い合わせ'],
    ),

    // ── 問い合わせ・フィードバック ──
    _FaqItem(
      question: '問い合わせをしたい場合はどうすればよいですか？',
      answer: '画面右上のメールアイコンをタップし、'
          '「お問い合わせ」を選択してください。\n'
          '追加開発のご相談や案件のご依頼などを受け付けています。',
      keywords: ['問い合わせ', 'お問い合わせ', '連絡', '相談', 'メール', 'アイコン'],
    ),
    _FaqItem(
      question: 'フィードバックを送りたい場合はどうすればよいですか？',
      answer: '画面右上のメールアイコンをタップし、'
          '「フィードバック」を選択してください。\n'
          '改善要望・不具合報告・その他のご意見を受け付けています。\n'
          'いただいたフィードバックは新機能の開発や改善に活用させていただきます。',
      keywords: ['フィードバック', '意見', '要望', '不具合', '報告', 'メール'],
    ),

    // ── 端末・環境 ──
    _FaqItem(
      question: 'スマートフォンでも使えますか？',
      answer: 'はい、スマートフォンのブラウザからアクセスできます。\n'
          'iOSの場合はSafariで開き、共有ボタン→「ホーム画面に追加」で'
          'アプリのように使えます。\n'
          'Androidの場合はChromeで開き、メニュー→「ホーム画面に追加」で同様です。',
      keywords: ['スマートフォン', 'スマホ', 'モバイル', '携帯', 'ホーム画面', 'iOS', 'Android'],
    ),
    _FaqItem(
      question: '対応しているブラウザはどれですか？',
      answer: 'Google Chrome / Microsoft Edge / Safari / Firefox の'
          '最新版に対応しています。\n'
          'PC・スマートフォンのどちらでもご利用いただけます。',
      keywords: ['ブラウザ', '対応', 'Chrome', 'Edge', 'Safari', 'Firefox', '推奨'],
    ),

    // ── アプリの利用終了 ──
    _FaqItem(
      question: 'アプリの利用を終了（退会）したい場合はどうすればよいですか？',
      answer: 'ユーザー登録がないため、退会手続きは不要です。\n'
          '設定ページの「全データを削除」でアプリ内のデータを消去し、'
          'ブラウザのブックマークを削除すれば完了です。\n\n'
          '【重要】プレミアムプランをご契約中の場合は、'
          '必ず事前にメールアイコンの「お問い合わせ」から'
          '解約をご連絡ください。\n'
          '解約手続きを行わない場合、毎月の請求が継続されます。',
      keywords: ['終了', '退会', 'やめる', '削除', 'アカウント', '解約', '利用停止'],
    ),

    // ── 書籍 ──
    _FaqItem(
      question: '書籍はどこから登録できますか？',
      answer: 'ハンバーガーメニュー（左上の三本線）から「書籍」を選択し、'
          '上部の入力欄からタイトルを入力して追加できます。\n'
          '登録した書籍をタップすると、カテゴリやメモの編集ができます。',
      keywords: ['書籍', '本', '登録', '追加', '読書'],
    ),

    // ── その他 ──
    _FaqItem(
      question: 'チュートリアルをもう一度やりたい場合は？',
      answer: '画面右上の初心者マーク（使い方）アイコンをタップし、'
          '「チュートリアルを開始」ボタンから再度体験できます。\n'
          'チュートリアル中に作成したデータは、'
          '完了時に保持するか削除するかを選べます。',
      keywords: ['チュートリアル', 'やり直し', '再開', '使い方', '操作方法'],
    ),
    _FaqItem(
      question: '実績（マイルストーン）はどこで確認できますか？',
      answer: '画面右上のトロフィーアイコンをタップすると、'
          '達成した実績の一覧が表示されます。\n'
          '活動時間や連続日数に応じて新しい実績が解除されます。\n'
          '新しい実績が達成されると、アイコンにバッジが表示されます。',
      keywords: ['実績', 'マイルストーン', 'トロフィー', '達成', 'バッジ'],
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
              hintText: 'キーワードで検索...',
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
                        '該当するFAQが見つかりません',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _FaqExpansionTile(faq: filtered[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.keywords,
  });
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
            title: '完全匿名でご利用いただけます',
            subtitle: 'ユーザー登録・ログインは不要です。\n'
                '入力したデータは全てお使いのブラウザ内にのみ保存され、'
                '開発者を含む第三者に送信・公開されることはありません。',
          ),
          _InfoRow(
            icon: Icons.warning_amber,
            color: Colors.amber,
            title: 'ブラウザのデータ削除で全データが消えます',
            subtitle: 'ブラウザのキャッシュやデータを消去すると、'
                'アプリで登録した夢・目標・タスク・書籍・活動ログ等'
                '全てのデータが削除されます。',
          ),
          _InfoRow(
            icon: Icons.devices,
            color: Colors.deepOrange,
            title: '別の端末・ブラウザではデータを引き継げません',
            subtitle: 'データはブラウザごとに独立して保存されます。\n'
                'プレミアムプランでは設定画面のエクスポート/インポート機能で'
                'データ移行が可能です。',
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
                    '大切なデータは定期的にエクスポートして'
                    'バックアップすることをおすすめします。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
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
            '登録上限',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.auto_awesome,
            color: Colors.blue,
            title: '夢: 1個まで',
            subtitle: null,
          ),
          _InfoRow(
            icon: Icons.flag,
            color: Colors.green,
            title: '目標: 夢1つにつき2個まで',
            subtitle: null,
          ),
          _InfoRow(
            icon: Icons.menu_book,
            color: Colors.purple,
            title: '書籍: 3冊まで',
            subtitle: null,
          ),
          _InfoRow(
            icon: Icons.lock_outline,
            color: Colors.red,
            title: 'ガントチャート・詳細統計: 利用不可',
            subtitle: 'フィードバック送信で段階的に登録上限が緩和されます',
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
                  'プレミアムプラン',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '月額480円（税込）で全機能を制限なくご利用いただけます。\n'
                  '初回7日間の無料トライアルもご用意しています。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '設定ページの「プランのアップグレード」からお申し込みください。',
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
