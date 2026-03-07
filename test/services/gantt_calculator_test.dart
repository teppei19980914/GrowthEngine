import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/services/gantt_calculator.dart';
import 'package:yume_log/services/study_stats_types.dart';

void main() {
  late GanttCalculator calc;

  setUp(() {
    calc = GanttCalculator();
  });

  group('GanttCalculator', () {
    group('calculateTimeline', () {
      test('空リストではデフォルト範囲を返す', () {
        final result = calc.calculateTimeline([]);
        expect(result.startDate.isBefore(result.endDate), isTrue);
      });

      test('タスク日付からパディング付き範囲を計算する', () {
        final dates = [
          (DateTime(2025, 3, 1), DateTime(2025, 3, 31)),
          (DateTime(2025, 4, 1), DateTime(2025, 4, 30)),
        ];
        final result = calc.calculateTimeline(dates);
        expect(
          result.startDate,
          DateTime(2025, 3, 1).subtract(const Duration(days: 7)),
        );
        expect(
          result.endDate,
          DateTime(2025, 4, 30).add(const Duration(days: 7)),
        );
      });

      test('カスタムパディングを適用する', () {
        final dates = [
          (DateTime(2025, 6, 1), DateTime(2025, 6, 30)),
        ];
        final result = calc.calculateTimeline(dates, paddingDays: 3);
        expect(
          result.startDate,
          DateTime(2025, 6, 1).subtract(const Duration(days: 3)),
        );
        expect(
          result.endDate,
          DateTime(2025, 6, 30).add(const Duration(days: 3)),
        );
      });
    });

    group('calculateBarGeometry', () {
      test('バーの座標を正しく計算する', () {
        final timeline = TimelineRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 12, 31),
        );
        final geo = calc.calculateBarGeometry(
          DateTime(2025, 1, 11),
          DateTime(2025, 1, 20),
          50,
          timeline,
        );
        expect(geo.x, 10 * 30.0); // 10 days * 30px
        expect(geo.width, 10 * 30.0); // 10 days duration
        expect(geo.progressWidth, 10 * 30.0 * 0.5);
      });

      test('進捗0%ではprogressWidthが0', () {
        final timeline = TimelineRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 3, 31),
        );
        final geo = calc.calculateBarGeometry(
          DateTime(2025, 1, 1),
          DateTime(2025, 1, 10),
          0,
          timeline,
        );
        expect(geo.progressWidth, 0.0);
      });

      test('進捗100%ではprogressWidth==width', () {
        final timeline = TimelineRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 3, 31),
        );
        final geo = calc.calculateBarGeometry(
          DateTime(2025, 2, 1),
          DateTime(2025, 2, 10),
          100,
          timeline,
        );
        expect(geo.progressWidth, geo.width);
      });
    });

    group('calculateBarY', () {
      test('行インデックスからY座標を計算する', () {
        expect(calc.calculateBarY(0), 70.0 + 0 * 40 + 8.0);
        expect(calc.calculateBarY(1), 70.0 + 1 * 40 + 8.0);
        expect(calc.calculateBarY(2), 70.0 + 2 * 40 + 8.0);
      });
    });

    group('dateToX', () {
      test('日付をX座標に変換する', () {
        final timeline = TimelineRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 12, 31),
        );
        expect(calc.dateToX(DateTime(2025, 1, 1), timeline), 0.0);
        expect(calc.dateToX(DateTime(2025, 1, 2), timeline), 30.0);
        expect(calc.dateToX(DateTime(2025, 1, 11), timeline), 300.0);
      });
    });

    group('getMonthBoundaries', () {
      test('月の境界位置を返す', () {
        final timeline = TimelineRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 4, 15),
        );
        final boundaries = calc.getMonthBoundaries(timeline);
        expect(boundaries.length, greaterThanOrEqualTo(4));
        expect(boundaries.first.$1, DateTime(2025, 1));
      });

      test('月中開始で最初の境界が翌月1日になる', () {
        final timeline = TimelineRange(
          startDate: DateTime(2025, 3, 15),
          endDate: DateTime(2025, 6, 15),
        );
        final boundaries = calc.getMonthBoundaries(timeline);
        // 3/1 is before 3/15, so first boundary should be 4/1
        expect(boundaries.first.$1, DateTime(2025, 4));
      });
    });

    group('getDayPositions', () {
      test('日付位置リストを返す', () {
        final timeline = TimelineRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 3),
        );
        final positions = calc.getDayPositions(timeline);
        expect(positions.length, 3);
        expect(positions[0].$2, 0.0);
        expect(positions[1].$2, 30.0);
        expect(positions[2].$2, 60.0);
      });
    });

    group('calculateSceneWidth', () {
      test('タイムライン幅を計算する', () {
        final timeline = TimelineRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 10),
        );
        expect(calc.calculateSceneWidth(timeline), timeline.totalDays * 30.0);
      });
    });

    group('calculateSceneHeight', () {
      test('タスク数から高さを計算する', () {
        expect(calc.calculateSceneHeight(5), 70.0 + 5 * 40.0);
      });

      test('タスク0でも最低1行分の高さ', () {
        expect(calc.calculateSceneHeight(0), 70.0 + 1 * 40.0);
      });
    });

    test('カスタムパラメータでインスタンスを作成する', () {
      final custom = GanttCalculator(
        pixelsPerDay: 50,
        rowHeight: 60,
        headerHeight: 100,
        barHeight: 30,
        barMargin: 10,
      );
      expect(custom.pixelsPerDay, 50.0);
      expect(custom.rowHeight, 60);
      expect(custom.calculateBarY(0), 100.0 + 0 * 60 + 10.0);
    });
  });
}
