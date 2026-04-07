import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_hashi/widgets/premium/premium_gate.dart';

/// テスト環境では kIsWeb=false なので isTrialMode=false.
/// そのため PremiumGate は child をそのまま表示し、
/// PremiumSectionGate は何も表示しない.
void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('PremiumGate（非Web環境）', () {
    testWidgets('isPremium=true のとき previewChild をそのまま表示する', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const PremiumGate(
            featureName: '活動予定',
            featureIcon: Icons.view_timeline_outlined,
            premiumPoints: ['機能A', '機能B'],
            previewChild: Text('コンテンツ'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 非Web環境ではpreviewChildをそのまま表示
      expect(find.text('コンテンツ'), findsOneWidget);
      // アップグレードカードは表示されない
      expect(find.text('プレミアムプランを見る'), findsNothing);
    });

    testWidgets('previewChild 未指定でもクラッシュしない', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const SizedBox(
            width: 300,
            height: 300,
            child: PremiumGate(
              featureName: 'テスト機能',
              featureIcon: Icons.star,
              premiumPoints: ['ポイント1'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // クラッシュしないことを確認
      expect(find.byType(PremiumGate), findsOneWidget);
    });
  });

  group('PremiumSectionGate（非Web環境）', () {
    testWidgets('isPremium=true のとき何も表示しない', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const PremiumSectionGate(
            featureName: '目標別統計',
            featureIcon: Icons.bar_chart,
            premiumPoints: ['詳細分析'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 非Web環境ではSizedBox.shrinkが返るのでゲートコンテンツは表示されない
      expect(find.text('目標別統計'), findsNothing);
      expect(find.text('プレミアムプランを見る'), findsNothing);
    });
  });

  group('訴求ポイントの定義', () {
    test('PremiumGateのpremiumPointsは空でも問題ない', () {
      const gate = PremiumGate(
        featureName: 'テスト',
        featureIcon: Icons.star,
        premiumPoints: [],
      );
      expect(gate.premiumPoints, isEmpty);
    });

    test('PremiumSectionGateのpremiumPointsが設定される', () {
      const gate = PremiumSectionGate(
        featureName: '目標別統計',
        featureIcon: Icons.bar_chart,
        premiumPoints: ['ポイント1', 'ポイント2'],
      );
      expect(gate.premiumPoints, hasLength(2));
      expect(gate.featureName, '目標別統計');
    });
  });
}
