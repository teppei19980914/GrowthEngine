/// 目標の追加・編集ダイアログ.
///
/// What, When, How フォームを表示し、
/// ユーザーに目標情報を入力させる.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_labels.dart';
import '../models/dream.dart';
import '../models/goal.dart';
import '../widgets/tutorial/tutorial_target_keys.dart';

/// GoalDialog の入力結果.
class GoalDialogResult {
  /// GoalDialogResultを作成する.
  const GoalDialogResult({
    required this.dreamId,
    required this.what,
    required this.whenType,
    required this.whenTarget,
    required this.how,
    this.deleteRequested = false,
  });

  /// 紐づく夢のID.
  final String dreamId;

  /// 何を目標とするか.
  final String what;

  /// When指定タイプ.
  final WhenType whenType;

  /// いつまでに.
  final String whenTarget;

  /// どうやって達成するか.
  final String how;

  /// 削除リクエスト.
  final bool deleteRequested;
}

/// 目標ダイアログを表示する.
///
/// [goal]が指定された場合は編集モード、nullの場合は新規作成モード.
/// [dreams]は紐づける夢の選択肢.
/// [initialDreamId]は新規作成時のデフォルト夢ID.
/// 結果は[GoalDialogResult]として返される（キャンセル時はnull）.
Future<GoalDialogResult?> showGoalDialog(
  BuildContext context, {
  Goal? goal,
  required List<Dream> dreams,
  String? initialDreamId,
}) {
  return showDialog<GoalDialogResult>(
    context: context,
    builder: (_) => _GoalDialogContent(
      goal: goal,
      dreams: dreams,
      initialDreamId: initialDreamId,
    ),
  );
}

class _GoalDialogContent extends StatefulWidget {
  const _GoalDialogContent({
    this.goal,
    required this.dreams,
    this.initialDreamId,
  });

  final Goal? goal;
  final List<Dream> dreams;
  final String? initialDreamId;

  @override
  State<_GoalDialogContent> createState() => _GoalDialogContentState();
}

class _GoalDialogContentState extends State<_GoalDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _whatController;
  late final TextEditingController _whenTargetController;
  late final TextEditingController _howController;
  late WhenType _whenType;
  late String? _selectedDreamId;
  DateTime? _selectedDate;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _whatController = TextEditingController(text: goal?.what ?? '');
    _howController = TextEditingController(text: goal?.how ?? '');
    _whenType = goal?.whenType ?? WhenType.date;
    final dreamIds = widget.dreams.map((d) => d.id).toSet();
    final candidateId = goal?.dreamId ?? widget.initialDreamId;
    if (candidateId != null && candidateId.isNotEmpty && dreamIds.contains(candidateId)) {
      _selectedDreamId = candidateId;
    } else if (candidateId != null && candidateId.isEmpty) {
      // 独立した目標（夢に紐づかない）
      _selectedDreamId = '';
    } else {
      // デフォルト: 夢がある場合は最初の夢、ない場合は空文字（独立目標）
      _selectedDreamId = widget.dreams.firstOrNull?.id ?? '';
    }

    if (goal != null && goal.whenType == WhenType.date) {
      _selectedDate = goal.getTargetDate();
      _whenTargetController = TextEditingController(
        text: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : goal.whenTarget,
      );
    } else {
      _whenTargetController = TextEditingController(
        text: goal?.whenTarget ?? '',
      );
    }
  }

  @override
  void dispose() {
    _whatController.dispose();
    _whenTargetController.dispose();
    _howController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 25)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _whenTargetController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      GoalDialogResult(
        dreamId: _selectedDreamId ?? '',
        what: _whatController.text.trim(),
        whenType: _whenType,
        whenTarget: _whenTargetController.text.trim(),
        how: _howController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEdit ? AppLabels.goalDialogEdit : AppLabels.goalDialogAdd),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dream — 紐づく夢（任意）
                Text(
                  AppLabels.goalLinkedDream,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDreamId,
                  decoration: const InputDecoration(
                    hintText: AppLabels.goalSelectDream,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text(AppLabels.goalIndependent),
                    ),
                    ...widget.dreams.map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.title),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDreamId = value);
                  },
                ),
                const SizedBox(height: 16),

                // What — 何を目標とするか
                Text(
                  AppLabels.goalWhat,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _whatController,
                  decoration: const InputDecoration(
                    hintText: AppLabels.goalHintWhat,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? AppLabels.validRequired : null,
                ),
                const SizedBox(height: 16),

                // When — いつまでに達成するか
                Text(
                  AppLabels.goalWhen,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                SegmentedButton<WhenType>(
                  segments: const [
                    ButtonSegment(
                      value: WhenType.date,
                      label: Text(AppLabels.goalDateType),
                      icon: Icon(Icons.calendar_today, size: 16),
                    ),
                    ButtonSegment(
                      value: WhenType.period,
                      label: Text(AppLabels.goalPeriodType),
                      icon: Icon(Icons.schedule, size: 16),
                    ),
                  ],
                  selected: {_whenType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _whenType = selection.first;
                      _whenTargetController.clear();
                      _selectedDate = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (_whenType == WhenType.date)
                  TextFormField(
                    controller: _whenTargetController,
                    decoration: InputDecoration(
                      hintText: 'yyyy-MM-dd',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: _pickDate,
                      ),
                    ),
                    readOnly: true,
                    onTap: _pickDate,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? AppLabels.validSelectDate : null,
                  )
                else
                  TextFormField(
                    controller: _whenTargetController,
                    decoration: const InputDecoration(
                      hintText: AppLabels.goalHintWhen,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? AppLabels.validEnterPeriod : null,
                  ),
                const SizedBox(height: 16),

                // How — どうやって達成するか
                Text(
                  AppLabels.goalHow,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _howController,
                  decoration: const InputDecoration(
                    hintText: AppLabels.goalHintHow,
                  ),
                  maxLines: 5,
                  minLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? AppLabels.validRequired : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isEdit)
          TextButton(
            onPressed: _requestDelete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppLabels.btnDelete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppLabels.btnCancel),
        ),
        ElevatedButton(
          key: _isEdit ? null : TutorialTargetKeys.goalDialogSubmit,
          onPressed: _submit,
          child: Text(_isEdit ? AppLabels.btnUpdate : AppLabels.btnAdd),
        ),
      ],
    );
  }

  Future<void> _requestDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppLabels.goalDialogDelete),
        content: Text(
          AppLabels.goalDeleteConfirm(widget.goal!.what),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppLabels.btnCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppLabels.btnDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(
        context,
        GoalDialogResult(
          dreamId: '',
          what: '',
          whenType: WhenType.date,
          whenTarget: '',
          how: '',
          deleteRequested: true,
        ),
      );
    }
  }
}
