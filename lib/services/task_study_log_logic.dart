/// TaskDialog内の活動ログ管理ロジック.
library;

import 'dart:math';

import '../models/study_log.dart';
import 'study_log_service.dart';
import 'study_stats_types.dart';

/// 表示用活動ログエントリ.
class StudyLogDisplayEntry {
  /// StudyLogDisplayEntryを作成する.
  const StudyLogDisplayEntry({
    required this.logId,
    required this.studyDate,
    required this.durationMinutes,
    this.memo = '',
  });

  /// ログID（削除用）.
  final String logId;

  /// 活動実施日.
  final DateTime studyDate;

  /// 活動時間（分）.
  final int durationMinutes;

  /// メモ.
  final String memo;
}

/// TaskDialog内の活動ログビジネスロジック.
class TaskStudyLogLogic {
  /// TaskStudyLogLogicを初期化する.
  TaskStudyLogLogic({
    required StudyLogService studyLogService,
    required String taskId,
    required String taskName,
  })  : _studyLogService = studyLogService,
        _taskId = taskId,
        _taskName = taskName;

  final StudyLogService _studyLogService;
  final String _taskId;
  final String _taskName;
  final _stopwatch = Stopwatch();

  /// タスクの活動ログ一覧を取得する（日付降順）.
  Future<List<StudyLogDisplayEntry>> getLogs() async {
    final logs = await _studyLogService.getLogsForTask(_taskId);
    final entries = logs
        .map(
          (log) => StudyLogDisplayEntry(
            logId: log.id,
            studyDate: log.studyDate,
            durationMinutes: log.durationMinutes,
            memo: log.memo,
          ),
        )
        .toList();
    entries.sort((a, b) => b.studyDate.compareTo(a.studyDate));
    return entries;
  }

  /// タスクの活動統計を取得する.
  Future<TaskStudyStats> getStats() =>
      _studyLogService.getTaskStats(_taskId);

  /// 活動ログを追加する.
  Future<StudyLog> addLog({
    required DateTime studyDate,
    required int durationMinutes,
    String memo = '',
  }) {
    return _studyLogService.addStudyLog(
      taskId: _taskId,
      studyDate: studyDate,
      durationMinutes: durationMinutes,
      memo: memo,
      taskName: _taskName,
    );
  }

  /// 活動ログを削除する.
  Future<bool> deleteLog(String logId) => _studyLogService.deleteLog(logId);

  /// 時間と分から合計分数を計算し検証する.
  static int validateDuration(int hours, int minutes) {
    final total = hours * 60 + minutes;
    if (total <= 0) {
      throw ArgumentError('活動時間は1分以上で入力してください。');
    }
    return total;
  }

  /// 活動時間を表示用にフォーマットする.
  static String formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (m > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
      return '${h}h 00min';
    }
    return '${minutes}min';
  }

  /// タイマーを開始する.
  void startTimer() => _stopwatch
    ..reset()
    ..start();

  /// タイマーを停止し経過分数を返す（最小1分、切り上げ）.
  int stopTimer() {
    if (!_stopwatch.isRunning) return 0;
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();
    return max(1, (elapsed / 60000).ceil());
  }

  /// タイマーが実行中かどうかを返す.
  bool get isTimerRunning => _stopwatch.isRunning;

  /// タイマーの経過秒数を返す.
  int get elapsedSeconds =>
      _stopwatch.isRunning ? _stopwatch.elapsed.inSeconds : 0;
}
