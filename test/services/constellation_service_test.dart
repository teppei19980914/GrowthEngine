import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/data/constellations.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/services/constellation_service.dart';

void main() {
  late AppDatabase db;
  late ConstellationService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ConstellationService(
      studyLogDao: db.studyLogDao,
    );
  });

  tearDown(() => db.close());

  group('ConstellationService', () {
    test('活動ログがない場合は全星座の星が0個', () async {
      final result = await service.getOverallProgress();
      expect(result.constellations.length, 36);
      expect(result.totalLitStars, 0);
      expect(result.totalMinutes, 0);
      for (final c in result.constellations) {
        expect(c.litStarCount, 0);
      }
    });

    test('活動ログに応じて星が順番に点灯する', () async {
      final now = DateTime.now();

      // Goal → Task → StudyLog のチェーンを作成
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

      final result = await service.getOverallProgress();
      expect(result.totalMinutes, 600);
      expect(result.totalLitStars, 2);
      // 最初の星座（おひつじ座）に2つ点灯
      expect(result.constellations[0].litStarCount, 2);
      expect(result.constellations[1].litStarCount, 0);
    });

    test('最初の星座が完成すると次の星座に進む', () async {
      final now = DateTime.now();
      final firstStarCount = constellations[0].starCount;

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
      // 最初の星座を完成させ、さらに3つ分の時間を追加
      final totalMinutes = minutesPerStar * (firstStarCount + 3);
      await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
        id: const Value('log-1'),
        taskId: const Value('task-1'),
        studyDate: Value(now),
        durationMinutes: Value(totalMinutes),
        createdAt: Value(now),
      ));

      final result = await service.getOverallProgress();
      expect(result.constellations[0].isComplete, isTrue);
      expect(result.constellations[0].litStarCount, firstStarCount);
      expect(result.constellations[1].litStarCount, 3);
      expect(result.completedCount, 1);
    });

    test('calculateProgressで合計分から正しく計算される', () {
      // 0分: 全て0
      final zero = service.calculateProgress(0);
      expect(zero.totalLitStars, 0);

      // 最初の星座を完成させる分数
      final firstStars = constellations[0].starCount;
      final firstComplete =
          service.calculateProgress(minutesPerStar * firstStars);
      expect(firstComplete.constellations[0].isComplete, isTrue);
      expect(firstComplete.constellations[1].litStarCount, 0);
      expect(firstComplete.completedCount, 1);
    });

    test('全星座の星の総数が正しい', () {
      final result = service.calculateProgress(0);
      final expectedTotal =
          constellations.fold<int>(0, (sum, c) => sum + c.starCount);
      expect(result.totalStars, expectedTotal);
    });

    test('大量の活動時間でも星の総数を超えない', () {
      final totalStars =
          constellations.fold<int>(0, (sum, c) => sum + c.starCount);
      final result =
          service.calculateProgress(minutesPerStar * (totalStars + 100));
      expect(result.totalLitStars, totalStars);
      for (final c in result.constellations) {
        expect(c.isComplete, isTrue);
      }
      expect(result.completedCount, 36);
    });
  });

  group('StudyLogDao.getTotalMinutes', () {
    test('ログがない場合は0を返す', () async {
      final total = await db.studyLogDao.getTotalMinutes();
      expect(total, 0);
    });

    test('全ログの合計時間を返す', () async {
      final now = DateTime.now();
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
        title: const Value('タスク'),
        startDate: Value(now),
        endDate: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
        id: const Value('log-1'),
        taskId: const Value('task-1'),
        studyDate: Value(now),
        durationMinutes: const Value(120),
        createdAt: Value(now),
      ));
      await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
        id: const Value('log-2'),
        taskId: const Value('task-1'),
        studyDate: Value(now),
        durationMinutes: const Value(180),
        createdAt: Value(now),
      ));

      final total = await db.studyLogDao.getTotalMinutes();
      expect(total, 300);
    });
  });
}
