import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/services/tutorial_service.dart';
import 'package:yume_hashi/widgets/tutorial/tutorial_banner.dart';

void main() {
  group('TutorialState', () {
    test('inactiveファクトリが正しい初期値を返す', () {
      const state = TutorialState.inactive;
      expect(state.isActive, isFalse);
      expect(state.step, TutorialStep.goToDreams);
    });

    test('カスタム状態を作成できる', () {
      const state = TutorialState(
        isActive: true,
        step: TutorialStep.addDream,
      );
      expect(state.isActive, isTrue);
      expect(state.step, TutorialStep.addDream);
    });
  });

  group('TutorialStateNotifier', () {
    late TutorialService service;
    late TutorialStateNotifier notifier;

    Future<void> setUp() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = TutorialService(prefs);
      notifier = TutorialStateNotifier(service);
    }

    test('初期状態はinactive', () async {
      await setUp();
      expect(notifier.state.isActive, isFalse);
    });

    test('startでチュートリアルが開始される', () async {
      await setUp();
      await notifier.start();
      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.step, TutorialStep.goToDreams);
    });

    test('advanceStepでステップが進む', () async {
      await setUp();
      await notifier.start();
      await notifier.advanceStep();
      expect(notifier.state.step, TutorialStep.addDream);
    });

    test('非アクティブ時にadvanceStepを呼んでも何もしない', () async {
      await setUp();
      await notifier.advanceStep();
      expect(notifier.state.isActive, isFalse);
      expect(notifier.state.step, TutorialStep.goToDreams);
    });

    test('resetで非アクティブに戻る', () async {
      await setUp();
      await notifier.start();
      notifier.reset();
      expect(notifier.state.isActive, isFalse);
    });

    test('全ステップを順に進行できる', () async {
      await setUp();
      await notifier.start();

      final expectedSteps = [
        TutorialStep.addDream,
        TutorialStep.goToGoals,
        TutorialStep.addGoal,
        TutorialStep.goToGantt,
        TutorialStep.addTask,
        TutorialStep.explainAppBar,
        TutorialStep.completed,
      ];

      for (final expected in expectedSteps) {
        await notifier.advanceStep();
        expect(notifier.state.step, expected);
      }
    });

    test('既にアクティブなサービスから初期化すると状態が復元される', () async {
      SharedPreferences.setMockInitialValues({
        'tutorial_active': true,
        'tutorial_step': 2,
      });
      final prefs = await SharedPreferences.getInstance();
      service = TutorialService(prefs);
      notifier = TutorialStateNotifier(service);

      expect(notifier.state.isActive, isTrue);
      expect(notifier.state.step, TutorialStep.goToGoals);
    });
  });
}
