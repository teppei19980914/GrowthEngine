/// データエクスポート/インポートサービス.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../database/daos/book_dao.dart';
import '../database/daos/dream_dao.dart';
import '../database/daos/goal_dao.dart';
import '../database/daos/notification_dao.dart';
import '../database/daos/study_log_dao.dart';
import '../database/daos/task_dao.dart';

/// バックアップファイル名を生成する.
///
/// 形式: `yumehashi_backup_<timestamp>.json`
/// タイムスタンプは ISO8601 形式からコロンとミリ秒を除去したもの.
String buildBackupFileName(DateTime now) {
  final timestamp =
      now.toIso8601String().replaceAll(':', '-').split('.').first;
  return 'yumehashi_backup_$timestamp.json';
}

/// データエクスポート/インポートを行うサービス.
class DataExportService {
  /// DataExportServiceを作成する.
  DataExportService({
    required DreamDao dreamDao,
    required GoalDao goalDao,
    required TaskDao taskDao,
    required BookDao bookDao,
    required StudyLogDao studyLogDao,
    required NotificationDao notificationDao,
  })  : _dreamDao = dreamDao,
        _goalDao = goalDao,
        _taskDao = taskDao,
        _bookDao = bookDao,
        _studyLogDao = studyLogDao,
        _notificationDao = notificationDao;

  final DreamDao _dreamDao;
  final GoalDao _goalDao;
  final TaskDao _taskDao;
  final BookDao _bookDao;
  final StudyLogDao _studyLogDao;
  final NotificationDao _notificationDao;

