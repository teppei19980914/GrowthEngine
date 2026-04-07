import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/data/constellations.dart';
import 'package:yume_hashi/database/app_database.dart'
    hide Book, Dream, Goal, Task;
import 'package:yume_hashi/models/constellation.dart';
import 'package:yume_hashi/pages/constellation_page.dart';
import 'package:yume_hashi/providers/constellation_providers.dart';
import 'package:yume_hashi/providers/database_provider.dart';
import 'package:yume_hashi/providers/theme_provider.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildPage(ConstellationOverallProgress progress) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        constellationProgressProvider.overrideWith(
          (ref) async => progress,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ConstellationPage()),
      ),
    );
  }

  group('ConstellationPage', () {
    testWidgets('完成した星座をタップすると説明ダイアログが表示される',
        (tester) async {
      final aries = constellations[0];
      final progress = ConstellationOverallProgress(
        constellations: [
          ConstellationProgress(
            constellation: aries,
            litStarCount: aries.starCount,
          ),
        ],
        totalMinutes: aries.starCount * minutesPerStar,
        totalLitStars: aries.starCount,
        totalStars: aries.starCount,
      );

      await tester.pumpWidget(buildPage(progress));
      await tester.pumpAndSettle();

      // カードをタップ
      await tester.tap(find.text(aries.jaName));
      await tester.pumpAndSettle();

      // 説明ダイアログが表示される
      expect(find.text(aries.name), findsOneWidget);
      expect(find.text(aries.description), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('未完成の星座はタップしてもダイアログが表示されない',
        (tester) async {
      final aries = constellations[0];
      final progress = ConstellationOverallProgress(
        constellations: [
          ConstellationProgress(
            constellation: aries,
            litStarCount: 1,
          ),
        ],
        totalMinutes: minutesPerStar,
        totalLitStars: 1,
        totalStars: aries.starCount,
      );

      await tester.pumpWidget(buildPage(progress));
      await tester.pumpAndSettle();

      // カードをタップ
      await tester.tap(find.text(aries.jaName));
      await tester.pumpAndSettle();

      // ダイアログは表示されない
      expect(find.text(aries.description), findsNothing);
    });

    testWidgets('完成した星座カードにinfoアイコンが表示される',
        (tester) async {
      final aries = constellations[0];
      final progress = ConstellationOverallProgress(
        constellations: [
          ConstellationProgress(
            constellation: aries,
            litStarCount: aries.starCount,
          ),
        ],
        totalMinutes: aries.starCount * minutesPerStar,
        totalLitStars: aries.starCount,
        totalStars: aries.starCount,
      );

      await tester.pumpWidget(buildPage(progress));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
