import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/database/daos/notification_dao.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late NotificationDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = NotificationDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  NotificationsCompanion createNotification({
    String id = 'notif-1',
    String notificationType = 'achievement',
    String title = 'テスト通知',
    String message = 'テストメッセージ',
    bool isRead = false,
    String dedupKey = '',
    DateTime? createdAt,
  }) {
    return NotificationsCompanion(
      id: Value(id),
      notificationType: Value(notificationType),
      title: Value(title),
      message: Value(message),
      isRead: Value(isRead),
      dedupKey: Value(dedupKey),
      createdAt: Value(createdAt ?? DateTime(2026, 3, 1)),
    );
  }

  group('NotificationDao', () {
    test('insert and getAll returns in descending order', () async {
      await dao.insertNotification(
        createNotification(
          id: 'notif-1',
          title: '古い通知',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await dao.insertNotification(
        createNotification(
          id: 'notif-2',
          title: '新しい通知',
          createdAt: DateTime(2026, 3, 1),
        ),
      );
      final notifications = await dao.getAll();
      expect(notifications.length, 2);
      expect(notifications[0].title, '新しい通知');
      expect(notifications[1].title, '古い通知');
    });

    test('getAll returns empty list initially', () async {
      final notifications = await dao.getAll();
      expect(notifications, isEmpty);
    });

    test('getById returns notification', () async {
      await dao.insertNotification(createNotification(id: 'notif-1'));
      final notification = await dao.getById('notif-1');
      expect(notification, isNotNull);
      expect(notification!.id, 'notif-1');
    });

    test('getById returns null when not found', () async {
      final notification = await dao.getById('nonexistent');
      expect(notification, isNull);
    });

    test('getUnread returns only unread notifications', () async {
      await dao.insertNotification(
        createNotification(id: 'notif-1', isRead: false, title: '未読'),
      );
      await dao.insertNotification(
        createNotification(id: 'notif-2', isRead: true, title: '既読'),
      );
      await dao.insertNotification(
        createNotification(id: 'notif-3', isRead: false, title: '未読2'),
      );

      final unread = await dao.getUnread();
      expect(unread.length, 2);
      for (final n in unread) {
        expect(n.isRead, isFalse);
      }
    });

    test('getUnreadCount returns correct count', () async {
      await dao.insertNotification(
        createNotification(id: 'notif-1', isRead: false),
      );
      await dao.insertNotification(
        createNotification(id: 'notif-2', isRead: true),
      );
      await dao.insertNotification(
        createNotification(id: 'notif-3', isRead: false),
      );

      final count = await dao.getUnreadCount();
      expect(count, 2);
    });

    test('getUnreadCount returns 0 when all read', () async {
      await dao.insertNotification(
        createNotification(id: 'notif-1', isRead: true),
      );
      final count = await dao.getUnreadCount();
      expect(count, 0);
    });

    test('getUnreadCount returns 0 when empty', () async {
      final count = await dao.getUnreadCount();
      expect(count, 0);
    });

    test('existsByDedupKey returns true when exists', () async {
      await dao.insertNotification(
        createNotification(id: 'notif-1', dedupKey: 'total_hours:100'),
      );
      final exists = await dao.existsByDedupKey('total_hours:100');
      expect(exists, isTrue);
    });

    test('existsByDedupKey returns false when not exists', () async {
      final exists = await dao.existsByDedupKey('total_hours:100');
      expect(exists, isFalse);
    });

    test('markAsRead marks single notification as read', () async {
      await dao.insertNotification(
        createNotification(id: 'notif-1', isRead: false),
      );
      final marked = await dao.markAsRead('notif-1');
      expect(marked, isTrue);
      final notification = await dao.getById('notif-1');
      expect(notification!.isRead, isTrue);
    });

    test('markAsRead returns false when not found', () async {
      final marked = await dao.markAsRead('nonexistent');
      expect(marked, isFalse);
    });

    test('markAllAsRead marks all unread as read', () async {
      await dao.insertNotification(
        createNotification(id: 'notif-1', isRead: false),
      );
      await dao.insertNotification(
        createNotification(id: 'notif-2', isRead: false),
      );
      await dao.insertNotification(
        createNotification(id: 'notif-3', isRead: true),
      );

      final count = await dao.markAllAsRead();
      expect(count, 2);

      final unreadCount = await dao.getUnreadCount();
      expect(unreadCount, 0);
    });

    test('markAllAsRead returns 0 when all already read', () async {
      await dao.insertNotification(
        createNotification(id: 'notif-1', isRead: true),
      );
      final count = await dao.markAllAsRead();
      expect(count, 0);
    });

    test('deleteById removes notification', () async {
      await dao.insertNotification(createNotification(id: 'notif-1'));
      final deleted = await dao.deleteById('notif-1');
      expect(deleted, isTrue);
      final notifications = await dao.getAll();
      expect(notifications, isEmpty);
    });

    test('deleteById returns false when not found', () async {
      final deleted = await dao.deleteById('nonexistent');
      expect(deleted, isFalse);
    });
  });
}
