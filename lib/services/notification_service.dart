/// 通知のビジネスロジック.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart' as db;
import '../database/daos/notification_dao.dart';
import '../l10n/app_labels.dart';
import '../models/notification.dart';
import 'study_stats_types.dart';

/// announcements.json 同期の結果.
class AnnouncementSyncResult {
  /// AnnouncementSyncResultを作成する.
  const AnnouncementSyncResult({required this.notifications});

  /// 同期された通知一覧.
  final List<Notification> notifications;
}

/// 実績達成時の閾値.
const _totalHoursThresholds = [1, 5, 10, 25, 50, 100, 250, 500, 1000];
const _studyDaysThresholds = [3, 7, 14, 30, 60, 100, 200, 365];
const _streakThresholds = [3, 7, 14, 30, 60, 100];

/// 実績タイプに対応するタイトルを返す.
String _achievementTitle(MilestoneType type, int value) => switch (type) {
      MilestoneType.totalHours => AppLabels.achievementTotalHoursTitle(value),
      MilestoneType.studyDays => AppLabels.achievementStudyDaysTitle(value),
      MilestoneType.streak => AppLabels.achievementStreakTitle(value),
    };

/// 実績タイプに対応するメッセージを返す.
String _achievementMessage(MilestoneType type, int value) => switch (type) {
      MilestoneType.totalHours => AppLabels.achievementTotalHoursMsg(value),
      MilestoneType.studyDays => AppLabels.achievementStudyDaysMsg(value),
      MilestoneType.streak => AppLabels.achievementStreakMsg(value),
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
            final title = _achievementTitle(type, threshold);
            final message = _achievementMessage(type, threshold);
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
        title = AppLabels.reminderOverdueTitle(item.title);
        message = AppLabels.reminderOverdueMsg(-daysLeft);
      } else if (daysLeft == 0) {
        dedupSuffix = 'due_today';
        title = AppLabels.reminderTodayTitle(item.title);
        message = AppLabels.reminderTodayMsg;
      } else if (daysLeft <= 7) {
        dedupSuffix = 'due_7days';
        title = AppLabels.reminderSoonTitle(item.title, daysLeft);
        message = AppLabels.reminderSoonMsg;
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

  /// システム通知をJSON文字列と同期する.
  ///
  /// DBの既存システム通知を全削除し、JSONの内容で再作成する.
  /// これにより announcements.json の編集がそのままユーザーに反映される.
  /// リマインダーや実績通知には影響しない.
  Future<AnnouncementSyncResult> syncSystemNotificationsFromJson(
    String jsonStr,
  ) async {
    try {
      final items =
          (json.decode(jsonStr) as List).cast<Map<String, dynamic>>();
      final now = DateTime.now();

      // 旧ロジック（全削除→再作成）で発生した重複を除去
      await _notificationDao.removeDuplicates();

      // announcements.json に含まれる全 dedup_key を集計（未来日付も含む）
      final jsonDedupKeys = <String>{
        for (final item in items)
          if ((item['dedup_key']?.toString() ?? '').isNotEmpty)
            item['dedup_key']!.toString(),
      };

      // announcements.json から削除されたエントリを DB からも除去
      // （リマインダー等の dedupKey が空の通知は影響を受けない）
      await _notificationDao.deleteByTypeWhereDedupKeyNotIn(
        NotificationType.system.value,
        jsonDedupKeys,
      );

      // 初回アクセス判定: システム通知が1件もなければ初回ユーザー
      final existingSystem =
          await _notificationDao.countByType(NotificationType.system.value);
      final isFirstAccess = existingSystem == 0;

      // 同期対象を抽出（非空dedupKey・非未来・DB未登録）
      final validItems = <Map<String, dynamic>>[];
      for (final item in items) {
        final dedupKey = item['dedup_key']?.toString() ?? '';
        if (dedupKey.isEmpty) continue;
        final dateStr = item['date']?.toString() ?? '';
        final createdAt =
            dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null;
        if (createdAt != null && createdAt.isAfter(now)) continue;
        if (await _notificationDao.existsByDedupKey(dedupKey)) continue;
        validItems.add(item);
      }

      // 通知を作成（初回は最新1件のみ未読、残りは既読で登録）
      final created = <Notification>[];
      for (var i = 0; i < validItems.length; i++) {
        final item = validItems[i];
        final dedupKey = item['dedup_key']!.toString();
        final dateStr = item['date']?.toString() ?? '';
        final createdAt =
            dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null;
        final isRead = isFirstAccess && i < validItems.length - 1;
        final notification = Notification(
          notificationType: NotificationType.system,
          title: item['title']?.toString() ?? '',
          message: item['message']?.toString() ?? '',
          dedupKey: dedupKey,
          isRead: isRead,
          createdAt: createdAt,
        );
        await _notificationDao.insertNotification(
          _notificationToCompanion(notification),
        );
        if (!isRead) created.add(notification);
      }
      return AnnouncementSyncResult(notifications: created);
    } catch (_) {
      return const AnnouncementSyncResult(notifications: []);
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
