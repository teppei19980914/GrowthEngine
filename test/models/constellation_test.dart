import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/data/constellations.dart';
import 'package:yume_log/models/constellation.dart';

void main() {
  group('ConstellationDef', () {
    test('全12星座が定義されている', () {
      expect(constellations.length, 12);
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
  });

  group('getConstellationForIndex', () {
    test('インデックスに応じた星座を返す', () {
      expect(getConstellationForIndex(0).id, 'aries');
      expect(getConstellationForIndex(11).id, 'pisces');
    });

    test('12以上のインデックスは循環する', () {
      expect(getConstellationForIndex(12).id, 'aries');
      expect(getConstellationForIndex(13).id, 'taurus');
    });
  });

  group('ConstellationProgress', () {
    final constellation = constellations[0]; // Aries (8 stars)

    test('completionRateが正しく計算される', () {
      final p = ConstellationProgress(
        dreamId: 'd1',
        dreamTitle: 'Test',
        constellation: constellation,
        totalMinutes: 0,
        litStarCount: 4,
      );
      expect(p.completionRate, closeTo(4 / 8, 0.01));
    });

    test('isCompleteが正しく判定される', () {
      final incomplete = ConstellationProgress(
        dreamId: 'd1',
        dreamTitle: 'Test',
        constellation: constellation,
        totalMinutes: 0,
        litStarCount: 7,
      );
      expect(incomplete.isComplete, isFalse);

      final complete = ConstellationProgress(
        dreamId: 'd1',
        dreamTitle: 'Test',
        constellation: constellation,
        totalMinutes: 0,
        litStarCount: 8,
      );
      expect(complete.isComplete, isTrue);
    });

    test('totalHoursが正しく変換される', () {
      final p = ConstellationProgress(
        dreamId: 'd1',
        dreamTitle: 'Test',
        constellation: constellation,
        totalMinutes: 150,
        litStarCount: 0,
      );
      expect(p.totalHours, 2.5);
    });
  });

  group('minutesPerStar', () {
    test('5時間（300分）に設定されている', () {
      expect(minutesPerStar, 300);
    });
  });
}
