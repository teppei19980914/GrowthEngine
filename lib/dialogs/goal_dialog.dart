/// 目標の追加・編集ダイアログ.
///
/// What, When, How フォームを表示し、
/// ユーザーに目標情報を入力させる.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    _selectedDreamId = (candidateId != null && dreamIds.contains(candidateId))
        ? candidateId
        : widget.dreams.firstOrNull?.id;

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
        dreamId: _selectedDreamId!,
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
      title: Text(_isEdit ? '目標を編集' : '新しい目標を追加'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dream — 紐づく夢
                Text(
                  '紐づく夢',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDreamId,
                  decoration: const InputDecoration(
                    hintText: '夢を選択してください',
                  ),
                  items: widget.dreams
                      .map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.title),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedDreamId = value);
                  },
                  validator: (v) =>
                      v == null || v.isEmpty ? '夢を選択してください' : null,
                ),
                const SizedBox(height: 16),

                // What — 何を目標とするか
                Text(
                  'What（何を目標とするか）',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _whatController,
                  decoration: const InputDecoration(
                    hintText: '例: TOEIC 900点を取得する',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '必須項目です' : null,
                ),
                const SizedBox(height: 16),

                // When — いつまでに達成するか
                Text(
                  'When（いつまでに達成するか）',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                SegmentedButton<WhenType>(
                  segments: const [
                    ButtonSegment(
                      value: WhenType.date,
                      label: Text('日付指定'),
                      icon: Icon(Icons.calendar_today, size: 16),
                    ),
                    ButtonSegment(
                      value: WhenType.period,
                      label: Text('期間指定'),
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
                        v == null || v.trim().isEmpty ? '日付を選択してください' : null,
                  )
                else
                  TextFormField(
                    controller: _whenTargetController,
                    decoration: const InputDecoration(
                      hintText: '例: 3ヶ月以内',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '期間を入力してください' : null,
                  ),
                const SizedBox(height: 16),

                // How — どうやって達成するか
                Text(
                  'How（どうやって達成するか）',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _howController,
                  decoration: const InputDecoration(
                    hintText: '例: 公式問題集を毎日1セット解く',
                  ),
                  maxLines: 3,
                  minLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '必須項目です' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          key: _isEdit ? null : TutorialTargetKeys.goalDialogSubmit,
          onPressed: _submit,
          child: Text(_isEdit ? '更新' : '追加'),
        ),
      ],
    );
  }
}
