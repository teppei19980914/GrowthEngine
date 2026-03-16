import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/widgets/tutorial/tutorial_target_keys.dart';

void main() {
  group('TutorialTargetKeys', () {
    test('全てのキーがGlobalKeyである', () {
      final keys = <GlobalKey>[
        TutorialTargetKeys.dreamTab,
        TutorialTargetKeys.goalTab,
        TutorialTargetKeys.ganttTab,
        TutorialTargetKeys.addDreamButton,
        TutorialTargetKeys.addGoalButton,
        TutorialTargetKeys.menuButton,
        TutorialTargetKeys.ganttDrawerItem,
        TutorialTargetKeys.ganttDropdown,
        TutorialTargetKeys.addTaskButton,
        TutorialTargetKeys.dreamDialogSubmit,
        TutorialTargetKeys.goalDialogSubmit,
      ];

      for (final key in keys) {
        expect(key, isA<GlobalKey>());
      }
    });

    test('全てのキーが一意である', () {
      final keys = <GlobalKey>[
        TutorialTargetKeys.dreamTab,
        TutorialTargetKeys.goalTab,
        TutorialTargetKeys.ganttTab,
        TutorialTargetKeys.addDreamButton,
        TutorialTargetKeys.addGoalButton,
        TutorialTargetKeys.menuButton,
        TutorialTargetKeys.ganttDrawerItem,
        TutorialTargetKeys.ganttDropdown,
        TutorialTargetKeys.addTaskButton,
        TutorialTargetKeys.dreamDialogSubmit,
        TutorialTargetKeys.goalDialogSubmit,
      ];

      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, keys.length);
    });

    test('全てのキーにdebugLabelが設定されている', () {
      final keys = <GlobalKey>[
        TutorialTargetKeys.dreamTab,
        TutorialTargetKeys.goalTab,
        TutorialTargetKeys.ganttTab,
        TutorialTargetKeys.addDreamButton,
        TutorialTargetKeys.addGoalButton,
        TutorialTargetKeys.menuButton,
        TutorialTargetKeys.ganttDrawerItem,
        TutorialTargetKeys.ganttDropdown,
        TutorialTargetKeys.addTaskButton,
        TutorialTargetKeys.dreamDialogSubmit,
        TutorialTargetKeys.goalDialogSubmit,
      ];

      for (final key in keys) {
        expect(key.toString(), contains('tutorial_'));
      }
    });
  });
}
