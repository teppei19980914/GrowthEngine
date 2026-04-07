import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/data/constellations.dart';
import 'package:yume_hashi/models/constellation.dart';

void main() {
  group('ConstellationDef', () {
    test('全36星座が定義されている', () {
      expect(constellations.length, 36);
    });

    test('各星座にIDと名前がある', () {
      for (final c in constellations) {
        expect(c.id, isNotEmpty);
        expect(c.name, isNotEmpty);
        expect(c.jaName, isNotEmpty);
        expect(c.symbol, isNotEmpty);
      }
    });

    test('各星座に星と接続線がある', () {
      for (final c in constellations) {
        expect(c.stars, isNotEmpty);
        expect(c.connections, isNotEmpty);
        expect(c.starCount, c.stars.length);
      }
    });

    test('接続線のインデックスが星の範囲内', () {
      for (final c in constellations) {
        for (final conn in c.connections) {
          expect(conn.fromIndex, lessThan(c.starCount));
          expect(conn.toIndex, lessThan(c.starCount));
        }
      }
    });

    test('星の座標が0.0-1.0の範囲内', () {
      for (final c in constellations) {
        for (final star in c.stars) {
          expect(star.x, inInclusiveRange(0.0, 1.0));
          expect(star.y, inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('全星座に説明文がある', () {
      for (final c in constellations) {
        expect(c.description, isNotEmpty, reason: '${c.id}に説明がない');
      }
    });
  });

  group('getConstellationForIndex', () {
    test('インデックスに応じた星座を返す', () {
      expect(getConstellationForIndex(0).id, 'aries');
      expect(getConstellationForIndex(11).id, 'pisces');
      expect(getConstellationForIndex(12).id, 'orion');
      expect(getConstellationForIndex(35).id, 'tucana');
    });

    test('36以上のインデックスは循環する', () {
      expect(getConstellationForIndex(36).id, 'aries');
      expect(getConstellationForIndex(37).id, 'taurus');
    });
  });

  group('ConstellationProgress', () {
    final constellation = constellations[0]; // Aries (8 stars)

    test('completionRateが正しく計算される', () {
      final p = ConstellationProgress(
        constellation: constellation,
        litStarCount: 4,
      );
      expect(p.completionRate, closeTo(4 / 8, 0.01));
    });

    test('isCompleteが正しく判定される', () {
      final incomplete = ConstellationProgress(
        constellation: constellation,
        litStarCount: 7,
      );
      expect(incomplete.isComplete, isFalse);

      final complete = ConstellationProgress(
        constellation: constellation,
        litStarCount: 8,
      );
      expect(complete.isComplete, isTrue);
    });
  });

  group('ConstellationOverallProgress', () {
    test('overallCompletionRateが正しく計算される', () {
      final progress = ConstellationOverallProgress(
        constellations: [
          ConstellationProgress(
            constellation: constellations[0],
            litStarCount: constellations[0].starCount,
          ),
          ConstellationProgress(
            constellation: constellations[1],
            litStarCount: 5,
          ),
        ],
        totalMinutes: 6500,
        totalLitStars: constellations[0].starCount + 5,
        totalStars: constellations[0].starCount + constellations[1].starCount,
      );
      expect(
        progress.overallCompletionRate,
        closeTo(
          (constellations[0].starCount + 5) /
              (constellations[0].starCount + constellations[1].starCount),
          0.01,
        ),
      );
    });

    test('completedCountが正しく計算される', () {
      final progress = ConstellationOverallProgress(
        constellations: [
          ConstellationProgress(
            constellation: constellations[0],
            litStarCount: constellations[0].starCount,
          ),
          ConstellationProgress(
            constellation: constellations[1],
            litStarCount: 5,
          ),
        ],
        totalMinutes: 6500,
        totalLitStars: constellations[0].starCount + 5,
        totalStars: constellations[0].starCount + constellations[1].starCount,
      );
      expect(progress.completedCount, 1);
    });

    test('totalHoursが正しく変換される', () {
      final progress = ConstellationOverallProgress(
        constellations: [],
        totalMinutes: 150,
        totalLitStars: 0,
        totalStars: 0,
      );
      expect(progress.totalHours, 2.5);
    });
  });

  group('minutesPerStar', () {
    test('5時間（300分）に設定されている', () {
      expect(minutesPerStar, 300);
    });
  });
}
