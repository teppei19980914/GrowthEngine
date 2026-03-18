/// 夢発見ガイド用のカテゴリ・テンプレート・質問データ.
library;

import 'package:flutter/material.dart';

/// 夢のカテゴリ.
enum DreamCategory {
  /// キャリア・仕事.
  career(
    label: 'キャリア・仕事',
    icon: Icons.work_outline,
    color: Color(0xFF89B4FA),
  ),

  /// 健康・体力.
  health(
    label: '健康・体力',
    icon: Icons.favorite_outline,
    color: Color(0xFFA6E3A1),
  ),

  /// 学習・資格.
  learning(
    label: '学習・資格',
    icon: Icons.school_outlined,
    color: Color(0xFFCBA6F7),
  ),

  /// 趣味・創作.
  hobby(
    label: '趣味・創作',
    icon: Icons.palette_outlined,
    color: Color(0xFFF9E2AF),
  ),

  /// 人間関係.
  relationships(
    label: '人間関係',
    icon: Icons.people_outline,
    color: Color(0xFFF38BA8),
  ),

  /// お金・資産.
  money(
    label: 'お金・資産',
    icon: Icons.savings_outlined,
    color: Color(0xFF94E2D5),
  ),

  /// ライフスタイル.
  lifestyle(
    label: 'ライフスタイル',
    icon: Icons.self_improvement,
    color: Color(0xFFFAB387),
  );

  const DreamCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  /// 表示名.
  final String label;

  /// アイコン.
  final IconData icon;

  /// テーマカラー.
  final Color color;
}

/// 夢テンプレート.
class DreamTemplate {
  /// DreamTemplateを作成する.
  const DreamTemplate({
    required this.title,
    required this.description,
    required this.suggestedWhy,
  });

  /// タイトル.
  final String title;

  /// 説明.
  final String description;

  /// 推奨のWhy.
  final String suggestedWhy;
}

