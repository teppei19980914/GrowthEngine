import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/data/dream_templates.dart';

void main() {
  group('dreamTemplates', () {
    test('全カテゴリにテンプレートが存在する', () {
      for (final category in DreamCategory.values) {
        final templates = dreamTemplates[category];
        expect(templates, isNotNull, reason: '${category.label}にテンプレートがない');
        expect(templates!.length, greaterThanOrEqualTo(3),
            reason: '${category.label}のテンプレートが3件未満');
      }
    });

    test('全テンプレートのフィールドが空でない', () {
      for (final entry in dreamTemplates.entries) {
        for (final template in entry.value) {
          expect(template.title, isNotEmpty,
              reason: '${entry.key.label}のテンプレートでtitleが空');
          expect(template.description, isNotEmpty,
              reason: '${entry.key.label}のテンプレートでdescriptionが空');
          expect(template.suggestedWhy, isNotEmpty,
              reason: '${entry.key.label}のテンプレートでsuggestedWhyが空');
        }
      }
    });
  });

  group('discoveryQuestions', () {
    test('質問が3件存在する', () {
      expect(discoveryQuestions.length, 3);
    });

    test('全質問に選択肢がある', () {
      for (final question in discoveryQuestions) {
        expect(question.question, isNotEmpty);
        expect(question.options, isNotEmpty);
        for (final option in question.options) {
          expect(option.label, isNotEmpty);
          expect(option.weights, isNotEmpty);
        }
      }
    });

    test('全選択肢の重みが有効なカテゴリを参照している', () {
      for (final question in discoveryQuestions) {
        for (final option in question.options) {
          for (final key in option.weights.keys) {
            expect(DreamCategory.values, contains(key));
          }
        }
      }
    });
  });

  group('calculateCategoryScores', () {
    test('回答なしは空のスコア', () {
      final scores = calculateCategoryScores([<int>{}, <int>{}, <int>{}]);
      expect(scores, isEmpty);
    });

    test('選択した回答に応じてスコアが計算される', () {
      // 質問0の選択肢0（本や記事を読む）→ learning:2, career:1
      final scores = calculateCategoryScores([{0}, <int>{}, <int>{}]);
      expect(scores[DreamCategory.learning], 2);
      expect(scores[DreamCategory.career], 1);
    });

    test('複数の回答でスコアが合算される', () {
      // 質問0:選択肢0 → learning:2, career:1
      // 質問1:選択肢0 → career:2, learning:1
      final scores = calculateCategoryScores([{0}, {0}, <int>{}]);
      expect(scores[DreamCategory.learning], 3); // 2 + 1
      expect(scores[DreamCategory.career], 3); // 1 + 2
    });
  });

  group('sortedCategories', () {
    test('スコア順にソートされる', () {
      final scores = {
        DreamCategory.health: 5,
        DreamCategory.career: 1,
        DreamCategory.learning: 3,
      };
      final sorted = sortedCategories(scores);
      expect(sorted.first, DreamCategory.health);
    });

    test('全カテゴリが含まれる', () {
      final sorted = sortedCategories({});
      expect(sorted.length, DreamCategory.values.length);
    });
  });
}
