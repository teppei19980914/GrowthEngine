/// 目標発見ガイド用のテンプレート・質問データ.
library;

/// 目標テンプレート.
class GoalTemplate {
  /// GoalTemplateを作成する.
  const GoalTemplate({
    required this.what,
    required this.how,
    required this.suggestedPeriod,
  });

  /// What（何を）.
  final String what;

  /// How（どうやって）.
  final String how;

  /// 推奨期間.
  final String suggestedPeriod;
}

/// 夢カテゴリに応じた目標テンプレート.
const Map<String, List<GoalTemplate>> goalTemplatesByDreamCategory = {
  'career': [
    GoalTemplate(
      what: '必要なスキルを習得する',
      how: '毎日1時間の学習時間を確保し、オンライン講座で体系的に学ぶ',
      suggestedPeriod: '3ヶ月',
    ),
    GoalTemplate(
      what: 'ポートフォリオを作成する',
      how: '学んだスキルを活かして実際の成果物を3つ以上作る',
      suggestedPeriod: '2ヶ月',
    ),
    GoalTemplate(
      what: '業界の人脈を広げる',
      how: '勉強会やイベントに月1回以上参加する',
      suggestedPeriod: '6ヶ月',
    ),
  ],
  'learning': [
    GoalTemplate(
      what: '試験範囲の基礎を固める',
      how: '参考書を1周し、各章の演習問題を解く',
      suggestedPeriod: '2ヶ月',
    ),
    GoalTemplate(
      what: '過去問を繰り返し解く',
      how: '過去5年分の問題を3回繰り返す',
      suggestedPeriod: '1ヶ月',
    ),
    GoalTemplate(
      what: '弱点分野を克服する',
      how: '模試の結果から弱点を分析し、集中的に対策する',
      suggestedPeriod: '1ヶ月',
    ),
  ],
  'health': [
    GoalTemplate(
      what: '運動習慣を身につける',
      how: '週3回、30分以上の運動を継続する',
      suggestedPeriod: '3ヶ月',
    ),
    GoalTemplate(
      what: '食生活を改善する',
      how: '自炊を増やし、栄養バランスを意識した食事を心がける',
      suggestedPeriod: '1ヶ月',
    ),
    GoalTemplate(
      what: '睡眠の質を向上させる',
      how: '就寝時間を固定し、寝る前のスマホ使用を控える',
      suggestedPeriod: '1ヶ月',
    ),
  ],
  'finance': [
    GoalTemplate(
      what: '毎月の支出を把握する',
      how: '家計簿をつけて支出を分類・可視化する',
      suggestedPeriod: '1ヶ月',
    ),
    GoalTemplate(
      what: '貯蓄目標を達成する',
      how: '毎月の収入から一定額を先取り貯蓄する',
      suggestedPeriod: '6ヶ月',
    ),
    GoalTemplate(
      what: '資産運用の知識を身につける',
      how: '投資の基礎を書籍やセミナーで学ぶ',
      suggestedPeriod: '2ヶ月',
    ),
  ],
  'hobby': [
    GoalTemplate(
      what: '基本技術を習得する',
      how: '教本やチュートリアルに沿って基礎練習を毎日行う',
      suggestedPeriod: '2ヶ月',
    ),
    GoalTemplate(
      what: '作品を1つ完成させる',
      how: '制作スケジュールを立てて計画的に取り組む',
      suggestedPeriod: '1ヶ月',
    ),
    GoalTemplate(
      what: '同じ趣味の仲間を見つける',
      how: 'コミュニティやSNSで活動を共有する',
      suggestedPeriod: '3ヶ月',
    ),
  ],
  'relationship': [
    GoalTemplate(
      what: '大切な人との時間を増やす',
      how: '週に1回は一緒に過ごす時間を作る',
      suggestedPeriod: '1ヶ月',
    ),
    GoalTemplate(
      what: 'コミュニケーション力を高める',
      how: '相手の話を最後まで聞き、感謝を言葉にする習慣をつける',
      suggestedPeriod: '3ヶ月',
    ),
  ],
  'travel': [
    GoalTemplate(
      what: '旅行の計画を立てる',
      how: '行き先・予算・日程をリサーチして計画書を作る',
      suggestedPeriod: '1ヶ月',
    ),
    GoalTemplate(
      what: '旅行資金を貯める',
      how: '目標金額を設定し、毎月積み立てる',
      suggestedPeriod: '6ヶ月',
    ),
  ],
};

/// 汎用の目標テンプレート（夢なし or カテゴリ不明の場合）.
const List<GoalTemplate> genericGoalTemplates = [
  GoalTemplate(
    what: '新しいことを1つ始める',
    how: '興味があることをリストアップし、一番気になるものから始める',
    suggestedPeriod: '1ヶ月',
  ),
  GoalTemplate(
    what: '毎日の習慣を1つ作る',
    how: '小さな行動を決めて、毎日同じ時間に実行する',
    suggestedPeriod: '1ヶ月',
  ),
  GoalTemplate(
    what: '知識を深める本を読む',
    how: '月に1冊、興味のある分野の本を読み切る',
    suggestedPeriod: '3ヶ月',
  ),
];

/// 夢に基づく目標の考え方を促す質問.
const List<GoalGuideQuestion> goalGuideQuestions = [
  GoalGuideQuestion(
    question: 'その夢を実現するために、まず何が必要ですか？',
    hints: ['知識やスキル', '時間や環境', '人とのつながり', '資金や道具'],
  ),
  GoalGuideQuestion(
    question: '今の自分に足りていないものは何ですか？',
    hints: ['経験', '自信', '具体的な計画', '継続する力'],
  ),
  GoalGuideQuestion(
    question: '半年後、どんな状態になっていたいですか？',
    hints: ['基礎ができている', '小さな成果が出ている', '習慣が身についている', '次のステップが見えている'],
  ),
];

/// ガイド用の質問.
class GoalGuideQuestion {
  /// GoalGuideQuestionを作成する.
  const GoalGuideQuestion({
    required this.question,
    required this.hints,
  });

  /// 質問文.
  final String question;

  /// ヒント選択肢.
  final List<String> hints;
}