/// カテゴリごとの夢テンプレート.
const Map<DreamCategory, List<DreamTemplate>> dreamTemplates = {
  DreamCategory.career: [
    DreamTemplate(
      title: '好きなことを仕事にする',
      description: '自分の興味や得意分野を活かせる仕事に就く',
      suggestedWhy: '毎日の仕事にやりがいを感じたいから',
    ),
    DreamTemplate(
      title: 'ITエンジニアになる',
      description: 'プログラミングスキルを身につけてIT業界で活躍する',
      suggestedWhy: 'テクノロジーで人の役に立つものを作りたいから',
    ),
    DreamTemplate(
      title: '独立・起業する',
      description: '自分のアイデアやスキルでビジネスを始める',
      suggestedWhy: '自分の力で価値を生み出したいから',
    ),
  ],
  DreamCategory.health: [
    DreamTemplate(
      title: '健康的な生活習慣を身につける',
      description: '運動・食事・睡眠のバランスを整える',
      suggestedWhy: '元気に毎日を過ごしたいから',
    ),
    DreamTemplate(
      title: 'マラソンを完走する',
      description: 'フルマラソンやハーフマラソンを完走する',
      suggestedWhy: '自分の限界に挑戦して達成感を味わいたいから',
    ),
    DreamTemplate(
      title: '理想の体型になる',
      description: '継続的な運動と食事管理で理想の体を手に入れる',
      suggestedWhy: '自分に自信を持てるようになりたいから',
    ),
  ],
  DreamCategory.learning: [
    DreamTemplate(
      title: '資格を取得する',
      description: '目標の資格試験に合格する',
      suggestedWhy: '専門知識を証明してキャリアに活かしたいから',
    ),
    DreamTemplate(
      title: '英語を話せるようになる',
      description: '日常会話レベルの英語力を身につける',
      suggestedWhy: '世界中の人とコミュニケーションを取りたいから',
    ),
    DreamTemplate(
      title: 'プログラミングを習得する',
      description: '自分でアプリやWebサービスを作れるようになる',
      suggestedWhy: '自分のアイデアを形にできるようになりたいから',
    ),
  ],
  DreamCategory.hobby: [
    DreamTemplate(
      title: '楽器を演奏できるようになる',
      description: '好きな曲を自分で演奏できるレベルになる',
      suggestedWhy: '音楽を通じて表現する喜びを味わいたいから',
    ),
    DreamTemplate(
      title: '作品を発表する',
      description: 'イラスト・小説・写真などの作品を公開する',
      suggestedWhy: '自分の創造力を形にして誰かに届けたいから',
    ),
    DreamTemplate(
      title: '料理が上手になる',
      description: 'レシピを見ずに美味しい料理を作れるようになる',
      suggestedWhy: '大切な人に美味しいものを食べてもらいたいから',
    ),
  ],
  DreamCategory.relationships: [
    DreamTemplate(
      title: '大切な人との時間を増やす',
      description: '家族や友人と過ごす時間を意識的に作る',
      suggestedWhy: '人生で本当に大切なものを大事にしたいから',
    ),
    DreamTemplate(
      title: '新しいコミュニティに参加する',
      description: '趣味や学習を通じて新しい仲間を見つける',
      suggestedWhy: '同じ志を持つ仲間と切磋琢磨したいから',
    ),
    DreamTemplate(
      title: '人に教えられる人になる',
      description: '自分の経験や知識を人に伝えられるようになる',
      suggestedWhy: '自分の経験が誰かの役に立てたら嬉しいから',
    ),
  ],
  DreamCategory.money: [
    DreamTemplate(
      title: '貯蓄目標を達成する',
      description: '計画的にお金を貯めて目標額に到達する',
      suggestedWhy: '将来の安心と選択肢を手に入れたいから',
    ),
    DreamTemplate(
      title: '投資を始める',
      description: '資産運用の知識を身につけて実践する',
      suggestedWhy: 'お金に働いてもらい時間の自由を得たいから',
    ),
    DreamTemplate(
      title: '副業で収入を増やす',
      description: 'スキルを活かして本業以外の収入源を作る',
      suggestedWhy: '経済的な余裕を持って好きなことに挑戦したいから',
    ),
  ],
  DreamCategory.lifestyle: [
    DreamTemplate(
      title: '早起きの習慣をつける',
      description: '朝の時間を有効に使える生活リズムを作る',
      suggestedWhy: '1日を充実させて自分の時間を確保したいから',
    ),
    DreamTemplate(
      title: '旅行で新しい世界を見る',
      description: '行きたかった場所を訪れて視野を広げる',
      suggestedWhy: '新しい体験を通じて人生を豊かにしたいから',
    ),
    DreamTemplate(
      title: 'ミニマルな暮らしを実現する',
      description: '本当に必要なものだけに囲まれた生活にする',
      suggestedWhy: 'シンプルな生活で心に余裕を持ちたいから',
    ),
  ],
};

/// 興味発見の質問.
class DiscoveryQuestion {
  /// DiscoveryQuestionを作成する.
  const DiscoveryQuestion({
    required this.question,
    required this.options,
  });

  /// 質問文.
  final String question;

  /// 選択肢.
  final List<DiscoveryOption> options;
}

/// 質問の選択肢.
class DiscoveryOption {
  /// DiscoveryOptionを作成する.
  const DiscoveryOption({
    required this.label,
    required this.weights,
  });

  /// 表示テキスト.
  final String label;

  /// カテゴリへの重み付け.
  final Map<DreamCategory, int> weights;
}

