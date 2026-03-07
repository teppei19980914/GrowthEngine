import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_planner/models/constellation.dart';
import 'package:study_planner/widgets/constellation/constellation_painter.dart';

const _testConstellation = ConstellationDef(
  id: 'test_constellation',
  name: 'Test',
  jaName: 'テスト座',
  symbol: '\u2606',
  stars: [
    StarPosition(0.2, 0.3),
    StarPosition(0.5, 0.1),
    StarPosition(0.8, 0.3),
    StarPosition(0.5, 0.7),
  ],
  connections: [
    StarConnection(0, 1),
    StarConnection(1, 2),
    StarConnection(2, 3),
    StarConnection(3, 0),
  ],
);

Widget _wrap(ConstellationProgress progress, {bool compact = false}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 200,
        child: ConstellationWidget(
          progress: progress,
          compact: compact,
        ),
      ),
    ),
  );
}

void main() {
  group('ConstellationWidget', () {
    testWidgets('有効なデータでエラーなく描画される', (tester) async {
      const progress = ConstellationProgress(
        dreamId: 'dream_1',
        dreamTitle: 'テスト目標',
        constellation: _testConstellation,
        totalMinutes: 120,
        litStarCount: 2,
      );

      await tester.pumpWidget(_wrap(progress));

      expect(find.byType(ConstellationWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('コンパクトモードで描画される', (tester) async {
      const progress = ConstellationProgress(
        dreamId: 'dream_1',
        dreamTitle: 'テスト目標',
        constellation: _testConstellation,
        totalMinutes: 60,
        litStarCount: 1,
      );

      await tester.pumpWidget(_wrap(progress, compact: true));

      expect(find.byType(ConstellationWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('全星が点灯した完成状態で描画される', (tester) async {
      const progress = ConstellationProgress(
        dreamId: 'dream_1',
        dreamTitle: 'テスト目標',
        constellation: _testConstellation,
        totalMinutes: 600,
        litStarCount: 4, // 全4つの星が点灯
      );

      await tester.pumpWidget(_wrap(progress));

      expect(find.byType(ConstellationWidget), findsOneWidget);
      expect(progress.isComplete, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('部分的な進捗で描画される', (tester) async {
      const progress = ConstellationProgress(
        dreamId: 'dream_1',
        dreamTitle: 'テスト目標',
        constellation: _testConstellation,
        totalMinutes: 180,
        litStarCount: 3,
      );

      await tester.pumpWidget(_wrap(progress));

      expect(find.byType(ConstellationWidget), findsOneWidget);
      expect(progress.isComplete, isFalse);
      expect(progress.completionRate, closeTo(0.75, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('星が0個点灯でも描画される', (tester) async {
      const progress = ConstellationProgress(
        dreamId: 'dream_1',
        dreamTitle: 'テスト目標',
        constellation: _testConstellation,
        totalMinutes: 0,
        litStarCount: 0,
      );

      await tester.pumpWidget(_wrap(progress));

      expect(find.byType(ConstellationWidget), findsOneWidget);
      expect(progress.completionRate, 0.0);
      expect(tester.takeException(), isNull);
    });
  });
}
