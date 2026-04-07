import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/models/notification.dart';
import 'package:yume_hashi/services/notification_service.dart';

void main() {
  late AppDatabase db;
  late NotificationService service;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    service = NotificationService(notificationDao: db.notificationDao);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => db.close());

  group('NotificationService', () {
    group('syncSystemNotificationsFromJson', () {
      test('JSON文字列から通知を同期する', () async {
        const jsonStr =
            '[{"dedup_key":"sys:v1","title":"お知らせ","message":"テスト"}]';
        final result =
            await service.syncSystemNotificationsFromJson(jsonStr);
        expect(result.notifications.length, 1);
        expect(result.notifications.first.notificationType,
            NotificationType.system);
        expect(result.notifications.first.title, 'お知らせ');
      });

      test('再同期で既存の通知は保持され新規のみ追加される', () async {
        const jsonStr1 =
            '[{"dedup_key":"sys:v1","title":"旧お知らせ","message":"旧"}]';
        await service.syncSystemNotificationsFromJson(jsonStr1);

        const jsonStr2 =
            '[{"dedup_key":"sys:v1","title":"旧お知らせ","message":"旧"},'
            '{"dedup_key":"sys:v2","title":"新お知らせ","message":"新"}]';
        final result =
            await service.syncSystemNotificationsFromJson(jsonStr2);

        // 新規のsys:v2のみ追加される
        expect(result.notifications.length, 1);
        expect(result.notifications.first.title, '新お知らせ');

        final all = await service.getAllNotifications();
        final systemNotifs =
            all.where((n) => n.notificationType == NotificationType.system);
        expect(systemNotifs.length, 2);
      });

      test('空JSONで再同期するとシステム通知は全て削除される', () async {
        const jsonStr =
            '[{"dedup_key":"sys:v1","title":"A","message":"B"}]';
        await service.syncSystemNotificationsFromJson(jsonStr);

        await service.syncSystemNotificationsFromJson('[]');

        final all = await service.getAllNotifications();
        final systemNotifs =
            all.where((n) => n.notificationType == NotificationType.system);
        expect(systemNotifs, isEmpty);
      });

      test('JSON から削除されたエントリは受信ボックスからも除去される', () async {
        // 1回目: 2件同期
        const jsonStr1 = '['
            '{"dedup_key":"release:1.0.0","title":"v1.0.0","message":"A",'
            '"date":"2025-01-01"},'
            '{"dedup_key":"release:1.3.0","title":"旧告知","message":"重複メッセージ",'
            '"date":"2025-02-01"}'
            ']';
        await service.syncSystemNotificationsFromJson(jsonStr1);

        // 2回目: release:1.3.0 を削除し release:2.0.0 を追加
        const jsonStr2 = '['
            '{"dedup_key":"release:1.0.0","title":"v1.0.0","message":"A",'
            '"date":"2025-01-01"},'
            '{"dedup_key":"release:2.0.0","title":"v2.0.0","message":"新",'
            '"date":"2025-03-01"}'
            ']';
        await service.syncSystemNotificationsFromJson(jsonStr2);

        final all = await service.getAllNotifications();
        final system = all
            .where((n) => n.notificationType == NotificationType.system)
            .toList();
        final keys = system.map((n) => n.dedupKey).toSet();
        // release:1.3.0 は削除されている
        expect(keys.contains('release:1.3.0'), isFalse);
        // release:1.0.0 は保持、release:2.0.0 は追加
        expect(keys.contains('release:1.0.0'), isTrue);
        expect(keys.contains('release:2.0.0'), isTrue);
        expect(system.length, 2);
      });

      test('リマインダー通知はシステム同期で削除されない', () async {
        // リマインダーを手動追加
        await db.notificationDao.insertNotification(
          NotificationsCompanion(
            id: const Value('reminder-1'),
            notificationType: const Value('reminder'),
            title: const Value('期限通知'),
            message: const Value('テスト'),
            isRead: const Value(false),
            createdAt: Value(DateTime.now()),
            dedupKey: const Value('reminder:task:t1:due_7days'),
          ),
        );

        // システム通知を同期（空）
        await service.syncSystemNotificationsFromJson('[]');

        final all = await service.getAllNotifications();
        expect(all.length, 1);
        expect(all.first.notificationType, NotificationType.reminder);
      });

      test('空のdedup_keyはスキップする', () async {
        const jsonStr =
            '[{"dedup_key":"","title":"A","message":"B"}]';
        final result =
            await service.syncSystemNotificationsFromJson(jsonStr);
        expect(result.notifications, isEmpty);
      });

      test('不正なJSONで空リスト', () async {
        final result =
            await service.syncSystemNotificationsFromJson('invalid');
        expect(result.notifications, isEmpty);
      });

      test('dateを指定するとcreatedAtに反映される', () async {
        const jsonStr = '['
            '{"dedup_key":"sys:dated","title":"日付指定","message":"テスト",'
            '"date":"2025-01-01"}'
            ']';
        final result =
            await service.syncSystemNotificationsFromJson(jsonStr);
        expect(result.notifications.length, 1);
        final all = await service.getAllNotifications();
        expect(all.first.createdAt.year, 2025);
        expect(all.first.createdAt.month, 1);
        expect(all.first.createdAt.day, 1);
      });

      test('未来の日付の通知はスキップされる（予約通知）', () async {
        const jsonStr = '['
            '{"dedup_key":"sys:future","title":"未来の通知","message":"テスト",'
            '"date":"2099-12-31"}'
            ']';
        final result =
            await service.syncSystemNotificationsFromJson(jsonStr);
        expect(result.notifications, isEmpty);

        final all = await service.getAllNotifications();
        expect(all, isEmpty);
      });

      test('過去の通知は表示され未来の通知はスキップされる', () async {
        const jsonStr = '['
            '{"dedup_key":"sys:past","title":"過去の通知","message":"A",'
            '"date":"2025-01-01"},'
            '{"dedup_key":"sys:future","title":"未来の通知","message":"B",'
            '"date":"2099-12-31"}'
            ']';
        final result =
            await service.syncSystemNotificationsFromJson(jsonStr);
        expect(result.notifications.length, 1);
        expect(result.notifications.first.title, '過去の通知');
      });

      test('初回アクセス時は最新の通知のみ未読で表示される', () async {
        const jsonStr = '['
            '{"dedup_key":"release:1.0.0","title":"v1.0.0","message":"A",'
            '"date":"2025-01-01"},'
            '{"dedup_key":"release:1.0.1","title":"v1.0.1","message":"B",'
            '"date":"2025-02-01"},'
            '{"dedup_key":"release:1.0.2","title":"v1.0.2","message":"C",'
            '"date":"2025-03-01"}'
            ']';
        final result =
            await service.syncSystemNotificationsFromJson(jsonStr);

        // 未読として返されるのは最新の1件のみ
        expect(result.notifications.length, 1);
        expect(result.notifications.first.title, 'v1.0.2');

        // DB上は全件登録されている（過去分は既読）
        final all = await service.getAllNotifications();
        final system = all
            .where((n) => n.notificationType == NotificationType.system)
            .toList();
        expect(system.length, 3);

        final unread = system.where((n) => !n.isRead).toList();
        expect(unread.length, 1);
        expect(unread.first.title, 'v1.0.2');

        final read = system.where((n) => n.isRead).toList();
        expect(read.length, 2);
      });

      test('既存ユーザーは新規通知が全て未読で表示される', () async {
        // 1回目の同期（初回アクセス）
        const jsonStr1 =
            '[{"dedup_key":"release:1.0.0","title":"v1.0.0","message":"A",'
            '"date":"2025-01-01"}]';
        await service.syncSystemNotificationsFromJson(jsonStr1);

        // 2回目の同期（既存ユーザー：新バージョン追加）
        const jsonStr2 = '['
            '{"dedup_key":"release:1.0.0","title":"v1.0.0","message":"A",'
            '"date":"2025-01-01"},'
            '{"dedup_key":"release:1.0.1","title":"v1.0.1","message":"B",'
            '"date":"2025-02-01"},'
            '{"dedup_key":"release:1.0.2","title":"v1.0.2","message":"C",'
            '"date":"2025-03-01"}'
            ']';
        final result =
            await service.syncSystemNotificationsFromJson(jsonStr2);

        // 既存ユーザーは新規の2件とも未読で表示される
        expect(result.notifications.length, 2);
        expect(result.notifications[0].title, 'v1.0.1');
        expect(result.notifications[1].title, 'v1.0.2');
      });
    });
  });
}
