import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/services/invite_service.dart';

void main() {
  group('InviteService', () {
    late SharedPreferences prefs;
    late InviteService service;

    Future<InviteService> createService([
      Map<String, Object> initialValues = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(initialValues);
      prefs = await SharedPreferences.getInstance();
      return InviteService(prefs);
    }

    group('初期状態', () {
      test('招待コードは未保存', () async {
        service = await createService();
        expect(service.savedCode, isNull);
      });

      test('ステータスは非アクティブ', () async {
        service = await createService();
        final status = service.getStatus();
        expect(status.isActive, isFalse);
        expect(status.remainingDays, isNull);
      });
    });

    group('activate', () {
      test('招待コードを有効化できる', () async {
        service = await createService();
        await service.activate(
          'TEST-CODE',
          const InviteConfig(name: 'テストユーザー', durationDays: 60),
        );

        expect(service.savedCode, 'TEST-CODE');
        final status = service.getStatus();
        expect(status.isActive, isTrue);
        expect(status.name, 'テストユーザー');
        expect(status.remainingDays, 60);
      });

      test('同じコードで再有効化しても日時が更新されない', () async {
        service = await createService({
          'invite_code': 'TEST-CODE',
          'invite_activated_at':
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .millisecondsSinceEpoch,
          'invite_name': 'テストユーザー',
          'invite_duration_days': 60,
        });

        await service.activate(
          'TEST-CODE',
          const InviteConfig(name: 'テストユーザー', durationDays: 60),
        );

        final status = service.getStatus();
        // 30日前に有効化済みなので残り約30日
        expect(status.isActive, isTrue);
        expect(status.remainingDays, closeTo(30, 1));
      });
    });

    group('getStatus', () {
      test('有効期間内はアクティブ', () async {
        service = await createService({
          'invite_code': 'CODE-1',
          'invite_activated_at':
              DateTime.now().millisecondsSinceEpoch,
          'invite_name': '田中太郎',
          'invite_duration_days': 60,
        });

        final status = service.getStatus();
        expect(status.isActive, isTrue);
        expect(status.name, '田中太郎');
        expect(status.remainingDays, 60);
        expect(status.expiredAt, isNull);
      });

      test('有効期間超過で非アクティブ', () async {
        service = await createService({
          'invite_code': 'CODE-2',
          'invite_activated_at':
              DateTime.now()
                  .subtract(const Duration(days: 61))
                  .millisecondsSinceEpoch,
          'invite_name': '山田花子',
          'invite_duration_days': 60,
        });

        final status = service.getStatus();
        expect(status.isActive, isFalse);
        expect(status.remainingDays, isNull);
        expect(status.expiredAt, isNotNull);
      });

      test('カスタム有効期間が反映される', () async {
        service = await createService({
          'invite_code': 'CODE-3',
          'invite_activated_at':
              DateTime.now().millisecondsSinceEpoch,
          'invite_name': 'テスト',
          'invite_duration_days': 90,
        });

        final status = service.getStatus();
        expect(status.isActive, isTrue);
        expect(status.remainingDays, 90);
      });
    });

    group('InviteConfig', () {
      test('JSONから生成できる', () {
        final config = InviteConfig.fromJson({
          'name': 'テスト',
          'durationDays': 90,
        });
        expect(config.name, 'テスト');
        expect(config.durationDays, 90);
      });

      test('デフォルト値が適用される', () {
        final config = InviteConfig.fromJson({});
        expect(config.name, '');
        expect(config.durationDays, 60);
      });
    });
  });
}
