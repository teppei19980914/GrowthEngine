/// お問い合わせ送信ダイアログ.
///
/// カテゴリ選択、メールアドレス入力、テキスト入力の
/// お問い合わせフォームを提供する.
library;

import 'package:flutter/material.dart';

import '../l10n/app_labels.dart';
import '../widgets/app_snackbar.dart';
import '../services/inquiry_service.dart';

/// お問い合わせダイアログを表示する.
///
/// 送信成功時は true を返す.
Future<bool> showInquiryDialog(
  BuildContext context,
  InquiryService inquiryService, {
  String? userKey,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _InquiryDialog(
      inquiryService: inquiryService,
      userKey: userKey,
    ),
  );
  return result ?? false;
}

class _InquiryDialog extends StatefulWidget {
  const _InquiryDialog({required this.inquiryService, this.userKey});

  final InquiryService inquiryService;
  final String? userKey;

  @override
  State<_InquiryDialog> createState() => _InquiryDialogState();
}

class _InquiryDialogState extends State<_InquiryDialog> {
  final _emailController = TextEditingController();
  final _textController = TextEditingController();
  InquiryCategory? _category;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textLength = _textController.text.trim().length;
    final remaining = inquiryMinLength - textLength;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      title: Row(
        children: [
          Icon(Icons.mail_outlined,
              size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text(AppLabels.inquiryTitle)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 説明
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business_center_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLabels.inquiryDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // カテゴリ選択
              Text(AppLabels.feedbackCategory, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<InquiryCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: AppLabels.feedbackSelectCategory,
                ),
                items: InquiryCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 16),

              // メールアドレス
              Text(AppLabels.inquiryEmail, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'example@mail.com',
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 16),

              // テキスト入力
              Row(
                children: [
                  Text(AppLabels.inquiryContent,
                      style: theme.textTheme.labelLarge),
                  const Spacer(),
                  Text(
                    remaining > 0 ? AppLabels.feedbackRemainingChars(remaining) : AppLabels.feedbackCharCount(textLength),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: remaining > 0
                          ? theme.colorScheme.error
                          : theme.hintColor,
                      fontWeight:
                          remaining > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: AppLabels.inquiryGuide,
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 8),

              // 注記
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      AppLabels.inquiryPrivacyNote,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 文字数プログレスバー
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (textLength / inquiryMinLength).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    textLength >= inquiryMinLength
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ),

              // エラーメッセージ
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text(AppLabels.btnCancel),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 18),
          label: Text(_submitting ? AppLabels.btnSending : AppLabels.btnSend),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_category == null) {
      setState(() => _errorMessage = AppLabels.inquiryCategoryRequired);
      return;
    }

    final emailError =
        widget.inquiryService.validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }

    final textError =
        widget.inquiryService.validateText(_textController.text);
    if (textError != null) {
      setState(() => _errorMessage = textError);
      return;
    }

    setState(() => _submitting = true);

    final result = await widget.inquiryService.submit(
      category: _category!,
      email: _emailController.text,
      text: _textController.text,
      userKey: widget.userKey,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, AppLabels.inquirySuccess);
    } else {
      setState(() {
        _submitting = false;
        _errorMessage = result.errorMessage;
      });
    }
  }
}