/// 興味発見の質問リスト.
const List<DiscoveryQuestion> discoveryQuestions = [
  DiscoveryQuestion(
    question: '休みの日、つい時間を使ってしまうことは？',
    options: [
      DiscoveryOption(
        label: '本や記事を読む',
        weights: {DreamCategory.learning: 2, DreamCategory.career: 1},
      ),
      DiscoveryOption(
        label: '体を動かす',
        weights: {DreamCategory.health: 2, DreamCategory.lifestyle: 1},
      ),
      DiscoveryOption(
        label: '何かを作る・描く',
        weights: {DreamCategory.hobby: 2, DreamCategory.career: 1},
      ),
      DiscoveryOption(
        label: '人と会う・話す',
        weights: {DreamCategory.relationships: 2, DreamCategory.lifestyle: 1},
      ),
      DiscoveryOption(
        label: 'お金や投資の情報を調べる',
        weights: {DreamCategory.money: 2, DreamCategory.learning: 1},
      ),
      DiscoveryOption(
        label: '動画やSNSを見る',
        weights: {DreamCategory.hobby: 1, DreamCategory.lifestyle: 1},
      ),
    ],
  ),
  DiscoveryQuestion(
    question: '「すごいな」と感じる人はどんな人？',
    options: [
      DiscoveryOption(
        label: '専門スキルが高い人',
        weights: {DreamCategory.career: 2, DreamCategory.learning: 1},
      ),
      DiscoveryOption(
        label: '健康的でエネルギッシュな人',
        weights: {DreamCategory.health: 2, DreamCategory.lifestyle: 1},
      ),
      DiscoveryOption(
        label: '好きなことを仕事にしている人',
        weights: {DreamCategory.hobby: 2, DreamCategory.career: 1},
      ),
      DiscoveryOption(
        label: '人望がある人',
        weights: {DreamCategory.relationships: 2},
      ),
      DiscoveryOption(
        label: '経済的に自由な人',
        weights: {DreamCategory.money: 2, DreamCategory.lifestyle: 1},
      ),
      DiscoveryOption(
        label: '自分らしく生きている人',
        weights: {DreamCategory.lifestyle: 2, DreamCategory.hobby: 1},
      ),
    ],
  ),
  DiscoveryQuestion(
    question: '1年後の自分に一つだけ変化があるとしたら？',
    options: [
      DiscoveryOption(
        label: '新しいスキルを身につけている',
        weights: {DreamCategory.learning: 2, DreamCategory.career: 1},
      ),
      DiscoveryOption(
        label: '心も体も健康になっている',
        weights: {DreamCategory.health: 2},
      ),
      DiscoveryOption(
        label: '趣味を楽しんでいる',
        weights: {DreamCategory.hobby: 2, DreamCategory.lifestyle: 1},
      ),
      DiscoveryOption(
        label: '良い人間関係を築いている',
        weights: {DreamCategory.relationships: 2},
      ),
      DiscoveryOption(
        label: '収入が増えている',
        weights: {DreamCategory.money: 2, DreamCategory.career: 1},
      ),
      DiscoveryOption(
        label: '自分のペースで生活できている',
        weights: {DreamCategory.lifestyle: 2},
      ),
    ],
  ),
];

/// 選択された回答からカテゴリスコアを計算する.
Map<DreamCategory, int> calculateCategoryScores(
  List<Set<int>> selectedAnswers,
) {
  final scores = <DreamCategory, int>{};
  for (var qi = 0; qi < discoveryQuestions.length; qi++) {
    final question = discoveryQuestions[qi];
    final selected = qi < selectedAnswers.length ? selectedAnswers[qi] : <int>{};
    for (final optionIndex in selected) {
      if (optionIndex < question.options.length) {
        final option = question.options[optionIndex];
        for (final entry in option.weights.entries) {
          scores[entry.key] = (scores[entry.key] ?? 0) + entry.value;
        }
      }
    }
  }
  return scores;
}

/// スコアでソートされたカテゴリ一覧を返す.
List<DreamCategory> sortedCategories(Map<DreamCategory, int> scores) {
  final categories = List<DreamCategory>.from(DreamCategory.values);
  categories.sort((a, b) {
    final sa = scores[a] ?? 0;
    final sb = scores[b] ?? 0;
    return sb.compareTo(sa);
  });
  return categories;
}
