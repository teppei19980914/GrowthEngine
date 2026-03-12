import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/services/trial_limit_service.dart';

void main() {
  // テスト環境では kIsWeb == false なので isTrialMode は常に false
  group('TrialLimitService (非Web環境)', () {
    test('isTrialMode はテスト環境で false', () {
      expect(isTrialMode, isFalse);
    });

    test('isPremium はテスト環境で true（非Web=ネイティブ）', () {
      expect(isPremium, isTrue);
    });

    test('非Web環境ではガントチャート利用可能', () {
      expect(canUseGanttChart, isTrue);
    });

    test('非Web環境では高度な統計利用可能', () {
      expect(canUseAdvancedStats, isTrue);
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
    test('レベル0の夢の上限は1', () {
      expect(trialMaxDreams, 1);
      expect(maxDreams(0), 1);
    });

    test('レベル0の目標の上限は各夢2', () {
      expect(trialMaxGoalsPerDream, 2);
      expect(maxGoalsPerDream(0), 2);
    });

    test('レベル0のタスクの上限は各目標3', () {
      expect(trialMaxTasksPerGoal, 3);
      expect(maxTasksPerGoal(0), 3);
    });

    test('レベル0の書籍の上限は3', () {
      expect(trialMaxBooks, 3);
      expect(maxBooks(0), 3);
    });
  });

  group('段階的解除', () {
    test('レベル1で制限が緩和される', () {
      expect(maxDreams(1), 2);
      expect(maxGoalsPerDream(1), 3);
      expect(maxTasksPerGoal(1), 5);
      expect(maxBooks(1), 5);
    });

    test('レベル2でさらに緩和される', () {
      expect(maxDreams(2), 3);
      expect(maxGoalsPerDream(2), 5);
      expect(maxTasksPerGoal(2), 8);
      expect(maxBooks(2), 8);
    });

    test('レベル3で実質無制限（基本機能）', () {
      expect(maxDreams(3), 999);
      expect(maxGoalsPerDream(3), 999);
      expect(maxTasksPerGoal(3), 999);
      expect(maxBooks(3), 999);
    });
  });

  group('trialLimitDescription', () {
    test('レベル0の制限情報が含まれる', () {
      final desc = trialLimitDescription();
      expect(desc, contains('1'));
      expect(desc, contains('2'));
      expect(desc, contains('3'));
      expect(desc, contains('レベル0'));
    });

    test('レベル3では完全解除メッセージ', () {
      final desc = trialLimitDescription(unlockLevel: 3);
      expect(desc, contains('完全に解除'));
    });
  });
}
