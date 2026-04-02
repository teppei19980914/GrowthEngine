/// 画面描画ストレステスト.
///
/// 大量データを表示する画面の描画性能を計測し、
/// 閾値を超えた場合にテスト失敗とする.
///
/// 実行方法:
///   flutter test test_stress/rendering_stress_test.dart
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/models/book.dart';
import 'package:yume_log/models/constellation.dart';
import 'package:yume_log/models/task.dart';
import 'package:yume_log/widgets/constellation/constellation_painter.dart';
import 'package:yume_log/widgets/gantt/gantt_chart.dart';

// ── テストデータ件数 ──────────────────────────────
const _ganttTaskCount = 200; // ガントチャート: 200タスク
const _ganttTimelineYears = 2; // 2年間のタイムライン
const _bookshelfCount = 200; // 本棚: 200冊
const _constellationStarCount = 50; // 星座: 50個の星

// ── 許容時間（ミリ秒） ──────────────────────────────
// pumpAndSettle のフレーム処理時間基準
const _thresholdRenderMs = 2000; // 初回描画
const _thresholdScrollMs = 2000; // スクロール操作
const _thresholdRepaintMs = 2000; // 再描画

/// 計測結果を収集するリスト.
final _results = <Map<String, dynamic>>[];

void _record(String label, int ms, int threshold) {
  _results.add({
    'label': label,
    'ms': ms,
    'threshold_ms': threshold,
    'passed': ms <= threshold,
  });
}

/// タスクを大量生成するヘルパー.
List<Task> _generateTasks(int count, int timelineYears) {
  final base = DateTime(2025, 1, 1);
  final goalIds = List.generate(10, (i) => 'goal-$i');
  return List.generate(count, (i) {
    final startDay = (i * 3) % (timelineYears * 365);
    return Task(
      id: 'task-$i',
      goalId: goalIds[i % goalIds.length],
      title: 'ストレステストタスク $i',
      startDate: base.add(Duration(days: startDay)),
      endDate: base.add(Duration(days: startDay + 7 + (i % 30))),
      status: TaskStatus.values[i % TaskStatus.values.length],
      progress: (i * 7) % 101,
    );
  });
}

/// 目標カラーマップを生成.
Map<String, Color> _generateGoalColors(int goalCount) {
  final colors = [
    Colors.blue, Colors.green, Colors.red, Colors.orange,
    Colors.purple, Colors.teal, Colors.indigo, Colors.amber,
    Colors.cyan, Colors.pink,
  ];
  return {
    for (var i = 0; i < goalCount; i++)
      'goal-$i': colors[i % colors.length],
  };
}

/// 目標名マップを生成.
Map<String, String> _generateGoalNames(int goalCount) {
  return {
    for (var i = 0; i < goalCount; i++) 'goal-$i': '目標 $i',
  };
}

/// 書籍を大量生成するヘルパー.
List<Book> _generateBooks(int count) {
  return List.generate(count, (i) {
    return Book(
      id: 'book-$i',
      title: 'ストレステスト書籍 $i 長いタイトルのテスト',
      status: BookStatus.values[i % BookStatus.values.length],
      category: BookCategory.values[i % BookCategory.values.length],
    );
  });
}