  /// 全データを **整形済み JSON 文字列** としてエクスポートする.
  ///
  /// 主にローカルファイル書き出し用. インデント付きで人間が読みやすい形式.
  /// クラウド同期用には [exportDataCompact] を使用する（サイズが約 20% 小さい）.
  Future<String> exportData() async {
    final data = await _buildExportMap();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 全データを **コンパクト JSON 文字列** としてエクスポートする.
  ///
  /// 改行・インデントを含まない最小サイズの JSON. クラウド同期で使用する.
  /// ファイルサイズと帯域コストを削減する目的で v2.1.0 で導入.
  Future<String> exportDataCompact() async {
    final data = await _buildExportMap();
    return json.encode(data);
  }

  /// エクスポート対象のデータを Map として構築する（共通処理）.
  Future<Map<String, dynamic>> _buildExportMap() async {
    final dreams = await _dreamDao.getAll();
    final goals = await _goalDao.getAll();
    final tasks = await _taskDao.getAll();
    final books = await _bookDao.getAll();
    final studyLogs = await _studyLogDao.getAll();
    final notifications = await _notificationDao.getAll();

    return <String, dynamic>{
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'dreams': dreams.map(_dreamToMap).toList(),
      'goals': goals.map(_goalToMap).toList(),
      'tasks': tasks.map(_taskToMap).toList(),
      'books': books.map(_bookToMap).toList(),
      'study_logs': studyLogs.map(_studyLogToMap).toList(),
      'notifications': notifications.map(_notificationToMap).toList(),
    };
  }

  /// JSON文字列からデータをインポートする.
  ///
  /// 既存データを全て削除してから新しいデータを挿入する.
  /// インポートファイルの最大サイズ（10MB）.
  static const _maxImportSize = 10 * 1024 * 1024;

  Future<ImportResult> importData(String jsonString) async {
    if (jsonString.length > _maxImportSize) {
      throw ArgumentError('インポートファイルが大きすぎます（上限10MB）');
    }
    final Map<String, dynamic> data;
    try {
      data = json.decode(jsonString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw ArgumentError('不正なJSONデータです: $e');
    }

    final dreamsRaw = data['dreams'] as List<dynamic>? ?? [];
    final goalsRaw = data['goals'] as List<dynamic>? ?? [];
    final tasksRaw = data['tasks'] as List<dynamic>? ?? [];
    final booksRaw = data['books'] as List<dynamic>? ?? [];
    final studyLogsRaw = data['study_logs'] as List<dynamic>? ?? [];
    final notificationsRaw = data['notifications'] as List<dynamic>? ?? [];

    await _clearAll();

    var dreamCount = 0;
    var goalCount = 0;
    var taskCount = 0;
    var bookCount = 0;
    var studyLogCount = 0;
    var notificationCount = 0;

    for (final raw in dreamsRaw) {
      await _dreamDao.insertDream(
        _dreamFromMap(raw as Map<String, dynamic>),
      );
      dreamCount++;
    }
    for (final raw in goalsRaw) {
      await _goalDao.insertGoal(
        _goalFromMap(raw as Map<String, dynamic>),
      );
      goalCount++;
    }
    for (final raw in tasksRaw) {
      await _taskDao.insertTask(
        _taskFromMap(raw as Map<String, dynamic>),
      );
      taskCount++;
    }
    for (final raw in booksRaw) {
      await _bookDao.insertBook(
        _bookFromMap(raw as Map<String, dynamic>),
      );
      bookCount++;
    }
    for (final raw in studyLogsRaw) {
      await _studyLogDao.insertStudyLog(
        _studyLogFromMap(raw as Map<String, dynamic>),
      );
      studyLogCount++;
    }
    for (final raw in notificationsRaw) {
      await _notificationDao.insertNotification(
        _notificationFromMap(raw as Map<String, dynamic>),
      );
      notificationCount++;
    }

    return ImportResult(
      dreamCount: dreamCount,
      goalCount: goalCount,
      taskCount: taskCount,
      bookCount: bookCount,
      studyLogCount: studyLogCount,
      notificationCount: notificationCount,
    );
  }

  /// JSON文字列のバリデーションを行う.
  ValidationResult validateJson(String jsonString) {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final counts = <String, int>{};
      for (final key in [
        'dreams',
        'goals',
        'tasks',
        'books',
        'study_logs',
        'notifications',
      ]) {
        final list = data[key] as List<dynamic>?;
        counts[key] = list?.length ?? 0;
      }
      return ValidationResult(valid: true, counts: counts);
    } on FormatException {
      return const ValidationResult(
        valid: false,
        counts: {},
        errorMessage: '不正なJSONフォーマットです',
      );
    } on TypeError {
      return const ValidationResult(
        valid: false,
        counts: {},
        errorMessage: '不正なデータ構造です',
      );
    }
  }

  /// 全データを削除する.
  Future<int> clearAllData() => _clearAll();

  Future<int> _clearAll() async {
    var deleted = 0;
    final studyLogs = await _studyLogDao.getAll();
    for (final log in studyLogs) {
      await _studyLogDao.deleteById(log.id);
      deleted++;
    }
    final notifications = await _notificationDao.getAll();
    for (final n in notifications) {
      await _notificationDao.deleteById(n.id);
      deleted++;
    }
    final tasks = await _taskDao.getAll();
    for (final t in tasks) {
      await _taskDao.deleteById(t.id);
      deleted++;
    }
    final books = await _bookDao.getAll();
    for (final b in books) {
      await _bookDao.deleteById(b.id);
      deleted++;
    }
    final goals = await _goalDao.getAll();
    for (final g in goals) {
      await _goalDao.deleteById(g.id);
      deleted++;
    }
    final dreams = await _dreamDao.getAll();
    for (final d in dreams) {
      await _dreamDao.deleteById(d.id);
      deleted++;
    }
    return deleted;
  }

  // --- Dream 変換 ---

  Map<String, dynamic> _dreamToMap(db.Dream dream) {
    return {
      'id': dream.id,
      'title': dream.title,
      'description': dream.description,
      'why': dream.why,
      'category': dream.category,
      'sort_order': dream.sortOrder,
      'created_at': dream.createdAt.toIso8601String(),
      'updated_at': dream.updatedAt.toIso8601String(),
    };
  }

  db.DreamsCompanion _dreamFromMap(Map<String, dynamic> map) {
    return db.DreamsCompanion(
      id: Value(map['id'] as String),
      title: Value(map['title'] as String? ?? ''),
      description: Value(map['description'] as String? ?? ''),
      why: Value(map['why'] as String? ?? ''),
      category: Value(map['category'] as String? ?? 'other'),
      sortOrder: Value((map['sort_order'] as int?) ?? 0),
      createdAt: Value(DateTime.parse(map['created_at'] as String)),
      updatedAt: Value(DateTime.parse(map['updated_at'] as String)),
    );
  }

  // --- Goal 変換 ---

  Map<String, dynamic> _goalToMap(db.Goal goal) {
    return {
      'id': goal.id,
      'dream_id': goal.dreamId,
      'why': goal.why,
      'when_target': goal.whenTarget,
      'when_type': goal.whenType,
      'what': goal.what,
      'how': goal.how,
      'color': goal.color,
      'sort_order': goal.sortOrder,
      'created_at': goal.createdAt.toIso8601String(),
      'updated_at': goal.updatedAt.toIso8601String(),
    };
  }

  db.GoalsCompanion _goalFromMap(Map<String, dynamic> map) {
    return db.GoalsCompanion(
      id: Value(map['id'] as String),
      dreamId: Value(map['dream_id'] as String? ?? ''),
      why: Value(map['why'] as String? ?? ''),
      whenTarget: Value(map['when_target'] as String? ?? ''),
      whenType: Value(map['when_type'] as String? ?? 'none'),
      what: Value(map['what'] as String? ?? ''),
      how: Value(map['how'] as String? ?? ''),
      color: Value(map['color'] as String? ?? '#89B4FA'),
      sortOrder: Value((map['sort_order'] as int?) ?? 0),
      createdAt: Value(DateTime.parse(map['created_at'] as String)),
      updatedAt: Value(DateTime.parse(map['updated_at'] as String)),
    );
  }

  // --- Task 変換 ---

  Map<String, dynamic> _taskToMap(db.Task task) {
    return {
      'id': task.id,
      'goal_id': task.goalId,
      'title': task.title,
      'start_date': task.startDate.toIso8601String(),
      'end_date': task.endDate.toIso8601String(),
      'status': task.status,
      'progress': task.progress,
      'memo': task.memo,
      'book_id': task.bookId,
      'order': task.order,
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
    };
  }

  db.TasksCompanion _taskFromMap(Map<String, dynamic> map) {
    return db.TasksCompanion(
      id: Value(map['id'] as String),
      goalId: Value(map['goal_id'] as String),
      title: Value(map['title'] as String),
      startDate: Value(DateTime.parse(map['start_date'] as String)),
      endDate: Value(DateTime.parse(map['end_date'] as String)),
      status: Value(map['status'] as String? ?? 'not_started'),
      progress: Value(map['progress'] as int? ?? 0),
      memo: Value(map['memo'] as String? ?? ''),
      bookId: Value(map['book_id'] as String? ?? ''),
      order: Value(map['order'] as int? ?? 0),
      createdAt: Value(DateTime.parse(map['created_at'] as String)),
      updatedAt: Value(DateTime.parse(map['updated_at'] as String)),
    );
  }

  // --- Book 変換 ---

  Map<String, dynamic> _bookToMap(db.Book book) {
    return {
      'id': book.id,
      'title': book.title,
      'status': book.status,
      'category': book.category,
      'why': book.why,
      'description': book.description,
      'summary': book.summary,
      'impressions': book.impressions,
      'completed_date': book.completedDate?.toIso8601String(),
      'start_date': book.startDate?.toIso8601String(),
      'end_date': book.endDate?.toIso8601String(),
      'progress': book.progress,
      'created_at': book.createdAt.toIso8601String(),
      'updated_at': book.updatedAt.toIso8601String(),
    };
  }

  db.BooksCompanion _bookFromMap(Map<String, dynamic> map) {
    return db.BooksCompanion(
      id: Value(map['id'] as String),
      title: Value(map['title'] as String),
      status: Value(map['status'] as String? ?? 'unread'),
      category: Value(map['category'] as String? ?? 'other'),
      why: Value(map['why'] as String? ?? ''),
      description: Value(map['description'] as String? ?? ''),
      summary: Value(map['summary'] as String? ?? ''),
      impressions: Value(map['impressions'] as String? ?? ''),
      completedDate: Value(
        map['completed_date'] != null
            ? DateTime.parse(map['completed_date'] as String)
            : null,
      ),
      startDate: Value(
        map['start_date'] != null
            ? DateTime.parse(map['start_date'] as String)
            : null,
      ),
      endDate: Value(
        map['end_date'] != null
            ? DateTime.parse(map['end_date'] as String)
            : null,
      ),
      progress: Value(map['progress'] as int? ?? 0),
      createdAt: Value(DateTime.parse(map['created_at'] as String)),
      updatedAt: Value(DateTime.parse(map['updated_at'] as String)),
    );
  }

  // --- StudyLog 変換 ---

  Map<String, dynamic> _studyLogToMap(db.StudyLog log) {
    return {
      'id': log.id,
      'task_id': log.taskId,
      'study_date': log.studyDate.toIso8601String(),
      'duration_minutes': log.durationMinutes,
      'memo': log.memo,
      'task_name': log.taskName,
      'created_at': log.createdAt.toIso8601String(),
    };
  }

  db.StudyLogsCompanion _studyLogFromMap(Map<String, dynamic> map) {
    return db.StudyLogsCompanion(
      id: Value(map['id'] as String),
      taskId: Value(map['task_id'] as String),
      studyDate: Value(DateTime.parse(map['study_date'] as String)),
      durationMinutes: Value(map['duration_minutes'] as int),
      memo: Value(map['memo'] as String? ?? ''),
      taskName: Value(map['task_name'] as String? ?? ''),
      createdAt: Value(DateTime.parse(map['created_at'] as String)),
    );
  }

  // --- Notification 変換 ---

  Map<String, dynamic> _notificationToMap(db.Notification notification) {
    return {
      'id': notification.id,
      'notification_type': notification.notificationType,
      'title': notification.title,
      'message': notification.message,
      'is_read': notification.isRead,
      'created_at': notification.createdAt.toIso8601String(),
      'dedup_key': notification.dedupKey,
    };
  }

  db.NotificationsCompanion _notificationFromMap(Map<String, dynamic> map) {
    return db.NotificationsCompanion(
      id: Value(map['id'] as String),
      notificationType: Value(map['notification_type'] as String),
      title: Value(map['title'] as String),
      message: Value(map['message'] as String),
      isRead: Value(map['is_read'] as bool? ?? false),
      createdAt: Value(DateTime.parse(map['created_at'] as String)),
      dedupKey: Value(map['dedup_key'] as String? ?? ''),
    );
  }
}

/// インポート結果.
class ImportResult {
  /// インポート結果を作成する.
  const ImportResult({
    required this.dreamCount,
    required this.goalCount,
    required this.taskCount,
    required this.bookCount,
    required this.studyLogCount,
    required this.notificationCount,
  });

  /// インポートした夢数.
  final int dreamCount;

  /// インポートした目標数.
  final int goalCount;

  /// インポートしたタスク数.
  final int taskCount;

  /// インポートした書籍数.
  final int bookCount;

  /// インポートした活動ログ数.
  final int studyLogCount;

  /// インポートした通知数.
  final int notificationCount;

  /// 合計件数.
  int get total =>
      dreamCount +
      goalCount +
      taskCount +
      bookCount +
      studyLogCount +
      notificationCount;
}

/// バリデーション結果.
class ValidationResult {
  /// バリデーション結果を作成する.
  const ValidationResult({
    required this.valid,
    required this.counts,
    this.errorMessage,
  });

  /// 有効かどうか.
  final bool valid;

  /// 各データの件数.
  final Map<String, int> counts;

  /// エラーメッセージ.
  final String? errorMessage;
}
