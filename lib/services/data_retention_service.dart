/// 古いデータを定期的に物理削除するクリーンアップサービス.
///
/// データ肥大化によるパフォーマンス劣化と Firestore コスト増を抑えるため、
/// 以下のポリシーで保持期間を超えたデータを物理削除する.
///
/// - 既読通知: 作成日時が 30 日以上経過したもの（未読は残す）
/// - 完了タスク: `updatedAt` が 30 日以上経過したもの（未完了は残す）
///
/// 削除されたくないデータはユーザーが事前にエクスポートする運用
/// （FAQ `helpFaqAutoDeleteA` に記載）.
library;

import '../database/daos/notification_dao.dart';
import '../database/daos/task_dao.dart';

/// 既読通知・完了タスクの保持期間.
const dataRetentionPeriod = Duration(days: 30);

/// データ保持期間を超えた古いデータを物理削除するサービス.
class DataRetentionService {
  /// DataRetentionServiceを作成する.
  DataRetentionService({
    required NotificationDao notificationDao,
    required TaskDao taskDao,
  })  : _notificationDao = notificationDao,
        _taskDao = taskDao;

  final NotificationDao _notificationDao;
  final TaskDao _taskDao;

  /// クリーンアップを実行する.
  ///
  /// 返り値は削除された行数の内訳. 失敗時は 0 件として扱い例外は伝播させない
  /// （起動時クリーンアップが失敗してもアプリ本体の動作を妨げないため）.
  Future<DataRetentionResult> cleanup({
    DateTime? now,
    Duration retention = dataRetentionPeriod,
  }) async {
    final threshold = (now ?? DateTime.now()).subtract(retention);
    var notifications = 0;
    var tasks = 0;
    try {
      notifications =
          await _notificationDao.deleteReadNotificationsOlderThan(threshold);
    } on Exception {
      notifications = 0;
    }
    try {
      tasks = await _taskDao.deleteCompletedOlderThan(threshold);
    } on Exception {
      tasks = 0;
    }
    return DataRetentionResult(
      deletedNotifications: notifications,
      deletedTasks: tasks,
      threshold: threshold,
    );
  }
}

/// クリーンアップ結果.
class DataRetentionResult {
  /// DataRetentionResultを作成する.
  const DataRetentionResult({
    required this.deletedNotifications,
    required this.deletedTasks,
    required this.threshold,
  });

  /// 削除された既読通知の件数.
  final int deletedNotifications;

  /// 削除された完了タスクの件数.
  final int deletedTasks;

  /// 削除判定の基準日時（これより古いデータが削除された）.
  final DateTime threshold;

  /// 何か 1 件でも削除されたかどうか.
  bool get hasDeletions => deletedNotifications > 0 || deletedTasks > 0;
}