/// 大きな星座を生成するヘルパー.
ConstellationDef _generateLargeConstellation(int starCount) {
  final rng = Random(42);
  final stars = List.generate(
      starCount, (_) => StarPosition(rng.nextDouble(), rng.nextDouble()));
  final connections = <StarConnection>[];
  for (var i = 0; i < starCount - 1; i++) {
    connections.add(StarConnection(i, i + 1));
  }
  // 追加のクロス接続
  for (var i = 0; i < starCount ~/ 3; i++) {
    connections.add(StarConnection(
      rng.nextInt(starCount),
      rng.nextInt(starCount),
    ));
  }
  return ConstellationDef(
    id: 'stress_test',
    name: 'Stress',
    jaName: 'ストレス座',
    symbol: '\u2606',
    stars: stars,
    connections: connections,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() {
    final failedCount = _results.where((r) => r['passed'] == false).length;
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'test_type': 'rendering',
      'total_measurements': _results.length,
      'passed_count': _results.where((r) => r['passed'] == true).length,
      'failed_count': failedCount,
      'all_passed': failedCount == 0,
      'measurements': _results,
      'bottlenecks': _results
          .where((r) => r['passed'] == false)
          .map((r) =>
              '${r['label']}: ${r['ms']}ms (threshold: ${r['threshold_ms']}ms)')
          .toList(),
    };

    final dir = Directory('test_stress/results');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final json = const JsonEncoder.withIndent('  ').convert(report);
    File('test_stress/results/latest_rendering.json').writeAsStringSync(json);

    // ignore: avoid_print
    print(
        '\n=== Rendering: ${report['all_passed'] == true ? 'ALL PASSED' : 'FAILED'} ===');
    // ignore: avoid_print
    print('Output: test_stress/results/latest_rendering.json');
  });

  // ══════════════════════════════════════════════════════════
  // 1. ガントチャート（大量タスク）
  // ══════════════════════════════════════════════════════════
  group('ガントチャート描画', () {
    final tasks = _generateTasks(_ganttTaskCount, _ganttTimelineYears);
    final goalColors = _generateGoalColors(10);
    final goalNames = _generateGoalNames(10);

    Widget buildGantt() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: GanttChart(
              tasks: tasks,
              goalColors: goalColors,
              goalNames: goalNames,
              milestones: const [],
            ),
          ),
        ),
      );
    }

    testWidgets('初回描画（$_ganttTaskCount タスク × $_ganttTimelineYears年）',
        (tester) async {
      // ignore: avoid_print
      print('\n=== ガントチャート描画 ===');

      final sw = Stopwatch()..start();
      await tester.pumpWidget(buildGantt());
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print('  [ガントチャート初回描画] ${sw.elapsedMilliseconds}ms');
      _record('ガントチャート初回描画', sw.elapsedMilliseconds,
          _thresholdRenderMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdRenderMs));
    });

    testWidgets('水平スクロール（$_ganttTaskCount タスク）', (tester) async {
      await tester.pumpWidget(buildGantt());
      await tester.pumpAndSettle();

      final sw = Stopwatch()..start();
      // 10回スクロール
      for (var i = 0; i < 10; i++) {
        await tester.drag(
          find.byType(GanttChart),
          const Offset(-200, 0),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print('  [ガントチャート水平スクロール×10] ${sw.elapsedMilliseconds}ms');
      _record('ガントチャート水平スクロール×10', sw.elapsedMilliseconds,
          _thresholdScrollMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdScrollMs));
    });

    testWidgets('垂直スクロール（$_ganttTaskCount タスク）', (tester) async {
      await tester.pumpWidget(buildGantt());
      await tester.pumpAndSettle();

      final sw = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        await tester.drag(
          find.byType(GanttChart),
          const Offset(0, -200),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print('  [ガントチャート垂直スクロール×10] ${sw.elapsedMilliseconds}ms');
      _record('ガントチャート垂直スクロール×10', sw.elapsedMilliseconds,
          _thresholdScrollMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdScrollMs));
    });

    testWidgets('タスク数変更による再描画', (tester) async {
      // 少ないタスクで初期表示
      final smallTasks = tasks.sublist(0, 10);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: GanttChart(
              tasks: smallTasks,
              goalColors: goalColors,
              goalNames: goalNames,
              milestones: const [],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // 大量タスクに切り替え
      final sw = Stopwatch()..start();
      await tester.pumpWidget(buildGantt());
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print(
          '  [ガントチャート再描画 10→$_ganttTaskCount] ${sw.elapsedMilliseconds}ms');
      _record('ガントチャート再描画 10→$_ganttTaskCount',
          sw.elapsedMilliseconds, _thresholdRepaintMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdRepaintMs));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 2. 星座描画（大量の星）
  // ══════════════════════════════════════════════════════════
  group('星座描画', () {
    final largeDef = _generateLargeConstellation(_constellationStarCount);

    testWidgets('大量の星（$_constellationStarCount個）の初回描画',
        (tester) async {
      // ignore: avoid_print
      print('\n=== 星座描画 ===');

      final progress = ConstellationProgress(
        constellation: largeDef,
        litStarCount: _constellationStarCount ~/ 2,
      );

      final sw = Stopwatch()..start();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: ConstellationWidget(progress: progress),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print('  [星座初回描画 $_constellationStarCount星] ${sw.elapsedMilliseconds}ms');
      _record('星座初回描画 $_constellationStarCount星',
          sw.elapsedMilliseconds, _thresholdRenderMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdRenderMs));
    });

    testWidgets('星の点灯数変更による再描画', (tester) async {
      // 0個点灯で初期表示
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: ConstellationWidget(
              progress: ConstellationProgress(
                constellation: largeDef,
                litStarCount: 0,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // 全点灯に切り替え
      final sw = Stopwatch()..start();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: ConstellationWidget(
              progress: ConstellationProgress(
                constellation: largeDef,
                litStarCount: _constellationStarCount,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print(
          '  [星座再描画 0→$_constellationStarCount点灯] ${sw.elapsedMilliseconds}ms');
      _record('星座再描画 0→$_constellationStarCount点灯',
          sw.elapsedMilliseconds, _thresholdRepaintMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdRepaintMs));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 3. 本棚（大量書籍）
  // ══════════════════════════════════════════════════════════
  group('本棚描画', () {
    final books = _generateBooks(_bookshelfCount);

    Widget buildBookshelf() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: ListView.builder(
              itemCount: (books.length / 8).ceil(),
              itemBuilder: (_, shelfIndex) {
                final start = shelfIndex * 8;
                final end = (start + 8).clamp(0, books.length);
                final shelfBooks = books.sublist(start, end);
                return SizedBox(
                  height: 160,
                  child: Row(
                    children: [
                      for (final book in shelfBooks)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade700,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Center(
                              child: Text(
                                book.title,
                                style: const TextStyle(
                                    fontSize: 8, color: Colors.white),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('初回描画（$_bookshelfCount冊）', (tester) async {
      // ignore: avoid_print
      print('\n=== 本棚描画 ===');

      final sw = Stopwatch()..start();
      await tester.pumpWidget(buildBookshelf());
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print('  [本棚初回描画 $_bookshelfCount冊] ${sw.elapsedMilliseconds}ms');
      _record(
          '本棚初回描画 $_bookshelfCount冊', sw.elapsedMilliseconds, _thresholdRenderMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdRenderMs));
    });

    testWidgets('高速スクロール（$_bookshelfCount冊）', (tester) async {
      await tester.pumpWidget(buildBookshelf());
      await tester.pumpAndSettle();

      final sw = Stopwatch()..start();
      // fling で高速スクロール
      await tester.fling(
        find.byType(ListView),
        const Offset(0, -3000),
        5000,
      );
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print('  [本棚高速スクロール] ${sw.elapsedMilliseconds}ms');
      _record(
          '本棚高速スクロール', sw.elapsedMilliseconds, _thresholdScrollMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdScrollMs));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 4. 大量リスト描画
  // ══════════════════════════════════════════════════════════
  group('大量リスト描画', () {
    testWidgets('1000行の ListTile 描画 + スクロール', (tester) async {
      // ignore: avoid_print
      print('\n=== 大量リスト描画 ===');

      final sw = Stopwatch()..start();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 1000,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.task),
              title: Text('タスク $i'),
              subtitle: Text('サブタイトル $i'),
              trailing: Text('${i % 100}%'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print('  [1000行ListTile初回描画] ${sw.elapsedMilliseconds}ms');
      _record('1000行ListTile初回描画', sw.elapsedMilliseconds,
          _thresholdRenderMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdRenderMs));

      // 高速スクロール
      final sw2 = Stopwatch()..start();
      await tester.fling(
        find.byType(ListView),
        const Offset(0, -5000),
        8000,
      );
      await tester.pumpAndSettle();
      sw2.stop();

      // ignore: avoid_print
      print('  [1000行高速スクロール] ${sw2.elapsedMilliseconds}ms');
      _record('1000行高速スクロール', sw2.elapsedMilliseconds,
          _thresholdScrollMs);
      expect(sw2.elapsedMilliseconds, lessThan(_thresholdScrollMs));
    });
  });

  // ══════════════════════════════════════════════════════════
  // 5. テーマ切替（全ウィジェット再描画）
  // ══════════════════════════════════════════════════════════
  group('テーマ切替', () {
    testWidgets('ダーク↔ライト切替の再描画', (tester) async {
      // ignore: avoid_print
      print('\n=== テーマ切替 ===');

      final themeNotifier = ValueNotifier(ThemeMode.dark);

      await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, _) => MaterialApp(
          themeMode: mode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: ListView.builder(
              itemCount: 500,
              itemBuilder: (_, i) => Card(
                child: ListTile(
                  title: Text('アイテム $i'),
                  subtitle: Text('説明 $i'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // ダーク→ライト
      final sw = Stopwatch()..start();
      themeNotifier.value = ThemeMode.light;
      await tester.pumpAndSettle();
      sw.stop();

      // ignore: avoid_print
      print('  [テーマ切替 dark→light] ${sw.elapsedMilliseconds}ms');
      _record('テーマ切替 dark→light', sw.elapsedMilliseconds,
          _thresholdRepaintMs);
      expect(sw.elapsedMilliseconds, lessThan(_thresholdRepaintMs));

      // ライト→ダーク
      final sw2 = Stopwatch()..start();
      themeNotifier.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      sw2.stop();

      // ignore: avoid_print
      print('  [テーマ切替 light→dark] ${sw2.elapsedMilliseconds}ms');
      _record('テーマ切替 light→dark', sw2.elapsedMilliseconds,
          _thresholdRepaintMs);
      expect(sw2.elapsedMilliseconds, lessThan(_thresholdRepaintMs));
    });
  });
}
