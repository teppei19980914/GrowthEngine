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
  goToDreams(
    '画面下の「夢」タブをタップしてください',
    '下部ナビゲーションバーの ✨ アイコンが「夢」ページです',
  ),

  /// 夢を追加.
  addDream(
    '右上の「夢を追加」ボタンをタップしてください',
    'タイトルを入力するだけでOK！説明や理由は後から編集できます',
  ),

  /// 目標ページへ移動.
  goToGoals(
    '画面下の「目標」タブをタップしてください',
    '下部ナビゲーションバーの 🚩 アイコンが「目標」ページです',
  ),

  /// 目標を追加.
  addGoal(
    '右上の「目標を追加」ボタンをタップしてください',
    '夢に紐づく具体的な目標を設定します。What・When・Howを入力してください',
  ),

  /// ガントチャートページへ移動.
  goToGantt(
    '画面下の「ガントチャート」タブをタップしてください',
    '下部ナビゲーションバーのタイムラインアイコンが「ガントチャート」ページです',
  ),

  /// タスクを追加.
  addTask(
    'ドロップダウンから目標を選び「タスクを追加」をタップ',
    '左上のプルダウンで先ほど作成した目標を選択すると、追加ボタンが表示されます',
  ),

  /// 画面右上アイコンの説明.
  explainAppBar(
    '画面右上のアイコンを確認しましょう',
    '各アイコンの役割を紹介します。「次へ」で進めてください',
  ),

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
