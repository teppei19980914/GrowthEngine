/// タスク発見ガイド用のテンプレート・質問データ.
library;

/// タスクテンプレート.
class TaskTemplate {
  /// TaskTemplateを作成する.
  const TaskTemplate({
    required this.title,
    required this.description,
    required this.suggestedDurationDays,
  });

  /// タスク名.
  final String title;

  /// タスクの説明.
  final String description;

  /// 推奨日数.
  final int suggestedDurationDays;
}

/// 目標カテゴリに応じたタスクテンプレート.
const Map<String, List<TaskTemplate>> taskTemplatesByGoalCategory = {
  'career': [
    TaskTemplate(
      title: 'オンライン講座を1レッスン受講する',
      description: '毎日1レッスンずつ進め、学んだ内容をノートにまとめる',
      suggestedDurationDays: 7,
    ),
    TaskTemplate(
      title: '業界ニュースを読む',
      description: '毎朝15分、関連分野の最新記事を読んで知識をアップデートする',
      suggestedDurationDays: 14,
    ),
    TaskTemplate(
      title: 'ポートフォリオ用の作品を1つ作る',
      description: '学んだスキルを使って小さな成果物を完成させる',
      suggestedDurationDays: 14,
    ),
    TaskTemplate(
      title: '勉強会・イベントに参加する',
      description: '関連コミュニティのイベントを探して参加申し込みをする',
      suggestedDurationDays: 7,
    ),
  ],
  'learning': [
    TaskTemplate(
      title: '参考書を1章読む',
      description: '1章を読み終え、章末問題を解いて理解度を確認する',
      suggestedDurationDays: 7,
    ),
    TaskTemplate(
      title: '過去問を1年分解く',
      description: '制限時間内に解き、間違えた問題を復習ノートにまとめる',
      suggestedDurationDays: 3,
    ),
    TaskTemplate(
      title: '暗記カードを30枚作成・復習する',
      description: '重要用語や公式を暗記カードにして毎日復習する',
      suggestedDurationDays: 7,
    ),
    TaskTemplate(
      title: '模試を受けて弱点を分析する',
      description: '模試の結果をもとに苦手分野を特定し、対策計画を立てる',
      suggestedDurationDays: 3,
    ),
  ],
  'health': [
    TaskTemplate(
      title: '30分のウォーキングをする',
      description: '毎日30分、近所を歩いて運動習慣をつくる',
      suggestedDurationDays: 14,
    ),
    TaskTemplate(
      title: '自炊で健康的な食事を作る',
      description: '野菜中心のメニューを考え、自炊する回数を増やす',
      suggestedDurationDays: 7,
    ),
    TaskTemplate(
      title: '就寝前のルーティンを実践する',
      description: '決まった時間にスマホを置き、ストレッチや読書でリラックスする',
      suggestedDurationDays: 14,
    ),
    TaskTemplate(
      title: '体重・体調を記録する',
      description: '毎朝体重と体調をメモして変化を可視化する',
      suggestedDurationDays: 30,
    ),
  ],
  'finance': [
    TaskTemplate(
      title: '今週の支出を記録する',
      description: 'レシートを集め、カテゴリ別に支出を記録する',
      suggestedDurationDays: 7,
    ),
    TaskTemplate(
      title: '固定費を見直す',
      description: 'サブスクや保険など固定費をリストアップし、削減できるものを探す',
      suggestedDurationDays: 3,
    ),
    TaskTemplate(
      title: '投資の基礎を本1冊で学ぶ',
      description: '初心者向けの投資本を1冊読み、要点をまとめる',
      suggestedDurationDays: 14,
    ),
    TaskTemplate(
      title: '月間予算を作成する',
      description: '収入と支出を把握して、来月の予算計画を立てる',
      suggestedDurationDays: 3,
    ),
  ],
  'hobby': [
    TaskTemplate(
      title: '基礎練習を30分行う',
      description: '教本やチュートリアルに沿って基本技術を練習する',
      suggestedDurationDays: 14,
    ),
    TaskTemplate(
      title: '小さな作品を1つ完成させる',
      description: '完璧を目指さず、まず1つ形にすることを目標にする',
      suggestedDurationDays: 7,
    ),
    TaskTemplate(
      title: '上手な人の作品を分析する',
      description: '参考になる作品を見つけて、技術やポイントを書き出す',
      suggestedDurationDays: 3,
    ),
    TaskTemplate(
      title: 'SNSやコミュニティで活動を共有する',
      description: '練習の成果や作品を投稿してフィードバックをもらう',
      suggestedDurationDays: 7,
    ),
  ],
  'relationship': [
    TaskTemplate(
      title: '大切な人に連絡を取る',
      description: '普段会えない人にメッセージや電話で近況を伝える',
      suggestedDurationDays: 3,
    ),
    TaskTemplate(
      title: '一緒に過ごす時間を計画する',
      description: '週末の予定を相手と相談して、共有する時間を作る',
      suggestedDurationDays: 7,
    ),
    TaskTemplate(
      title: '感謝の気持ちを伝える',
      description: '毎日1つ、相手の良いところや感謝を言葉にして伝える',
      suggestedDurationDays: 14,
    ),
  ],
  'travel': [
    TaskTemplate(
      title: '行き先の情報をリサーチする',
      description: '観光スポット、交通手段、宿泊先を調べてメモする',
      suggestedDurationDays: 7,
    ),
    TaskTemplate(
      title: '旅行の予算を計算する',
      description: '交通費、宿泊費、食費、お土産代を見積もる',
      suggestedDurationDays: 3,
    ),
    TaskTemplate(
      title: '旅行資金を積み立てる',
      description: '目標金額を日割りにして、毎日少しずつ貯める',
      suggestedDurationDays: 30,
    ),
    TaskTemplate(
      title: '持ち物リストを作成する',
      description: '必要な持ち物をリストアップし、足りないものを準備する',
      suggestedDurationDays: 3,
    ),
  ],
};

