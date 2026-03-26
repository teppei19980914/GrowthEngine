/// 通知のビジネスロジック.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart' as db;
import '../database/daos/notification_dao.dart';
import '../models/notification.dart';
import 'study_stats_types.dart';

/// 実績達成時の閾値.
const _totalHoursThresholds = [1, 5, 10, 25, 50, 100, 250, 500, 1000];
const _studyDaysThresholds = [3, 7, 14, 30, 60, 100, 200, 365];
const _streakThresholds = [3, 7, 14, 30, 60, 100];

const _achievementTitles = {
  MilestoneType.totalHours: '累計{value}時間達成！',
  MilestoneType.studyDays: '活動{value}日目達成！',
  MilestoneType.streak: '{value}日連続活動達成！',
};

const _achievementMessages = {
  MilestoneType.totalHours: '累計活動時間が{value}時間に到達しました。素晴らしい継続力です！',
  MilestoneType.studyDays: '活動日数が{value}日に到達しました。コツコツ積み重ねていますね！',
  MilestoneType.streak: '{value}日間連続で活動を続けています。この調子で頑張りましょう！',
};

const _thresholdMap = {
  MilestoneType.totalHours: _totalHoursThresholds,
  MilestoneType.studyDays: _studyDaysThresholds,
  MilestoneType.streak: _streakThresholds,
};

const _prefsKeyNotificationsEnabled = 'notifications_enabled';

/// NotificationのCRUD操作とビジネスロジックを提供するサービス.
class NotificationService {
  /// NotificationServiceを作成する.
  NotificationService({required NotificationDao notificationDao})
      : _notificationDao = notificationDao;

  final NotificationDao _notificationDao;

  /// 通知が有効かどうかを返す.
  Future<bool> get notificationsEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyNotificationsEnabled) ?? true;
  }

  /// 通知の有効/無効を設定する.
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyNotificationsEnabled, enabled);
  }

  /// 全通知を取得する.
  Future<List<Notification>> getAllNotifications() async {
    final rows = await _notificationDao.getAll();
    return rows.map(_rowToNotification).toList();
  }

  /// 未読通知数を返す.
  Future<int> getUnreadCount() => _notificationDao.getUnreadCount();

  /// 通知を既読にする.
  Future<bool> markAsRead(String notificationId) =>
      _notificationDao.markAsRead(notificationId);

  /// 全通知を既読にする.
  Future<int> markAllAsRead() => _notificationDao.markAllAsRead();

  /// 実績達成通知をチェックして作成する.
  Future<List<Notification>> checkAndCreateAchievementNotifications(
    MilestoneData milestoneData,
  ) async {
    final enabled = await notificationsEnabled;
    if (!enabled) return [];

    final created = <Notification>[];
    final checks = {
      MilestoneType.totalHours: milestoneData.totalHours.floor(),
      MilestoneType.studyDays: milestoneData.studyDays,
      MilestoneType.streak: milestoneData.currentStreak,
    };

    for (final entry in checks.entries) {
      final type = entry.key;
      final currentValue = entry.value;
      final thresholds = _thresholdMap[type]!;

      for (final threshold in thresholds) {
        if (currentValue >= threshold) {
          final dedupKey = '${type.value}:$threshold';
          final exists = await _notificationDao.existsByDedupKey(dedupKey);
          if (!exists) {
            final title =
                _achievementTitles[type]!.replaceAll('{value}', '$threshold');
            final message =
                _achievementMessages[type]!.replaceAll('{value}', '$threshold');
            final notification = Notification(
              notificationType: NotificationType.achievement,
              title: title,
              message: message,
              dedupKey: dedupKey,
            );
            await _notificationDao.insertNotification(
              _notificationToCompanion(notification),
            );
            created.add(notification);
          }
        }
      }
    }
    return created;
  }

  /// 期限リマインダー通知を生成する.
  ///
  /// タスク・目標の期限が7日以内または超過の場合に自動生成する.
  /// 日付ベースの dedupKey で同じ期限通知は1日1回のみ.
  Future<List<Notification>> checkAndCreateReminders({
    required List<({String id, String title, DateTime deadline, bool isGoal})>
        deadlines,
  }) async {
    final enabled = await notificationsEnabled;
    if (!enabled) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final created = <Notification>[];

    for (final item in deadlines) {
      final dueDate = DateTime(
        item.deadline.year,
        item.deadline.month,
        item.deadline.day,
      );
      final daysLeft = dueDate.difference(today).inDays;

      String? title;
      String? message;
      String? dedupSuffix;

      if (daysLeft < 0) {
        dedupSuffix = 'overdue:${today.toIso8601String().substring(0, 10)}';
        title = '${item.title}が期限を過ぎています';
        message = '期限を${-daysLeft}日超過しています。確認してください。';
      } else if (daysLeft == 0) {
        dedupSuffix = 'due_today';
        title = '${item.title}の期限は今日です';
        message = '今日が期限日です。最後の追い込みを！';
      } else if (daysLeft <= 7) {
        dedupSuffix = 'due_7days';
        title = '${item.title}の期限まであと$daysLeft日';
        message = '期限が近づいています。計画を確認しましょう。';
      }

      if (title == null || dedupSuffix == null) continue;

      final kind = item.isGoal ? 'goal' : 'task';
      final dedupKey = 'reminder:$kind:${item.id}:$dedupSuffix';
      final exists = await _notificationDao.existsByDedupKey(dedupKey);
      if (exists) continue;

      final notification = Notification(
        notificationType: NotificationType.reminder,
        title: title,
        message: message!,
        dedupKey: dedupKey,
      );
      await _notificationDao.insertNotification(
        _notificationToCompanion(notification),
      );
      created.add(notification);
    }
    return created;
  }

  /// システム通知をJSON文字列から読み込む.
  Future<List<Notification>> loadSystemNotificationsFromJson(
    String jsonStr,
  ) async {
    try {
      final items =
          (json.decode(jsonStr) as List).cast<Map<String, dynamic>>();
      final created = <Notification>[];
      for (final item in items) {
        final dedupKey = item['dedup_key']?.toString() ?? '';
        if (dedupKey.isEmpty) continue;
        final exists = await _notificationDao.existsByDedupKey(dedupKey);
        if (exists) continue;
        final notification = Notification(
          notificationType: NotificationType.system,
          title: item['title']?.toString() ?? '',
          message: item['message']?.toString() ?? '',
          dedupKey: dedupKey,
        );
        await _notificationDao.insertNotification(
          _notificationToCompanion(notification),
        );
        created.add(notification);
      }
      return created;
    } catch (_) {
      return [];
    }
  }

  Notification _rowToNotification(db.Notification row) {
    return Notification(
      id: row.id,
      notificationType: NotificationType.fromValue(row.notificationType),
      title: row.title,
      message: row.message,
      isRead: row.isRead,
      createdAt: row.createdAt,
      dedupKey: row.dedupKey,
    );
  }

  db.NotificationsCompanion _notificationToCompanion(Notification n) {
    return db.NotificationsCompanion(
      id: Value(n.id),
      notificationType: Value(n.notificationType.value),
      title: Value(n.title),
      message: Value(n.message),
      isRead: Value(n.isRead),
      createdAt: Value(n.createdAt),
      dedupKey: Value(n.dedupKey),
    );
  }
}
