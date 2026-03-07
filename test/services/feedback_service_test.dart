import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/services/feedback_service.dart';

void main() {
  late FeedbackService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<FeedbackService> createService([
    Map<String, Object> initialValues = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    return FeedbackService(prefs);
  }

  group('validateFeedback', () {
    test('100文字未満は無効', () async {
      service = await createService();
      final result = service.validateFeedback('短いテキスト');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('100文字以上'));
    });

    test('100文字以上で有効', () async {
      service = await createService();
      final text = 'あ' * 100;
      final result = service.validateFeedback(text);
      // 100文字の同一文字は繰り返し検出に引っかかる
      expect(result.isValid, isFalse);
    });

    test('具体的な100文字以上のテキストは有効', () async {
      service = await createService();
      final text =
          'このアプリは学習管理にとても役立っています。特にガントチャート機能が便利です。'
          '改善点としては、カレンダー表示があるとさらに使いやすくなると思います。'
          'また、通知機能の時間指定ができると嬉しいです。全体的に満足しています。';
      final result = service.validateFeedback(text);
      expect(result.isValid, isTrue);
    });

    test('同一文字の繰り返しは無効', () async {
      service = await createService();
      final text = 'あ' * 150;
      final result = service.validateFeedback(text);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('同じ文字の繰り返し'));
    });

    test('過去と同じテキストは無効', () async {
      service = await createService();
      final text =
          'このアプリは学習管理にとても役立っています。特にガントチャート機能が便利です。'
          '改善点としては、カレンダー表示があるとさらに使いやすくなると思います。'
          'また、通知機能の時間指定ができると嬉しいです。全体的に満足しています。';

      // 1回目は成功
      await service.submitFeedback(
        category: FeedbackCategory.improvement,
        text: text,
      );

      // 2回目は重複
      final result = service.validateFeedback(text);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('以前と同じ'));
    });

    test('空白のみのテキストは文字数不足', () async {
      service = await createService();
      final text = '   ' * 50;
      final result = service.validateFeedback(text);
      expect(result.isValid, isFalse);
    });
  });

  group('submitFeedback', () {
    test('成功時にレベルが上がる', () async {
      service = await createService();
      expect(service.unlockLevel, 0);

      final text =
          'このアプリは学習管理にとても役立っています。特にガントチャート機能が便利です。'
          '改善点としては、カレンダー表示があるとさらに使いやすくなると思います。'
          'また、通知機能の時間指定ができると嬉しいです。全体的に満足しています。';

      final result = await service.submitFeedback(
        category: FeedbackCategory.improvement,
        text: text,
      );

      expect(result.success, isTrue);
      expect(result.newLevel, 1);
      expect(service.unlockLevel, 1);
    });

    test('バリデーション失敗時はレベルが変わらない', () async {
      service = await createService();
      final result = await service.submitFeedback(
        category: FeedbackCategory.improvement,
        text: '短い',
      );

      expect(result.success, isFalse);
      expect(service.unlockLevel, 0);
    });

    test('フィードバック数がカウントされる', () async {
      service = await createService();
      expect(service.feedbackCount, 0);

      final text1 =
          'このアプリは学習管理にとても役立っています。特にガントチャート機能が便利です。'
          '改善点としては、カレンダー表示があるとさらに使いやすくなると思います。'
          'また、通知機能の時間指定ができると嬉しいです。全体的に満足しています。';

      await service.submitFeedback(
        category: FeedbackCategory.improvement,
        text: text1,
      );
      expect(service.feedbackCount, 1);
    });
  });

  group('unlockLevel', () {
    test('初期レベルは0', () async {
      service = await createService();
      expect(service.unlockLevel, 0);
      expect(service.isMaxLevel, isFalse);
    });

    test('レベル3で最大', () async {
      service = await createService({
        'feedback_unlock_level': 3,
      });
      expect(service.unlockLevel, 3);
      expect(service.isMaxLevel, isTrue);
    });
  });

  group('_isRepetitive', () {
    test('多様な文字を含むテキストは繰り返しでない', () async {
      service = await createService();
      final text =
          'アプリの使い勝手について感想を述べます。UIデザインが洗練されていて使いやすいです。'
          'データ管理機能が充実しています。改善点としては検索機能の追加を希望します。'
          'タスク管理やガントチャートの表示も分かりやすく、全体的に満足度が高いアプリだと感じました。';
      final result = service.validateFeedback(text);
      expect(result.isValid, isTrue);
    });
  });
}
