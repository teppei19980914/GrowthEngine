import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart';
import 'package:yume_log/models/notification.dart';
import 'package:yume_log/services/notification_service.dart';

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late NotificationService service;

  setUp(() {
    db = _createDb();
    service = NotificationService(notificationDao: db.notificationDao);
  });

  tearDown(() => db.close());

  group('NotificationService', () {
    group('loadSystemNotificationsFromJson', () {
      test('JSON文字列から通知を読み込む', () async {
        const jsonStr =
            '[{"dedup_key":"sys:v1","title":"お知らせ","message":"テスト"}]';
        final created =
            await service.loadSystemNotificationsFromJson(jsonStr);
        expect(created.length, 1);
        expect(created.first.notificationType, NotificationType.system);
        expect(created.first.title, 'お知らせ');
      });

      test('重複キーはスキップする', () async {
        const jsonStr =
            '[{"dedup_key":"sys:v1","title":"A","message":"B"}]';
        await service.loadSystemNotificationsFromJson(jsonStr);
        final second =
            await service.loadSystemNotificationsFromJson(jsonStr);
        expect(second, isEmpty);
      });

      test('空のdedup_keyはスキップする', () async {
        const jsonStr =
            '[{"dedup_key":"","title":"A","message":"B"}]';
        final created =
            await service.loadSystemNotificationsFromJson(jsonStr);
        expect(created, isEmpty);
      });

      test('不正なJSONで空リスト', () async {
        final created =
            await service.loadSystemNotificationsFromJson('invalid');
        expect(created, isEmpty);
      });
    });
  });
}
