/// 星座データモデル.
library;

/// 星の位置（正規化座標 0.0〜1.0）.
class StarPosition {
  /// StarPositionを作成する.
  const StarPosition(this.x, this.y);

  /// X座標（0.0〜1.0）.
  final double x;

  /// Y座標（0.0〜1.0）.
  final double y;
}

/// 星同士の接続線.
class StarConnection {
  /// StarConnectionを作成する.
  const StarConnection(this.fromIndex, this.toIndex);

  /// 始点の星インデックス.
  final int fromIndex;

  /// 終点の星インデックス.
  final int toIndex;
}

/// 星座の定義.
class ConstellationDef {
  /// ConstellationDefを作成する.
  const ConstellationDef({
    required this.id,
    required this.name,
    required this.jaName,
    required this.stars,
    required this.connections,
    required this.symbol,
    this.description = '',
  });

  /// 一意識別子.
  final String id;

  /// 英語名.
  final String name;

  /// 日本語名.
  final String jaName;

  /// シンボル文字.
  final String symbol;

  /// 星座の説明文.
  final String description;

  /// 星の位置一覧.
  final List<StarPosition> stars;

  /// 接続線一覧.
  final List<StarConnection> connections;

  /// 星の総数.
  int get starCount => stars.length;
}

/// 個別星座の進捗状態.
class ConstellationProgress {
  /// ConstellationProgressを作成する.
  const ConstellationProgress({
    required this.constellation,
    required this.litStarCount,
  });

  /// 割り当てられた星座.
  final ConstellationDef constellation;

  /// 点灯済みの星の数.
  final int litStarCount;

  /// 完成率（0.0〜1.0）.
  double get completionRate =>
      constellation.starCount == 0
          ? 0.0
          : (litStarCount / constellation.starCount).clamp(0.0, 1.0);

  /// 星座が完成しているか.
  bool get isComplete => litStarCount >= constellation.starCount;
}

/// 全星座の総合進捗.
class ConstellationOverallProgress {
  /// ConstellationOverallProgressを作成する.
  const ConstellationOverallProgress({
    required this.constellations,
    required this.totalMinutes,
    required this.totalLitStars,
    required this.totalStars,
  });

  /// 各星座の進捗リスト.
  final List<ConstellationProgress> constellations;

  /// 累計活動時間（分）.
  final int totalMinutes;

  /// 点灯済みの星の総数.
  final int totalLitStars;

  /// 全星座の星の総数.
  final int totalStars;

  /// 合計活動時間（時間）.
  double get totalHours => totalMinutes / 60.0;

  /// 全体完成率（0.0〜1.0）.
  double get overallCompletionRate =>
      totalStars == 0 ? 0.0 : (totalLitStars / totalStars).clamp(0.0, 1.0);

  /// 完成した星座の数.
  int get completedCount =>
      constellations.where((c) => c.isComplete).length;
}
