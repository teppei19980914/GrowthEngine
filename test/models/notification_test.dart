import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/models/notification.dart';

void main() {
  group('NotificationType', () {
    test('values have correct string values', () {
      expect(NotificationType.system.value, 'system');
      expect(NotificationType.achievement.value, 'achievement');
    });

    test('fromValue returns correct enum', () {
      expect(NotificationType.fromValue('system'), NotificationType.system);
      expect(
        NotificationType.fromValue('achievement'),
        NotificationType.achievement,
      );
    });

    test('fromValue throws on invalid value', () {
      expect(
        () => NotificationType.fromValue('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Notification', () {
    late Notification notification;

    setUp(() {
      notification = Notification(
        notificationType: NotificationType.achievement,
        title: '100時間達成！',
        message: '累計活動時間が100時間に到達しました。',
      );
    });

    test('creates with default values', () {
      expect(notification.id, isNotEmpty);
      expect(notification.notificationType, NotificationType.achievement);
      expect(notification.title, '100時間達成！');
      expect(notification.message, '累計活動時間が100時間に到達しました。');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, isNotNull);
      expect(notification.dedupKey, '');
    });

    test('creates with all custom values', () {
      final custom = Notification(
        id: 'custom-id',
        notificationType: NotificationType.system,
        title: 'システム通知',
        message: 'メンテナンス予定',
        isRead: true,
        createdAt: DateTime(2026, 3, 1, 10, 0),
        dedupKey: 'system:maintenance:2026-03-01',
      );
      expect(custom.id, 'custom-id');
      expect(custom.notificationType, NotificationType.system);
      expect(custom.isRead, isTrue);
      expect(custom.dedupKey, 'system:maintenance:2026-03-01');
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final copied = notification.copyWith(
          isRead: true,
          dedupKey: 'total_hours:100',
        );
        expect(copied.isRead, isTrue);
        expect(copied.dedupKey, 'total_hours:100');
        expect(copied.id, notification.id);
        expect(copied.title, notification.title);
      });

      test('copies with changed type', () {
        final copied = notification.copyWith(
          notificationType: NotificationType.system,
        );
        expect(copied.notificationType, NotificationType.system);
      });
    });

    group('toMap / fromMap', () {
      test('round-trip serialization', () {
        final full = Notification(
          id: 'test-id',
          notificationType: NotificationType.achievement,
          title: 'テスト通知',
          message: 'テストメッセージ',
          isRead: true,
          createdAt: DateTime(2026, 3, 1, 10, 0),
          dedupKey: 'total_hours:50',
        );
        final map = full.toMap();
        final restored = Notification.fromMap(map);
        expect(restored.id, full.id);
        expect(restored.notificationType, full.notificationType);
        expect(restored.title, full.title);
        expect(restored.message, full.message);
        expect(restored.isRead, full.isRead);
        expect(restored.dedupKey, full.dedupKey);
      });

      test('toMap contains correct keys', () {
        final map = notification.toMap();
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('notification_type'), isTrue);
        expect(map.containsKey('title'), isTrue);
        expect(map.containsKey('message'), isTrue);
        expect(map.containsKey('is_read'), isTrue);
        expect(map.containsKey('created_at'), isTrue);
        expect(map.containsKey('dedup_key'), isTrue);
      });

      test('toMap stores notification_type as string', () {
        final map = notification.toMap();
        expect(map['notification_type'], 'achievement');
      });

      test('toMap stores is_read as bool', () {
        final map = notification.toMap();
        expect(map['is_read'], isFalse);
      });

      test('fromMap handles missing optional fields', () {
        final map = {
          'id': 'test-id',
          'notification_type': 'system',
          'title': 'test',
          'message': 'msg',
          'created_at': '2026-01-01T00:00:00.000',
        };
        final restored = Notification.fromMap(map);
        expect(restored.isRead, isFalse);
        expect(restored.dedupKey, '');
      });
    });

    group('equality', () {
      test('equal when same id', () {
        final n1 = Notification(
          id: 'same-id',
          notificationType: NotificationType.system,
          title: 'A',
          message: 'A',
        );
        final n2 = Notification(
          id: 'same-id',
          notificationType: NotificationType.achievement,
          title: 'B',
          message: 'B',
        );
        expect(n1, equals(n2));
        expect(n1.hashCode, n2.hashCode);
      });

      test('not equal when different id', () {
        final n1 = Notification(
          id: 'id-1',
          notificationType: NotificationType.system,
          title: 'Same',
          message: 'Same',
        );
        final n2 = Notification(
          id: 'id-2',
          notificationType: NotificationType.system,
          title: 'Same',
          message: 'Same',
        );
        expect(n1, isNot(equals(n2)));
      });
    });

    test('toString contains id and title', () {
      final str = notification.toString();
      expect(str, contains(notification.id));
      expect(str, contains(notification.title));
    });
  });
}
