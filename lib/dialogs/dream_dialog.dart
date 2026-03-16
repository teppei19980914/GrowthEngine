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
  });

  /// 夢のタイトル.
  final String title;

  /// 夢の説明.
  final String description;

  /// なぜこの夢を叶えたいか.
  final String why;
}

/// 夢ダイアログを表示する.
///
/// [dream]が指定された場合は編集モード、nullの場合は新規作成モード.
Future<DreamDialogResult?> showDreamDialog(
  BuildContext context, {
  Dream? dream,
}) {
  return showDialog<DreamDialogResult>(
    context: context,
    builder: (_) => _DreamDialogContent(dream: dream),
  );
}

class _DreamDialogContent extends StatefulWidget {
  const _DreamDialogContent({this.dream});

  final Dream? dream;

  @override
  State<_DreamDialogContent> createState() => _DreamDialogContentState();
}

class _DreamDialogContentState extends State<_DreamDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _whyController;

  bool get _isEdit => widget.dream != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.dream?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.dream?.description ?? '');
    _whyController = TextEditingController(text: widget.dream?.why ?? '');
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
                Text(
                  'タイトル',
                  style: theme.textTheme.titleSmall,
                ),
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
                Text(
                  '説明',
                  style: theme.textTheme.titleSmall,
                ),
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
}
