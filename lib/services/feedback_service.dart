/// フィードバック送信・制限解除管理.
///
/// フィードバックのバリデーション、送信履歴管理、
/// 段階的な制限解除レベルの管理を行う.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// フィードバックカテゴリ.
enum FeedbackCategory {
  /// 改善要望.
  improvement('改善要望'),

  /// 不具合報告.
  bugReport('不具合報告'),

  /// 使いやすさ.
  usability('使いやすさ'),

  /// その他.
  other('その他');

  const FeedbackCategory(this.label);

  /// 表示用ラベル.
  final String label;
}

/// フィードバックのバリデーション結果.
class FeedbackValidation {
  const FeedbackValidation({required this.isValid, this.errorMessage});

  /// バリデーション成功.
  static const valid = FeedbackValidation(isValid: true);

  /// バリデーションが通ったか.
  final bool isValid;

  /// エラーメッセージ.
  final String? errorMessage;
}

/// フィードバック送信結果.
class FeedbackResult {
  const FeedbackResult({
    required this.success,
    required this.newLevel,
    this.errorMessage,
  });

  /// 送信成功か.
  final bool success;

  /// 新しい解除レベル.
  final int newLevel;

  /// エラーメッセージ.
  final String? errorMessage;
}

/// フィードバックの最低文字数.
const feedbackMinLength = 100;

/// 最大解除レベル.
const feedbackMaxLevel = 3;

const _levelKey = 'feedback_unlock_level';
const _historyKey = 'feedback_history';

/// フィードバック管理サービス.
class FeedbackService {
  /// FeedbackServiceを作成する.
  FeedbackService(this._prefs);

  final SharedPreferences _prefs;

  /// 現在の解除レベル（0-3）を取得する.
  int get unlockLevel => _prefs.getInt(_levelKey) ?? 0;

  /// 最大レベルに達しているか.
  bool get isMaxLevel => unlockLevel >= feedbackMaxLevel;

  /// 送信済みフィードバック数.
  int get feedbackCount => _getHistory().length;

  /// フィードバックテキストのバリデーション.
  FeedbackValidation validateFeedback(String text) {
    final trimmed = text.trim();

    if (trimmed.length < feedbackMinLength) {
      return FeedbackValidation(
        isValid: false,
        errorMessage: '${feedbackMinLength}文字以上入力してください'
            '（現在${trimmed.length}文字）',
      );
    }

    if (_isRepetitive(trimmed)) {
      return const FeedbackValidation(
        isValid: false,
        errorMessage: '同じ文字の繰り返しは無効です。具体的なご意見をお聞かせください',
      );
    }

    if (_isDuplicate(trimmed)) {
      return const FeedbackValidation(
        isValid: false,
        errorMessage: '以前と同じ内容です。別のご意見をお聞かせください',
      );
    }

    return FeedbackValidation.valid;
  }

  /// フィードバックを送信する.
  Future<FeedbackResult> submitFeedback({
    required FeedbackCategory category,
    required String text,
  }) async {
    final validation = validateFeedback(text);
    if (!validation.isValid) {
      return FeedbackResult(
        success: false,
        newLevel: unlockLevel,
        errorMessage: validation.errorMessage,
      );
    }

    // 履歴に保存
    final history = _getHistory();
    history.add(text.trim());
    await _prefs.setStringList(_historyKey, history);

    // レベルアップ
    final currentLevel = unlockLevel;
    if (currentLevel < feedbackMaxLevel) {
      final newLevel = currentLevel + 1;
      await _prefs.setInt(_levelKey, newLevel);
      return FeedbackResult(success: true, newLevel: newLevel);
    }

    return FeedbackResult(success: true, newLevel: currentLevel);
  }

  /// 同一文字の繰り返しを検出する.
  ///
  /// 1文字が80%以上を占める、またはユニーク文字が3種以下の場合 true.
  bool _isRepetitive(String text) {
    if (text.isEmpty) return false;

    final charCounts = <String, int>{};
    final chars = text.replaceAll(RegExp(r'\s'), '');
    if (chars.isEmpty) return true;

    for (final char in chars.split('')) {
      charCounts[char] = (charCounts[char] ?? 0) + 1;
    }

    final maxCount = charCounts.values.reduce((a, b) => a > b ? a : b);
    // 1文字が80%以上を占める場合（例: "あああ..."）
    if (maxCount / chars.length > 0.8) return true;
    // ユニーク文字が3種以下（例: "あいあいあい..."）
    if (charCounts.length <= 3 && chars.length >= feedbackMinLength) {
      return true;
    }
    return false;
  }

  /// 過去のフィードバックと重複していないか確認する.
  bool _isDuplicate(String text) {
    final history = _getHistory();
    final normalized = _normalize(text);
    return history.any((h) => _normalize(h) == normalized);
  }

  /// テキストを正規化する（空白除去・小文字化）.
  String _normalize(String text) {
    return text.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  List<String> _getHistory() {
    return _prefs.getStringList(_historyKey) ?? [];
  }
}
