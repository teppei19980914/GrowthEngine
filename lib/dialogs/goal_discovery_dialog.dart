/// 目標発見ガイドダイアログ.
///
/// 夢の選択→思考の整理→テンプレート提案→目標作成の流れで
/// ユーザーの目標設定をサポートする.
library;

import 'package:flutter/material.dart';

import '../data/goal_templates.dart';
import '../models/dream.dart';
import '../theme/app_theme.dart';

/// 目標発見ガイドの結果.
class GoalDiscoveryResult {
  /// GoalDiscoveryResultを作成する.
  const GoalDiscoveryResult({
    required this.dreamId,
    required this.what,
    required this.how,
    required this.whenTarget,
  });

  /// 紐づく夢のID（空文字なら独立目標）.
  final String dreamId;

  /// What.
  final String what;

  /// How.
  final String how;

  /// When.
  final String whenTarget;
}

/// 目標発見ガイドダイアログを表示する.
Future<GoalDiscoveryResult?> showGoalDiscoveryDialog(
  BuildContext context, {
  required List<Dream> dreams,
}) {
  return showGeneralDialog<GoalDiscoveryResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    barrierLabel: 'GoalDiscovery',
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    pageBuilder: (context, animation, secondaryAnimation) =>
        _GoalDiscoveryDialog(dreams: dreams),
  );
}

class _GoalDiscoveryDialog extends StatefulWidget {
  const _GoalDiscoveryDialog({required this.dreams});
  final List<Dream> dreams;

  @override
  State<_GoalDiscoveryDialog> createState() => _GoalDiscoveryDialogState();
}

class _GoalDiscoveryDialogState extends State<_GoalDiscoveryDialog> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1: 夢の選択
  Dream? _selectedDream;
  bool _noDream = false;

  // Page 2: 思考の整理（質問への回答）
  final List<Set<int>> _selectedHints = [
    for (var i = 0; i < goalGuideQuestions.length; i++) <int>{},
  ];

  // Page 3: テンプレート選択
  GoalTemplate? _selectedTemplate;

  // Page 4: フォーム
  final _formKey = GlobalKey<FormState>();
  final _whatController = TextEditingController();
  final _howController = TextEditingController();
  final _whenController = TextEditingController();

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _whatController.dispose();
    _howController.dispose();
    _whenController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _selectedDream != null || _noDream;
      case 1:
        return true; // 質問は任意
      case 2:
        return true; // テンプレート選択は任意
      case 3:
        return true;
      default:
        return false;
    }
  }

  List<GoalTemplate> get _availableTemplates {
    if (_selectedDream != null) {
      final cat = _selectedDream!.category;
      return goalTemplatesByDreamCategory[cat] ?? genericGoalTemplates;
    }
    return genericGoalTemplates;
  }

  void _applyTemplate(GoalTemplate template) {
    setState(() => _selectedTemplate = template);
    _whatController.text = template.what;
    _howController.text = template.how;
    _whenController.text = template.suggestedPeriod;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      GoalDiscoveryResult(
        dreamId: _selectedDream?.id ?? '',
        what: _whatController.text.trim(),
        how: _howController.text.trim(),
        whenTarget: _whenController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final screenSize = MediaQuery.of(context).size;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Material(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '目標設定ガイド',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // プログレスインジケーター
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: List.generate(_totalPages, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? theme.colorScheme.primary
                              : colors.textMuted.withAlpha(40),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // コンテンツ
              Flexible(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDreamSelectionPage(theme, colors),
                    _buildQuestionsPage(theme, colors),
                    _buildTemplatePage(theme, colors),
                    _buildFormPage(theme, colors),
                  ],
                ),
              ),

              // ナビゲーションボタン
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () => _goToPage(_currentPage - 1),
                        child: const Text('戻る'),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_currentPage < _totalPages - 1)
                      ElevatedButton(
                        onPressed: _canProceed
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                        child: const Text('次へ'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('目標を作成'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Page 1: 夢の選択
  Widget _buildDreamSelectionPage(ThemeData theme, AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'どの夢に向けた目標ですか？',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '夢と紐づけることで、目標の意味がより明確になります。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // 夢のリスト
          ...widget.dreams.map((dream) {
            final isSelected = _selectedDream?.id == dream.id && !_noDream;
            final cat = dream.dreamCategory;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedDream = dream;
                  _noDream = false;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withAlpha(25)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? cat.color : theme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dream.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (dream.description.isNotEmpty)
                              Text(
                                dream.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: cat.color),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          // 夢なしオプション
          GestureDetector(
            onTap: () => setState(() {
              _noDream = true;
              _selectedDream = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _noDream
                    ? colors.textMuted.withAlpha(25)
                    : Colors.transparent,
                border: Border.all(
                  color: _noDream ? colors.textMuted : theme.dividerColor,
                  width: _noDream ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.explore_outlined,
                      color: colors.textMuted, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '夢とは紐づけず、独立した目標を立てる',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  if (_noDream)
                    Icon(Icons.check_circle, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 2: 思考の整理
  Widget _buildQuestionsPage(ThemeData theme, AppColors colors) {
    final dreamTitle = _selectedDream?.title;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dreamTitle != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '「$dreamTitle」を実現するために考えてみましょう',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          ...List.generate(goalGuideQuestions.length, (qi) {
            final q = goalGuideQuestions[qi];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(q.hints.length, (hi) {
                      final selected = _selectedHints[qi].contains(hi);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedHints[qi].remove(hi);
                          } else {
                            _selectedHints[qi].add(hi);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primary.withAlpha(25)
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            q.hints[hi],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : colors.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Page 3: テンプレート選択
  Widget _buildTemplatePage(ThemeData theme, AppColors colors) {
    final templates = _availableTemplates;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'テンプレートから選ぶ',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'そのまま使っても、自分なりにアレンジしてもOKです。\n「自分で考える」場合はそのまま「次へ」を押してください。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          ...templates.map((t) {
            final isSelected = _selectedTemplate == t;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _applyTemplate(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withAlpha(20)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined,
                              size: 16,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : colors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.what,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                size: 18,
                                color: theme.colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.how,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '推奨期間: ${t.suggestedPeriod}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Page 4: フォーム
  Widget _buildFormPage(ThemeData theme, AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '目標を具体化しよう',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('What（何を達成する？）', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextFormField(
              controller: _whatController,
              decoration: const InputDecoration(
                hintText: '例: TOEIC 800点を取る',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '必須項目です' : null,
            ),
            const SizedBox(height: 16),
            Text('When（いつまでに？）', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextFormField(
              controller: _whenController,
              decoration: const InputDecoration(
                hintText: '例: 2026年12月, 3ヶ月以内',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '必須項目です' : null,
            ),
            const SizedBox(height: 16),
            Text('How（どうやって？）', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextFormField(
              controller: _howController,
              decoration: const InputDecoration(
                hintText: '例: 毎日1時間の英語学習を継続する',
              ),
              maxLines: 3,
              minLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '必須項目です' : null,
            ),

            if (_selectedDream != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '紐づく夢: ${_selectedDream!.title}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