/// 汎用のタスクテンプレート（カテゴリ不明の場合）.
const List<TaskTemplate> genericTaskTemplates = [
  TaskTemplate(
    title: '情報収集をする',
    description: '関連する本や記事を読んで、必要な知識を集める',
    suggestedDurationDays: 7,
  ),
  TaskTemplate(
    title: '小さな一歩を踏み出す',
    description: '今日できる最小限のアクションを1つ実行する',
    suggestedDurationDays: 3,
  ),
  TaskTemplate(
    title: '進捗を振り返る',
    description: '今週やったことを書き出し、次にやることを決める',
    suggestedDurationDays: 7,
  ),
  TaskTemplate(
    title: '環境を整える',
    description: '目標達成に集中できるよう、作業環境や道具を準備する',
    suggestedDurationDays: 3,
  ),
];

/// タスク発見ガイド用の質問.
class TaskGuideQuestion {
  /// TaskGuideQuestionを作成する.
  const TaskGuideQuestion({
    required this.question,
    required this.hints,
  });

  /// 質問文.
  final String question;

  /// ヒント選択肢.
  final List<String> hints;
}

/// 目標をタスクに分解するための質問.
const List<TaskGuideQuestion> taskGuideQuestions = [
  TaskGuideQuestion(
    question: 'この目標を達成するために、毎日できることは何ですか？',
    hints: ['読書・学習', '練習・トレーニング', '記録・振り返り', '人に会う・相談する'],
  ),
  TaskGuideQuestion(
    question: '最初の1週間で達成できる小さなゴールは？',
    hints: ['必要な道具を揃える', '計画を立てる', '基礎を学ぶ', '環境を整える'],
  ),
  TaskGuideQuestion(
    question: 'つまずきそうなポイントはどこですか？',
    hints: ['時間が足りない', 'モチベーション維持', '何から始めるか分からない', '1人では難しい'],
  ),
];
