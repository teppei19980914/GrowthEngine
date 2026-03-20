/// 夢の追加・編集ダイアログ.
library;

import 'package:flutter/material.dart';

import '../models/dream.dart';
import '../widgets/tutorial/tutorial_target_keys.dart';

/// DreamDialog の入力結果.
class DreamDialogResult {
  /// DreamDialogResultを作成する.
  const DreamDialogResult({
    required this.title,
    required this.description,
    required this.why,
    required this.category,
    this.deleteRequested = false,
  });

  /// 夢のタイトル.
  final String title;

  /// 夢の説明.
  final String description;

  /// なぜこの夢を叶えたいか.
  final String why;

  /// カテゴリ.
  final String category;

  /// 削除リクエスト.
  final bool deleteRequested;
}

/// 夢ダイアログを表示する.
///
/// [dream]が指定された場合は編集モード、nullの場合は新規作成モード.
Future<DreamDialogResult?> showDreamDialog(
  BuildContext context, {
  Dream? dream,
  String? initialTitle,
  String? initialDescription,
  String? initialWhy,
}) {
  return showDialog<DreamDialogResult>(
    context: context,
    builder: (_) => _DreamDialogContent(
      dream: dream,
      initialTitle: initialTitle,
      initialDescription: initialDescription,
      initialWhy: initialWhy,
    ),
  );
}

class _DreamDialogContent extends StatefulWidget {
  const _DreamDialogContent({
    this.dream,
    this.initialTitle,
    this.initialDescription,
    this.initialWhy,
  });

  final Dream? dream;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialWhy;

  @override
  State<_DreamDialogContent> createState() => _DreamDialogContentState();
}

class _DreamDialogContentState extends State<_DreamDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _whyController;
  late DreamCategory _selectedCategory;

  bool get _isEdit => widget.dream != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: widget.dream?.title ?? widget.initialTitle ?? '');
    _descriptionController = TextEditingController(
        text: widget.dream?.description ?? widget.initialDescription ?? '');
    _whyController = TextEditingController(
        text: widget.dream?.why ?? widget.initialWhy ?? '');
    _selectedCategory = widget.dream?.dreamCategory ?? DreamCategory.other;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      DreamDialogResult(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        why: _whyController.text.trim(),
        category: _selectedCategory.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEdit ? '夢を編集' : '新しい夢を追加'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // カテゴリ選択
                Text('カテゴリ', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DreamCategory.values.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withAlpha(40)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? cat.color
                                : theme.dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 16, color: cat.color),
                            const SizedBox(width: 4),
                            Text(
                              cat.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? cat.color
                                    : theme.textTheme.bodySmall?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('タイトル', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '例: 医者になる、世界一周する',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '必須項目です' : null,
                ),
                const SizedBox(height: 16),
                Text('説明', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: '例: 困っている人を助けられる医者になりたい',
                  ),
                  maxLines: 4,
                  minLines: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  'Why（なぜこの夢を叶えたいか）',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _whyController,
                  decoration: const InputDecoration(
                    hintText: '例: 幼い頃に医者に助けられた経験がある',
                  ),
                  maxLines: 3,
                  minLines: 2,
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
            child: const Text('削除'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          key: _isEdit ? null : TutorialTargetKeys.dreamDialogSubmit,
          onPressed: _submit,
          child: Text(_isEdit ? '更新' : '追加'),
        ),
      ],
    );
  }

  Future<void> _requestDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('夢を削除'),
        content: Text(
          '「${widget.dream!.title}」を削除しますか？\n'
          '紐づく目標・タスクも削除されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(
        context,
        const DreamDialogResult(
          title: '',
          description: '',
          why: '',
          category: 'other',
          deleteRequested: true,
        ),
      );
    }
  }
}
