/// チュートリアルスポットライト対象ウィジェットのGlobalKey管理.
///
/// 各チュートリアルステップで操作対象となるウィジェットに
/// GlobalKeyを付与し、オーバーレイからの位置取得を可能にする.
library;

import 'package:flutter/material.dart';

/// チュートリアル対象ウィジェットのGlobalKeyレジストリ.
class TutorialTargetKeys {
  TutorialTargetKeys._();

  /// ボトムナビ「夢」タブ.
  static final dreamTab = GlobalKey(debugLabel: 'tutorial_dream_tab');

  /// ボトムナビ「目標」タブ.
  static final goalTab = GlobalKey(debugLabel: 'tutorial_goal_tab');

  /// 「夢を追加」ボタン.
  static final addDreamButton = GlobalKey(debugLabel: 'tutorial_add_dream');

  /// 「目標を追加」ボタン.
  static final addGoalButton = GlobalKey(debugLabel: 'tutorial_add_goal');

  /// ボトムナビ「ガントチャート」タブ.
  static final ganttTab = GlobalKey(debugLabel: 'tutorial_gantt_tab');

  /// ハンバーガーメニューボタン.
  static final menuButton = GlobalKey(debugLabel: 'tutorial_menu');

  /// ドロワー内「ガントチャート」項目.
  static final ganttDrawerItem =
      GlobalKey(debugLabel: 'tutorial_gantt_drawer');

  /// ガントチャートの目標ドロップダウン.
  static final ganttDropdown = GlobalKey(debugLabel: 'tutorial_gantt_dropdown');

  /// 「タスクを追加」ボタン.
  static final addTaskButton = GlobalKey(debugLabel: 'tutorial_add_task');

  /// 夢追加ダイアログの「追加」ボタン.
  static final dreamDialogSubmit =
      GlobalKey(debugLabel: 'tutorial_dream_dialog_submit');

  /// 目標追加ダイアログの「追加」ボタン.
  static final goalDialogSubmit =
      GlobalKey(debugLabel: 'tutorial_goal_dialog_submit');

  /// アプリのNavigatorKey（ダイアログ表示に使用）.
  static final navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'app_navigator');
}
