/// タスク発見ガイドダイアログ.
///
/// 目標の選択→思考の整理→テンプレート提案→タスク作成の流れで
/// ユーザーのタスク設定をサポートする.
library;

import 'package:flutter/material.dart';

import '../data/task_templates.dart';
import '../models/goal.dart';
import '../theme/app_theme.dart';

/// タスク発見ガイドの結果.
class TaskDiscoveryResult {
  /// TaskDiscoveryResultを作成する.
  const TaskDiscoveryResult({
    required this.goalId,
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  /// 紐づく目標のID.
  final String goalId;

  /// タスク名.
  final String title;

  /// 開始日.
  final DateTime startDate;

  /// 終了日.
  final DateTime endDate;
}

/// タスク発見ガイドダイアログを表示する.
Future<TaskDiscoveryResult?> showTaskDiscoveryDialog(
  BuildContext context, {
  required List<Goal> goals,
  required Map<String, String> goalDreamCategoryMap,
}) {
  return showGeneralDialog<TaskDiscoveryResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    barrierLabel: 'TaskDiscovery',
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    pageBuilder: (context, animation, secondaryAnimation) =>
        _TaskDiscoveryDialog(
      goals: goals,
      goalDreamCategoryMap: goalDreamCategoryMap,
    ),
  );
}

class _TaskDiscoveryDialog extends StatefulWidget {
  const _TaskDiscoveryDialog({
    required this.goals,
    required this.goalDreamCategoryMap,
  });
  final List<Goal> goals;

  /// GoalID → DreamCategory value のマップ.
  final Map<String, String> goalDreamCategoryMap;

  @override
  State<_TaskDiscoveryDialog> createState() => _TaskDiscoveryDialogState();
}

class _TaskDiscoveryDialogState extends State<_TaskDiscoveryDialog> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1: 目標の選択
  Goal? _selectedGoal;

  // Page 2: 思考の整理（質問への回答）
  final List<Set<int>> _selectedHints = [
    for (var i = 0; i < taskGuideQuestions.length; i++) <int>{},
  ];

  // Page 3: テンプレート選択
  TaskTemplate? _selectedTemplate;

  // Page 4: フォーム
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
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
        return _selectedGoal != null;
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

  List<TaskTemplate> get _availableTemplates {
    if (_selectedGoal != null) {
      final cat =
          widget.goalDreamCategoryMap[_selectedGoal!.id] ?? '';
      if (cat.isNotEmpty) {
        return taskTemplatesByGoalCategory[cat] ?? genericTaskTemplates;
      }
    }
    return genericTaskTemplates;
  }

  void _applyTemplate(TaskTemplate template) {
    setState(() => _selectedTemplate = template);
    _titleController.text = template.title;
    final now = DateTime.now();
    _startDate = now;
    _endDate = now.add(Duration(days: template.suggestedDurationDays));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TaskDiscoveryResult(
        goalId: _selectedGoal?.id ?? '',
        title: _titleController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart ? DateTime(2020) : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = picked;
      }
    });
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
                    Icon(Icons.task_alt,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'タスク発見ガイド',
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
                    _buildGoalSelectionPage(theme, colors),
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
                        child: const Text('タスクを作成'),
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

  // Page 1: 目標の選択
  Widget _buildGoalSelectionPage(ThemeData theme, AppColors colors) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'どの目標に向けたタスクですか？',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '目標を達成するための具体的な行動を考えましょう。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          if (widget.goals.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.textMuted.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline,
                      color: colors.textMuted, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '目標がまだありません。\n先に目標を作成してください。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // 目標のリスト
          ...widget.goals.map((goal) {
            final isSelected = _selectedGoal?.id == goal.id;
            final goalColor = _parseColor(goal.color);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedGoal = goal;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? goalColor.withAlpha(25)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? goalColor : theme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 32,
                        decoration: BoxDecoration(
                          color: goalColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.what,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (goal.how.isNotEmpty)
                              Text(
                                goal.how,
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
                        Icon(Icons.check_circle, color: goalColor),
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

  // Page 2: 思考の整理
  Widget _buildQuestionsPage(ThemeData theme, AppColors colors) {
    final goalTitle = _selectedGoal?.what;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goalTitle != null) ...[
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
                      '「$goalTitle」を達成するための行動を考えましょう',
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

          ...List.generate(taskGuideQuestions.length, (qi) {
            final q = taskGuideQuestions[qi];
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
      physics: const ClampingScrollPhysics(),
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
                          Icon(Icons.task_alt,
                              size: 16,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : colors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.title,
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
                        t.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '推奨期間: ${t.suggestedDurationDays}日間',
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
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'タスクを具体化しよう',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('タスク名', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '例: 参考書を1章読む',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '必須項目です' : null,
            ),
            const SizedBox(height: 16),
            Text('開始日', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _pickDate(isStart: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(_startDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Icon(Icons.calendar_today,
                        size: 18, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('終了日', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _pickDate(isStart: false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(_endDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Icon(Icons.calendar_today,
                        size: 18, color: colors.textSecondary),
                  ],
                ),
              ),
            ),

            if (_selectedGoal != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '紐づく目標: ${_selectedGoal!.what}',
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

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }
}
