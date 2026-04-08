import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/services/data_retention_service.dart';

void main() {
  late AppDatabase db;
  late DataRetentionService service;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    service = DataRetentionService(
      notificationDao: db.notificationDao,
      taskDao: db.taskDao,
    );
  });

  tearDown(() => db.close());

  group('DataRetentionService.cleanup', () {
    test('既読かつ30日より古い通知が削除される', () async {
      final now = DateTime(2026, 4, 8);
      // 既読 / 31日前 → 削除対象
      await db.notificationDao.insertNotification(
        NotificationsCompanion(
          id: const Value('old-read'),
          notificationType: const Value('system'),
          title: const Value('古い既読'),
          message: const Value(''),
          isRead: const Value(true),
          createdAt: Value(now.subtract(const Duration(days: 31))),
          dedupKey: const Value('old-read'),
        ),
      );
      // 既読 / 29日前 → 残す
      await db.notificationDao.insertNotification(
        NotificationsCompanion(
          id: const Value('recent-read'),
          notificationType: const Value('system'),
          title: const Value('最近の既読'),
          message: const Value(''),
          isRead: const Value(true),
          createdAt: Value(now.subtract(const Duration(days: 29))),
          dedupKey: const Value('recent-read'),
        ),
      );
      // 未読 / 60日前 → 残す（未読は保護）
      await db.notificationDao.insertNotification(
        NotificationsCompanion(
          id: const Value('old-unread'),
          notificationType: const Value('system'),
          title: const Value('古い未読'),
          message: const Value(''),
          isRead: const Value(false),
          createdAt: Value(now.subtract(const Duration(days: 60))),
          dedupKey: const Value('old-unread'),
        ),
      );

      final result = await service.cleanup(now: now);

      expect(result.deletedNotifications, 1);
      final remaining = await db.notificationDao.getAll();
      final ids = remaining.map((n) => n.id).toSet();
      expect(ids, containsAll(['recent-read', 'old-unread']));
      expect(ids.contains('old-read'), isFalse);
    });

    test('完了済みかつ30日より古い更新日時のタスクが削除される', () async {
      final now = DateTime(2026, 4, 8);
      // 完了 / updatedAt 31日前 → 削除対象
      await db.taskDao.insertTask(
        TasksCompanion(
          id: const Value('old-done'),
          goalId: const Value('g1'),
          title: const Value('古い完了タスク'),
          startDate: Value(now.subtract(const Duration(days: 60))),
          endDate: Value(now.subtract(const Duration(days: 31))),
          status: const Value('completed'),
          progress: const Value(100),
          createdAt: Value(now.subtract(const Duration(days: 60))),
          updatedAt: Value(now.subtract(const Duration(days: 31))),
        ),
      );
      // 完了 / updatedAt 29日前 → 残す
      await db.taskDao.insertTask(
        TasksCompanion(
          id: const Value('recent-done'),
          goalId: const Value('g1'),
          title: const Value('最近の完了タスク'),
          startDate: Value(now.subtract(const Duration(days: 60))),
          endDate: Value(now.subtract(const Duration(days: 29))),
          status: const Value('completed'),
          progress: const Value(100),
          createdAt: Value(now.subtract(const Duration(days: 60))),
          updatedAt: Value(now.subtract(const Duration(days: 29))),
        ),
      );
      // 進行中 / updatedAt 60日前 → 残す（未完了は保護）
      await db.taskDao.insertTask(
        TasksCompanion(
          id: const Value('old-inprogress'),
          goalId: const Value('g1'),
          title: const Value('古い進行中タスク'),
          startDate: Value(now.subtract(const Duration(days: 120))),
          endDate: Value(now.add(const Duration(days: 30))),
          status: const Value('in_progress'),
          progress: const Value(50),
          createdAt: Value(now.subtract(const Duration(days: 120))),
          updatedAt: Value(now.subtract(const Duration(days: 60))),
        ),
      );
      // 未着手 / updatedAt 100日前 → 残す
      await db.taskDao.insertTask(
        TasksCompanion(
          id: const Value('old-notstarted'),
          goalId: const Value('g1'),
          title: const Value('古い未着手タスク'),
          startDate: Value(now.add(const Duration(days: 1))),
          endDate: Value(now.add(const Duration(days: 30))),
          status: const Value('not_started'),
          progress: const Value(0),
          createdAt: Value(now.subtract(const Duration(days: 100))),
          updatedAt: Value(now.subtract(const Duration(days: 100))),
        ),
      );

      final result = await service.cleanup(now: now);

      expect(result.deletedTasks, 1);
      final remaining = await db.taskDao.getAll();
      final ids = remaining.map((t) => t.id).toSet();
      expect(
        ids,
        containsAll(['recent-done', 'old-inprogress', 'old-notstarted']),
      );
      expect(ids.contains('old-done'), isFalse);
    });

    test('何も削除対象がない場合は 0 件を返す', () async {
      final now = DateTime(2026, 4, 8);

      final result = await service.cleanup(now: now);

      expect(result.deletedNotifications, 0);
      expect(result.deletedTasks, 0);
      expect(result.hasDeletions, isFalse);
    });

    test('カスタム retention で閾値を調整できる', () async {
      final now = DateTime(2026, 4, 8);
      // 既読 / 10日前 → 通常 (30日) なら残るが、retention=7日なら削除
      await db.notificationDao.insertNotification(
        NotificationsCompanion(
          id: const Value('10d-read'),
          notificationType: const Value('system'),
          title: const Value('10日前の既読'),
          message: const Value(''),
          isRead: const Value(true),
          createdAt: Value(now.subtract(const Duration(days: 10))),
          dedupKey: const Value('10d-read'),
        ),
      );

      final result = await service.cleanup(
        now: now,
        retention: const Duration(days: 7),
      );

      expect(result.deletedNotifications, 1);
    });

    test('完了タスクのうち progress=100 でも status が completed でなければ残る', () async {
      // このテストで DAO の where 条件 status == 'completed' を確認
      final now = DateTime(2026, 4, 8);
      await db.taskDao.insertTask(
        TasksCompanion(
          id: const Value('bug-row'),
          goalId: const Value('g1'),
          title: const Value('不整合レコード'),
          startDate: Value(now.subtract(const Duration(days: 60))),
          endDate: Value(now.subtract(const Duration(days: 50))),
          status: const Value('in_progress'), // 不整合
          progress: const Value(100),
          createdAt: Value(now.subtract(const Duration(days: 60))),
          updatedAt: Value(now.subtract(const Duration(days: 60))),
        ),
      );

      final result = await service.cleanup(now: now);

      // status が 'in_progress' なので削除されない
      expect(result.deletedTasks, 0);
    });
  });
}
