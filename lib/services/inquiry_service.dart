/// お問い合わせ送信管理.
///
/// 案件相談・開発依頼等のビジネスお問い合わせを管理する.
/// Google Apps Script 経由でスプレッドシート記録・メール通知を行う.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'feedback_service.dart' show feedbackEndpointUrl;

/// お問い合わせカテゴリ.
enum InquiryCategory {
  /// 追加開発の相談.
  development('追加開発の相談'),

  /// 案件のご依頼.
  commission('案件のご依頼'),

  /// その他のお問い合わせ.
  other('その他のお問い合わせ');

  const InquiryCategory(this.label);

  /// 表示用ラベル.
  final String label;
}

/// お問い合わせ送信結果.
class InquiryResult {
  const InquiryResult({required this.success, this.errorMessage});

  /// 送信成功か.
  final bool success;

  /// エラーメッセージ.
  final String? errorMessage;
}

/// お問い合わせの最低文字数.
const inquiryMinLength = 30;

/// お問い合わせ管理サービス.
class InquiryService {
  /// InquiryServiceを作成する.
  InquiryService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// お問い合わせテキストのバリデーション.
  String? validateText(String text) {
    final trimmed = text.trim();
    if (trimmed.length < inquiryMinLength) {
      return '$inquiryMinLength文字以上入力してください'
          '（現在${trimmed.length}文字）';
    }
    return null;
  }

  /// メールアドレスのバリデーション.
  String? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return '有効なメールアドレスを入力してください';
    }
    return null;
  }

  /// お問い合わせを送信する.
  Future<InquiryResult> submit({
    required InquiryCategory category,
    required String email,
    required String text,
    String? userKey,
  }) async {
    final emailError = validateEmail(email);
    if (emailError != null) {
      return InquiryResult(success: false, errorMessage: emailError);
    }

    final textError = validateText(text);
    if (textError != null) {
      return InquiryResult(success: false, errorMessage: textError);
    }

    await _sendToRemote(
      category: category,
      email: email.trim(),
      text: text.trim(),
      userKey: userKey,
    );

    return const InquiryResult(success: true);
  }

  /// Google Apps Script にお問い合わせをPOST送信する.
  Future<void> _sendToRemote({
    required InquiryCategory category,
    required String email,
    required String text,
    String? userKey,
  }) async {
    if (feedbackEndpointUrl.isEmpty) return;
    try {
      await _httpClient.post(
        Uri.parse(feedbackEndpointUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'type': 'inquiry',
          'category': category.label,
          'email': email,
          'text': text,
          'userKey': userKey ?? '',
        }),
      );
    } on Exception {
      // 通信エラーは無視
    }
  }
}
