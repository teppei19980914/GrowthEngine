/// アプリ使い方ガイド & FAQ ダイアログ.
///
/// 「使い方」タブと「FAQ」タブを持ち、体験版ではガントチャート等の
/// プレミアム機能を非表示にする.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// アプリ使い方ガイドダイアログを表示する.
/// アプリ使い方ガイドダイアログを表示する.
///
/// [onStartTutorial] が指定された場合、チュートリアル開始ボタンを表示する.
Future<void> showAppGuideDialog(
  BuildContext context, {
  bool isPremium = false,
  VoidCallback? onStartTutorial,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _AppGuideDialog(
      isPremium: isPremium,
      onStartTutorial: onStartTutorial,
    ),
  );
}

class _AppGuideDialog extends StatefulWidget {
  const _AppGuideDialog({required this.isPremium, this.onStartTutorial});
  final bool isPremium;
  final VoidCallback? onStartTutorial;

  @override
  State<_AppGuideDialog> createState() => _AppGuideDialogState();
}

class _AppGuideDialogState extends State<_AppGuideDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          Icon(Icons.menu_book_outlined, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('使い方')),
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
              tabs: const [
                Tab(text: '全体像'),
                Tab(text: '使い方'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(isPremium: widget.isPremium),
                  _GuideTab(isPremium: widget.isPremium),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.onStartTutorial != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onStartTutorial!();
            },
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('チュートリアルを開始'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

// ── 全体像タブ ────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isTrialWeb = kIsWeb && !isPremium;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // ── メイン階層: 夢 → 目標 → タスク ──────────────────
          _DiagramNode(
            icon: Icons.auto_awesome,
            label: '夢',
            subtitle: '最終ゴール',
            color: primary,
            theme: theme,
          ),
          _DiagramArrow(label: '分解', theme: theme),
          _DiagramNode(
            icon: Icons.flag,
            label: '目標',
            subtitle: '具体的なステップ',
            color: primary,
            theme: theme,
          ),
          if (!isTrialWeb) ...[
            _DiagramArrow(label: '実行', theme: theme),
            _DiagramNode(
              icon: Icons.view_timeline,
              label: 'ガントチャート',
              subtitle: 'スケジュール管理・進捗記録',
              color: primary,
              theme: theme,
            ),
          ],

          const SizedBox(height: 16),

          // ── 補完関係の横並び図 ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withAlpha(8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withAlpha(25)),
            ),
            child: Column(
              children: [
                Text(
                  '連携する画面',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                // 書籍 ↔ ガントチャート
                if (!isTrialWeb)
                  _DiagramRelation(
                    theme: theme,
                    leftIcon: Icons.menu_book,
                    leftLabel: '書籍',
                    leftSub: '何を読むか\nどう読んだか',
                    rightIcon: Icons.view_timeline,
                    rightLabel: 'ガントチャート',
                    rightSub: 'いつ読むか\nスケジュール管理',
                    linkLabel: '読書計画',
                  ),
                if (!isTrialWeb) const SizedBox(height: 12),
                // 目標 ↔ ガントチャート
                if (!isTrialWeb)
                  _DiagramRelation(
                    theme: theme,
                    leftIcon: Icons.flag,
                    leftLabel: '目標',
                    leftSub: '何を達成するか',
                    rightIcon: Icons.view_timeline,
                    rightLabel: 'ガントチャート',
                    rightSub: 'いつ・どのくらい\nやるか',
                    linkLabel: 'タスク管理',
                  ),
                if (isTrialWeb)
                  _DiagramRelation(
                    theme: theme,
                    leftIcon: Icons.menu_book,
                    leftLabel: '書籍',
                    leftSub: '何を読むか\nどう読んだか',
                    rightIcon: Icons.flag,
                    rightLabel: '目標',
                    rightSub: '何を達成するか',
                    linkLabel: '紐づけ',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── サポート画面 ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DiagramMiniNode(
                  icon: Icons.dashboard,
                  label: 'ダッシュ\nボード',
                  subtitle: '今日の状況',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DiagramMiniNode(
                  icon: Icons.bar_chart,
                  label: '統計',
                  subtitle: '振り返り',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DiagramMiniNode(
                  icon: Icons.stars,
                  label: '星座',
                  subtitle: 'モチベーション',
                  theme: theme,
                ),
              ),
              if (!isTrialWeb) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _DiagramMiniNode(
                    icon: Icons.menu_book,
                    label: '書籍',
                    subtitle: '読書管理',
                    theme: theme,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 図のメインノード（夢・目標・ガントチャート）.
class _DiagramNode extends StatelessWidget {
  const _DiagramNode({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// 図の矢印（ノード間の接続）.
class _DiagramArrow extends StatelessWidget {
  const _DiagramArrow({required this.label, required this.theme});
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_downward,
                size: 16,
                color: theme.colorScheme.primary.withAlpha(120),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary.withAlpha(150),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 図の補完関係（2ノード間の双方向リンク）.
class _DiagramRelation extends StatelessWidget {
  const _DiagramRelation({
    required this.theme,
    required this.leftIcon,
    required this.leftLabel,
    required this.leftSub,
    required this.rightIcon,
    required this.rightLabel,
    required this.rightSub,
    required this.linkLabel,
  });

  final ThemeData theme;
  final IconData leftIcon;
  final String leftLabel;
  final String leftSub;
  final IconData rightIcon;
  final String rightLabel;
  final String rightSub;
  final String linkLabel;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Row(
      children: [
        // 左ノード
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withAlpha(40)),
            ),
            child: Column(
              children: [
                Icon(leftIcon, size: 18, color: primary),
                const SizedBox(height: 2),
                Text(
                  leftLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  leftSub,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // リンク
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Icon(Icons.sync_alt, size: 14, color: primary.withAlpha(100)),
              Text(
                linkLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  color: primary.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        // 右ノード
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withAlpha(40)),
            ),
            child: Column(
              children: [
                Icon(rightIcon, size: 18, color: primary),
                const SizedBox(height: 2),
                Text(
                  rightLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rightSub,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 図のサポート画面ミニノード（ダッシュボード・統計・星座）.
class _DiagramMiniNode extends StatelessWidget {
  const _DiagramMiniNode({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.hintColor.withAlpha(12),
        border: Border.all(color: theme.hintColor.withAlpha(25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.hintColor),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 使い方タブ ────────────────────────────────────────────────

class _GuideTab extends StatelessWidget {
  const _GuideTab({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTrialWeb = kIsWeb && !isPremium;

    final steps = <_GuideStep>[
      const _GuideStep(
        stepNumber: 1,
        icon: Icons.auto_awesome,
        title: '夢を登録する',
        procedures: [
          '画面下部の「夢」タブをタップ',
          '右上の「＋ 夢を追加」ボタンをタップ',
          '夢のタイトルを入力して「追加」をタップ',
        ],
        example: '例: 「ITエンジニアになる」「英語を話せるようになる」',
      ),
      const _GuideStep(
        stepNumber: 2,
        icon: Icons.flag,
        title: '目標を設定する',
        procedures: [
          '画面下部の「目標」タブをタップ',
          '「＋ 目標を追加」ボタンをタップ',
          '紐づける夢を選択',
          'What（何を）・When（いつまでに）・How（どうやって）を入力',
          '「追加」をタップ',
        ],
        example: '夢を細分化し、具体的な行動目標に落とし込みましょう',
      ),
      if (!isTrialWeb)
        const _GuideStep(
          stepNumber: 3,
          icon: Icons.view_timeline,
          title: 'ガントチャートでタスク管理',
          procedures: [
            '画面下部の「ガントチャート」タブをタップ',
            '上部のドロップダウンで目標を選択',
            '「＋ タスク追加」ボタンをタップ',
            'タスク名・開始日・終了日を入力して追加',
            'チャート上のタスクをタップして進捗を更新',
          ],
          example: 'タスクをタップすると活動ログの記録やタイマーも使えます',
        ),
      _GuideStep(
        stepNumber: isTrialWeb ? 3 : 4,
        icon: Icons.menu_book,
        title: '書籍を管理する',
        procedures: const [
          'ハンバーガーメニューから「書籍」を選択',
          '「＋ 書籍を追加」ボタンをタップ',
          'タイトルを入力して追加',
          'カレンダーアイコンで読書スケジュールを設定',
          '読了時にチェックアイコンで要約・感想を記録',
        ],
        example: '読書の進捗管理と振り返りに活用できます',
      ),
      _GuideStep(
        stepNumber: isTrialWeb ? 4 : 5,
        icon: Icons.bar_chart,
        title: '統計で振り返る',
        procedures: const [
          'ハンバーガーメニューから「統計」を選択',
          '期間（週・月・全期間）を切り替えて推移を確認',
          '活動時間・活動日数・連続記録を把握',
        ],
        example: '定期的に振り返ることで、学習習慣を定着させましょう',
      ),
      _GuideStep(
        stepNumber: isTrialWeb ? 5 : 6,
        icon: Icons.stars,
        title: '星座で成長を実感',
        procedures: const [
          'ハンバーガーメニューから「星座」を選択',
          '夢ごとに割り当てられた星座を確認',
          '活動ログを記録して星を輝かせる',
          '完成した星座をタップすると説明が表示されます',
        ],
        example: '活動の積み重ねが星座として可視化されます',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: steps.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _GuideStepItem(step: steps[index], theme: theme);
      },
    );
  }
}

class _GuideStep {
  const _GuideStep({
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.procedures,
    required this.example,
  });

  final int stepNumber;
  final IconData icon;
  final String title;
  final List<String> procedures;
  final String example;
}

class _GuideStepItem extends StatelessWidget {
  const _GuideStepItem({required this.step, required this.theme});
  final _GuideStep step;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ステップ番号 + アイコン
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withAlpha(25),
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Icon(step.icon, size: 16, color: theme.hintColor),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                // 手順リスト
                for (var i = 0; i < step.procedures.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            step.procedures[i],
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                // ヒント
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          step.example,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
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

