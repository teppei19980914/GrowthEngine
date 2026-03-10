/// インタラクティブチュートリアル管理.
///
/// ユーザーに実際の操作を行わせながら進める体験型ガイド.
/// チュートリアル中に作成されたデータを追跡し、
/// 完了時に保持または削除を選択できる.
library;

import 'package:shared_preferences/shared_preferences.dart';

const _tutorialActiveKey = 'tutorial_active';
const _tutorialStepKey = 'tutorial_step';
const _tutorialDreamIdKey = 'tutorial_dream_id';
const _tutorialGoalIdKey = 'tutorial_goal_id';

/// チュートリアルのステップ.
enum TutorialStep {
  /// 夢ページへ移動.
  goToDreams('「夢」ページを開いてください', 'メニュー（≡）から「夢」をタップ'),

  /// 夢を追加.
  addDream('「夢を追加」ボタンをタップしてください', '自由にタイトルと説明を入力して追加'),

  /// 目標ページへ移動.
  goToGoals('「目標」ページを開いてください', 'メニュー（≡）から「目標」をタップ'),

  /// 目標を追加.
  addGoal('「目標を追加」ボタンをタップしてください', '各項目を入力して追加'),

  /// ガントチャートページへ移動.
  goToGantt('「ガントチャート」ページを開いてください', 'メニュー（≡）から「ガントチャート」をタップ'),

  /// タスクを追加.
  addTask('「＋」ボタンでタスクを追加してください', '目標の横の「＋」をタップしてタスクを登録'),

  /// 完了.
  completed('チュートリアル完了！', 'アプリの基本的な使い方を体験しました');

  const TutorialStep(this.instruction, this.hint);

  /// メインの指示テキスト.
  final String instruction;

  /// 補足ヒント.
  final String hint;
}

/// チュートリアル管理サービス.
class TutorialService {
  /// TutorialServiceを作成する.
  TutorialService(this._prefs);

  final SharedPreferences _prefs;

  /// チュートリアルが実行中か.
  bool get isActive => _prefs.getBool(_tutorialActiveKey) ?? false;

  /// 現在のステップ.
  TutorialStep get currentStep {
    final index = _prefs.getInt(_tutorialStepKey) ?? 0;
    if (index >= TutorialStep.values.length) return TutorialStep.completed;
    return TutorialStep.values[index];
  }

  /// ステップの進捗（0.0〜1.0）.
  double get progress {
    final index = _prefs.getInt(_tutorialStepKey) ?? 0;
    return index / (TutorialStep.values.length - 1);
  }

  /// チュートリアルで作成した夢のID.
  String? get tutorialDreamId => _prefs.getString(_tutorialDreamIdKey);

  /// チュートリアルで作成した目標のID.
  String? get tutorialGoalId => _prefs.getString(_tutorialGoalIdKey);

  /// チュートリアルを開始する.
  Future<void> start() async {
    await _prefs.setBool(_tutorialActiveKey, true);
    await _prefs.setInt(_tutorialStepKey, 0);
    await _prefs.remove(_tutorialDreamIdKey);
    await _prefs.remove(_tutorialGoalIdKey);
  }

  /// 次のステップに進む.
  Future<void> advanceStep() async {
    final current = _prefs.getInt(_tutorialStepKey) ?? 0;
    final next = current + 1;
    await _prefs.setInt(_tutorialStepKey, next);
    if (next >= TutorialStep.values.length - 1) {
      // completed ステップに到達
    }
  }

  /// チュートリアルで作成した夢のIDを記録する.
  Future<void> setTutorialDreamId(String dreamId) async {
    await _prefs.setString(_tutorialDreamIdKey, dreamId);
  }

  /// チュートリアルで作成した目標のIDを記録する.
  Future<void> setTutorialGoalId(String goalId) async {
    await _prefs.setString(_tutorialGoalIdKey, goalId);
  }

  /// チュートリアルを終了する.
  Future<void> finish() async {
    await _prefs.setBool(_tutorialActiveKey, false);
    await _prefs.remove(_tutorialStepKey);
    await _prefs.remove(_tutorialDreamIdKey);
    await _prefs.remove(_tutorialGoalIdKey);
  }

  /// チュートリアルのデータIDをクリアする（データ保持時）.
  Future<void> clearDataIds() async {
    await _prefs.remove(_tutorialDreamIdKey);
    await _prefs.remove(_tutorialGoalIdKey);
  }
}
