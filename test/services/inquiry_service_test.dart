import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yume_hashi/services/inquiry_service.dart';

void main() {
  group('InquiryService', () {
    late InquiryService service;

    setUp(() {
      final mockClient = MockClient((_) async => http.Response('ok', 200));
      service = InquiryService(httpClient: mockClient);
    });

    group('validateEmail', () {
      test('空文字はエラー', () {
        expect(service.validateEmail(''), isNotNull);
      });

      test('不正なメールアドレスはエラー', () {
        expect(service.validateEmail('invalid'), isNotNull);
        expect(service.validateEmail('a@'), isNotNull);
        expect(service.validateEmail('@b.com'), isNotNull);
      });

      test('正しいメールアドレスはnull', () {
        expect(service.validateEmail('test@example.com'), isNull);
        expect(service.validateEmail('user@mail.co.jp'), isNull);
      });
    });

    group('validateText', () {
      test('短いテキストはエラー', () {
        expect(service.validateText('短い'), isNotNull);
      });

      test('十分な長さのテキストはnull', () {
        final text = 'あ' * inquiryMinLength;
        expect(service.validateText(text), isNull);
      });
    });

    group('submit', () {
      test('バリデーション成功時はsuccess', () async {
        final text = 'テスト問い合わせ内容です。開発のご相談をしたいです。追加機能についてお伺いしたいことがあります。';
        final result = await service.submit(
          category: InquiryCategory.development,
          email: 'test@example.com',
          text: text,
        );
        expect(result.success, isTrue);
      });

      test('メールアドレスが不正な場合は失敗', () async {
        final text = 'あ' * inquiryMinLength;
        final result = await service.submit(
          category: InquiryCategory.development,
          email: 'invalid',
          text: text,
        );
        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
      });

      test('テキストが短い場合は失敗', () async {
        final result = await service.submit(
          category: InquiryCategory.other,
          email: 'test@example.com',
          text: '短い',
        );
        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
      });
    });

    group('InquiryCategory', () {
      test('全カテゴリにラベルがある', () {
        for (final category in InquiryCategory.values) {
          expect(category.label, isNotEmpty);
        }
      });

      test('カテゴリは3種類', () {
        expect(InquiryCategory.values.length, 3);
      });
    });
  });
}
