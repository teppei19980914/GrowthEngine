import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/services/tutorial_service.dart';

void main() {
  late TutorialService service;

  Future<TutorialService> createService([
    Map<String, Object> initialValues = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    return TutorialService(prefs);
  }

  group('初期状態', () {
    test('チュートリアルは非アクティブ', () async {
      service = await createService();
      expect(service.isActive, isFalse);
    });

    test('初期ステップはgoToDreams', () async {
      service = await createService();
      expect(service.currentStep, TutorialStep.goToDreams);
    });

    test('チュートリアルデータIDはnull', () async {
      service = await createService();
      expect(service.tutorialDreamId, isNull);
      expect(service.tutorialGoalId, isNull);
    });
  });

  group('start', () {
    test('チュートリアルを開始するとアクティブになる', () async {
      service = await createService();
      await service.start();
      expect(service.isActive, isTrue);
      expect(service.currentStep, TutorialStep.goToDreams);
    });

    test('再開始するとステップがリセットされる', () async {
      service = await createService({
        'tutorial_active': true,
        'tutorial_step': 3,
      });
      await service.start();
      expect(service.currentStep, TutorialStep.goToDreams);
    });
  });

  group('advanceStep', () {
    test('ステップが順に進む', () async {
      service = await createService();
      await service.start();

      expect(service.currentStep, TutorialStep.goToDreams);

      await service.advanceStep();
      expect(service.currentStep, TutorialStep.addDream);

      await service.advanceStep();
      expect(service.currentStep, TutorialStep.goToGoals);

      await service.advanceStep();
      expect(service.currentStep, TutorialStep.addGoal);

      await service.advanceStep();
      expect(service.currentStep, TutorialStep.goToGantt);

      await service.advanceStep();
      expect(service.currentStep, TutorialStep.addTask);

      await service.advanceStep();
      expect(service.currentStep, TutorialStep.explainAppBar);

      await service.advanceStep();
      expect(service.currentStep, TutorialStep.completed);
    });
  });

  group('progress', () {
    test('進捗が正しく計算される', () async {
      service = await createService();
      await service.start();

      // 8ステップ (goToDreams, addDream, goToGoals, addGoal, goToGantt, addTask, explainAppBar, completed)
      expect(service.progress, 0.0); // 0/7

      await service.advanceStep();
      expect(service.progress, closeTo(1 / 7, 0.01)); // 1/7

      await service.advanceStep();
      expect(service.progress, closeTo(2 / 7, 0.01)); // 2/7
    });
  });

  group('データID管理', () {
    test('夢IDを記録できる', () async {
      service = await createService();
      await service.setTutorialDreamId('dream-123');
      expect(service.tutorialDreamId, 'dream-123');
    });

    test('目標IDを記録できる', () async {
      service = await createService();
      await service.setTutorialGoalId('goal-456');
      expect(service.tutorialGoalId, 'goal-456');
    });
  });

  group('finish', () {
    test('終了するとアクティブではなくなる', () async {
      service = await createService();
      await service.start();
      await service.setTutorialDreamId('dream-123');
      await service.setTutorialGoalId('goal-456');

      await service.finish();

      expect(service.isActive, isFalse);
      expect(service.tutorialDreamId, isNull);
      expect(service.tutorialGoalId, isNull);
    });
  });

  group('clearDataIds', () {
    test('データIDのみクリアされる', () async {
      service = await createService();
      await service.start();
      await service.setTutorialDreamId('dream-123');
      await service.setTutorialGoalId('goal-456');

      await service.clearDataIds();

      expect(service.isActive, isTrue);
      expect(service.tutorialDreamId, isNull);
      expect(service.tutorialGoalId, isNull);
    });
  });

  group('TutorialStep', () {
    test('各ステップにinstructionとhintがある', () {
      for (final step in TutorialStep.values) {
        expect(step.instruction, isNotEmpty);
        expect(step.hint, isNotEmpty);
      }
    });
  });
}
