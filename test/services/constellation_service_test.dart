import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/data/constellations.dart';
import 'package:yume_log/database/app_database.dart' hide Dream;
import 'package:yume_log/models/dream.dart';
import 'package:yume_log/services/constellation_service.dart';

void main() {
  late AppDatabase db;
  late ConstellationService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ConstellationService(
      goalDao: db.goalDao,
      taskDao: db.taskDao,
      studyLogDao: db.studyLogDao,
    );
  });

  tearDown(() => db.close());

  group('ConstellationService', () {
    test('夢がない場合は空リスト', () async {
      final result = await service.getAllProgress([]);
      expect(result, isEmpty);
    });

    test('学習ログがない場合は星が0個', () async {
      final dreams = [Dream(id: 'dream-1', title: 'Test')];

      final result = await service.getAllProgress(dreams);
      expect(result.length, 1);
      expect(result[0].litStarCount, 0);
      expect(result[0].totalMinutes, 0);
      expect(result[0].constellation.id, constellations[0].id);
    });

    test('学習ログに応じて星が点灯する', () async {
      final now = DateTime.now();
      final dreams = [Dream(id: 'dream-1', title: 'Test')];

      // Dream → Goal → Task → StudyLog のチェーンを作成
      await db.goalDao.insertGoal(GoalsCompanion(
        id: const Value('goal-1'),
        dreamId: const Value('dream-1'),
        why: const Value('テスト'),
        whenTarget: const Value('2026年末'),
        whenType: const Value('date'),
        what: const Value('テスト'),
        how: const Value('テスト'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.taskDao.insertTask(TasksCompanion(
        id: const Value('task-1'),
        goalId: const Value('goal-1'),
        title: const Value('テストタスク'),
        startDate: Value(now),
        endDate: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      // 600分 = 10時間 → 2つの星が点灯 (minutesPerStar=300)
      await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
        id: const Value('log-1'),
        taskId: const Value('task-1'),
        studyDate: Value(now),
        durationMinutes: const Value(600),
        createdAt: Value(now),
      ));

      final result = await service.getAllProgress(dreams);
      expect(result[0].totalMinutes, 600);
      expect(result[0].litStarCount, 2);
    });

    test('複数のDreamに異なる星座が割り当てられる', () async {
      final dreams = [
        Dream(id: 'dream-1', title: 'Dream A'),
        Dream(id: 'dream-2', title: 'Dream B'),
      ];

      final result = await service.getAllProgress(dreams);
      expect(result[0].constellation.id, constellations[0].id);
      expect(result[1].constellation.id, constellations[1].id);
    });

    test('星の数は星座の上限を超えない', () async {
      final now = DateTime.now();
      final dreams = [Dream(id: 'dream-1', title: 'Test')];
      final starCount = constellations[0].starCount;

      await db.goalDao.insertGoal(GoalsCompanion(
        id: const Value('goal-1'),
        dreamId: const Value('dream-1'),
        why: const Value('テスト'),
        whenTarget: const Value('2026年末'),
        whenType: const Value('date'),
        what: const Value('テスト'),
        how: const Value('テスト'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.taskDao.insertTask(TasksCompanion(
        id: const Value('task-1'),
        goalId: const Value('goal-1'),
        title: const Value('テストタスク'),
        startDate: Value(now),
        endDate: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      // 大量の学習時間
      await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
        id: const Value('log-1'),
        taskId: const Value('task-1'),
        studyDate: Value(now),
        durationMinutes: Value(minutesPerStar * (starCount + 10)),
        createdAt: Value(now),
      ));

      final result = await service.getAllProgress(dreams);
      expect(result[0].litStarCount, starCount);
      expect(result[0].isComplete, isTrue);
    });
  });
}
