import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/services/trial_limit_service.dart';

void main() {
  // テスト環境では kIsWeb == false なので isTrialMode は常に false
  group('TrialLimitService (非Web環境)', () {
    test('isTrialMode はテスト環境で false', () {
      expect(isTrialMode, isFalse);
    });

    test('非Web環境では夢の追加制限がない', () {
      expect(canAddDream(currentCount: 100), isTrue);
    });

    test('非Web環境では目標の追加制限がない', () {
      expect(canAddGoal(currentGoalCountForDream: 100), isTrue);
    });

    test('非Web環境ではタスクの追加制限がない', () {
      expect(canAddTask(currentTaskCountForGoal: 100), isTrue);
    });

    test('非Web環境では書籍の追加制限がない', () {
      expect(canAddBook(currentCount: 100), isTrue);
    });
  });

  group('制限値の定義', () {
    test('レベル0の夢の上限は2', () {
      expect(trialMaxDreams, 2);
      expect(maxDreams(0), 2);
    });

    test('レベル0の目標の上限は各夢3', () {
      expect(trialMaxGoalsPerDream, 3);
      expect(maxGoalsPerDream(0), 3);
    });

    test('レベル0のタスクの上限は各目標5', () {
      expect(trialMaxTasksPerGoal, 5);
      expect(maxTasksPerGoal(0), 5);
    });

    test('レベル0の書籍の上限は5', () {
      expect(trialMaxBooks, 5);
      expect(maxBooks(0), 5);
    });
  });

  group('段階的解除', () {
    test('レベル1で制限が緩和される', () {
      expect(maxDreams(1), 4);
      expect(maxGoalsPerDream(1), 5);
      expect(maxTasksPerGoal(1), 8);
      expect(maxBooks(1), 8);
    });

    test('レベル2でさらに緩和される', () {
      expect(maxDreams(2), 6);
      expect(maxGoalsPerDream(2), 8);
      expect(maxTasksPerGoal(2), 12);
      expect(maxBooks(2), 12);
    });

    test('レベル3で実質無制限', () {
      expect(maxDreams(3), 999);
      expect(maxGoalsPerDream(3), 999);
      expect(maxTasksPerGoal(3), 999);
      expect(maxBooks(3), 999);
    });
  });

  group('trialLimitDescription', () {
    test('レベル0の制限情報が含まれる', () {
      final desc = trialLimitDescription();
      expect(desc, contains('2'));
      expect(desc, contains('3'));
      expect(desc, contains('5'));
      expect(desc, contains('レベル0'));
    });

    test('レベル3では完全解除メッセージ', () {
      final desc = trialLimitDescription(unlockLevel: 3);
      expect(desc, contains('完全に解除'));
    });
  });
}
