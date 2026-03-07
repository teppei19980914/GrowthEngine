/// Web体験版の制限管理.
///
/// Web版アプリでのみデータ追加数を制限する.
/// ネイティブデスクトップ版では全て無制限.
/// フィードバック送信により段階的に制限が解除される.
library;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'feedback_service.dart';

/// レベル別の制限値.
///
/// レベル0: 初期, レベル1: FB1回, レベル2: FB2回, レベル3: 無制限.
const _levelLimits = <int, _LevelConfig>{
  0: _LevelConfig(dreams: 2, goalsPerDream: 3, tasksPerGoal: 5, books: 5),
  1: _LevelConfig(dreams: 4, goalsPerDream: 5, tasksPerGoal: 8, books: 8),
  2: _LevelConfig(dreams: 6, goalsPerDream: 8, tasksPerGoal: 12, books: 12),
};

class _LevelConfig {
  const _LevelConfig({
    required this.dreams,
    required this.goalsPerDream,
    required this.tasksPerGoal,
    required this.books,
  });

  final int dreams;
  final int goalsPerDream;
  final int tasksPerGoal;
  final int books;
}

/// 現在のレベルに応じた制限値を取得する.
_LevelConfig _currentConfig(int level) {
  if (level >= feedbackMaxLevel) {
    // レベル3以上: 無制限（十分大きな値）
    return const _LevelConfig(
      dreams: 999,
      goalsPerDream: 999,
      tasksPerGoal: 999,
      books: 999,
    );
  }
  return _levelLimits[level] ??
      const _LevelConfig(dreams: 2, goalsPerDream: 3, tasksPerGoal: 5, books: 5);
}

/// 体験版の制限値（レベル0のデフォルト値、表示用）.
int get trialMaxDreams => _levelLimits[0]!.dreams;
int get trialMaxGoalsPerDream => _levelLimits[0]!.goalsPerDream;
int get trialMaxTasksPerGoal => _levelLimits[0]!.tasksPerGoal;
int get trialMaxBooks => _levelLimits[0]!.books;

/// Web体験版かどうか.
bool get isTrialMode => kIsWeb;

/// 夢の追加が可能か判定する.
bool canAddDream({required int currentCount, int unlockLevel = 0}) {
  if (!isTrialMode) return true;
  return currentCount < _currentConfig(unlockLevel).dreams;
}

/// 目標の追加が可能か判定する.
bool canAddGoal({
  required int currentGoalCountForDream,
  int unlockLevel = 0,
}) {
  if (!isTrialMode) return true;
  return currentGoalCountForDream <
      _currentConfig(unlockLevel).goalsPerDream;
}

/// タスクの追加が可能か判定する.
bool canAddTask({
  required int currentTaskCountForGoal,
  int unlockLevel = 0,
}) {
  if (!isTrialMode) return true;
  return currentTaskCountForGoal <
      _currentConfig(unlockLevel).tasksPerGoal;
}

/// 書籍の追加が可能か判定する.
bool canAddBook({required int currentCount, int unlockLevel = 0}) {
  if (!isTrialMode) return true;
  return currentCount < _currentConfig(unlockLevel).books;
}

/// 指定レベルでの夢の上限数.
int maxDreams(int unlockLevel) => _currentConfig(unlockLevel).dreams;

/// 指定レベルでの目標の上限数.
int maxGoalsPerDream(int unlockLevel) =>
    _currentConfig(unlockLevel).goalsPerDream;

/// 指定レベルでのタスクの上限数.
int maxTasksPerGoal(int unlockLevel) =>
    _currentConfig(unlockLevel).tasksPerGoal;

/// 指定レベルでの書籍の上限数.
int maxBooks(int unlockLevel) => _currentConfig(unlockLevel).books;

/// 制限の説明テキストを取得する.
String trialLimitDescription({int unlockLevel = 0}) {
  if (unlockLevel >= feedbackMaxLevel) {
    return '制限は完全に解除されています。';
  }
  final config = _currentConfig(unlockLevel);
  return '現在の制限（レベル$unlockLevel / $feedbackMaxLevel）:\n'
      '- 夢: ${config.dreams}個まで\n'
      '- 目標: 各夢${config.goalsPerDream}個まで\n'
      '- タスク: 各目標${config.tasksPerGoal}個まで\n'
      '- 書籍: ${config.books}冊まで';
}
