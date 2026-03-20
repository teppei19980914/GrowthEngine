/// 夢発見ガイドダイアログ.
///
/// 質問→カテゴリ選択→テンプレート提案→夢作成の4ステップで
/// ユーザーの夢の言語化をサポートする.
library;

import 'package:flutter/material.dart';

import '../data/dream_templates.dart';
import '../theme/app_theme.dart';

/// 夢発見ガイドの結果.
class DreamDiscoveryResult {
  /// DreamDiscoveryResultを作成する.
  const DreamDiscoveryResult({
    required this.title,
    required this.description,
    required this.why,
    this.categoryKey,
  });

  /// 夢のタイトル.
  final String title;

  /// ガイドで選択されたカテゴリキー（dream_templates.dartのDreamCategory.name）.
  final String? categoryKey;

  /// 説明.
  final String description;

  /// Why.
  final String why;
}

/// 夢発見ガイドダイアログを表示する.
Future<DreamDiscoveryResult?> showDreamDiscoveryDialog(
  BuildContext context,
) {
  return showGeneralDialog<DreamDiscoveryResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    barrierLabel: 'DreamDiscovery',
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    pageBuilder: (context, animation, secondaryAnimation) =>
        const _DreamDiscoveryDialog(),
  );
}

class _DreamDiscoveryDialog extends StatefulWidget {
  const _DreamDiscoveryDialog();

  @override
  State<_DreamDiscoveryDialog> createState() => _DreamDiscoveryDialogState();
}

class _DreamDiscoveryDialogState extends State<_DreamDiscoveryDialog> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1: 質問への回答
  final List<Set<int>> _selectedAnswers = [
    for (var i = 0; i < discoveryQuestions.length; i++) <int>{},
  ];

  // Page 2: 選択カテゴリ
  DreamCategory? _selectedCategory;

  // Page 3: 選択テンプレート
  DreamTemplate? _selectedTemplate;

  // Page 4: フォーム
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _whyController = TextEditingController();

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      DreamDiscoveryResult(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        why: _whyController.text.trim(),
        categoryKey: _selectedCategory?.name,
      ),
    );
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _selectedAnswers.any((s) => s.isNotEmpty);
      case 1:
        return _selectedCategory != null;
      case 2:
        return true; // テンプレート選択 or 自分で入力
      default:
        return true;
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
        horizontal: isSmall ? 12 : 40,
        vertical: isSmall ? 16 : 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: isSmall ? screenSize.height * 0.9 : 640,
        ),
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.explore, color: colors.accent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'やりたいこと発見ガイド',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ページコンテンツ
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildQuestionsPage(theme, colors),
                  _buildCategoryPage(theme, colors),
                  _buildTemplatePage(theme, colors),
                  _buildFormPage(theme, colors),
                ],
              ),
            ),

            // インジケーター + ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  // ステップインジケーター
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
                  const SizedBox(height: 16),

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
                        ),
                      const Spacer(),
                      if (_currentPage < _totalPages - 1)
                        FilledButton(
                          onPressed: _canProceed ? _nextPage : null,
                          child: const Text('次へ'),
                        )
                      else
                        FilledButton(
                          onPressed: _submit,
                          child: const Text('夢を作成'),
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

  // ── Page 1: 質問 ──

  Widget _buildQuestionsPage(ThemeData theme, AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'いくつかの質問に答えてみましょう',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          for (var qi = 0; qi < discoveryQuestions.length; qi++) ...[
            if (qi > 0) const SizedBox(height: 20),
            Text(
              discoveryQuestions[qi].question,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (var oi = 0;
                    oi < discoveryQuestions[qi].options.length;
                    oi++)
                  FilterChip(
                    label: Text(discoveryQuestions[qi].options[oi].label),
                    selected: _selectedAnswers[qi].contains(oi),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAnswers[qi].add(oi);
                        } else {
                          _selectedAnswers[qi].remove(oi);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Page 2: カテゴリ選択 ──

  Widget _buildCategoryPage(ThemeData theme, AppColors colors) {
    final scores = calculateCategoryScores(_selectedAnswers);
    final sorted = sortedCategories(scores);
    final topScore = scores.values.fold(0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'あなたの回答から、興味のある分野が見えてきました。\n'
            '気になるカテゴリを選んでください。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          for (final category in sorted) ...[
            _CategoryCard(
              category: category,
              score: scores[category] ?? 0,
              isRecommended:
                  topScore > 0 && (scores[category] ?? 0) == topScore,
              isSelected: _selectedCategory == category,
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  // テンプレート選択をリセット
                  _selectedTemplate = null;
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // ── Page 3: テンプレート提案 ──

  Widget _buildTemplatePage(ThemeData theme, AppColors colors) {
    final category = _selectedCategory;
    if (category == null) {
      return Center(
        child: Text('カテゴリを選択してください',
            style: TextStyle(color: colors.textMuted)),
      );
    }

    final templates = dreamTemplates[category] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, color: category.color, size: 20),
              const SizedBox(width: 8),
              Text(
                '${category.label}の夢テンプレート',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '気になるものを選ぶか、自分で入力もできます。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          for (final template in templates) ...[
            _TemplateCard(
              template: template,
              isSelected: _selectedTemplate == template,
              color: category.color,
              onTap: () {
                setState(() {
                  _selectedTemplate = template;
                  _titleController.text = template.title;
                  _descriptionController.text = template.description;
                  _whyController.text = template.suggestedWhy;
                });
              },
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedTemplate = null;
                _titleController.clear();
                _descriptionController.clear();
                _whyController.clear();
              });
              _nextPage();
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('自分で入力する'),
          ),
        ],
      ),
    );
  }

  // ── Page 4: 夢の作成フォーム ──

  Widget _buildFormPage(ThemeData theme, AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'あなたの夢を言葉にしましょう',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text('タイトル', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '例: 英語を話せるようになる',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '必須項目です' : null,
            ),
            const SizedBox(height: 16),
            Text('説明（任意）', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: '例: 日常会話レベルの英語力を身につける',
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 16),
            Text('Why ── なぜ実現したいか（任意）',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextFormField(
              controller: _whyController,
              decoration: const InputDecoration(
                hintText: '例: 世界中の人と話せるようになりたいから',
              ),
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// カテゴリ選択カード.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.score,
    required this.isRecommended,
    required this.isSelected,
    required this.onTap,
  });

  final DreamCategory category;
  final int score;
  final bool isRecommended;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? category.color.withAlpha(30)
          : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? category.color : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isRecommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: category.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'おすすめ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: category.color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// テンプレート選択カード.
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final DreamTemplate template;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? color.withAlpha(20) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
