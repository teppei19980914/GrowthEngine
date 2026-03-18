import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_log/models/notification.dart' as model;
import 'package:yume_log/widgets/notification/notification_button.dart';

import '../helpers/test_helpers.dart';

void main() {
  final setup = TestSetup();

  setUp(() => setup.setUp());
  tearDown(() => setup.tearDown());

  Future<SharedPreferences> getPrefs() async =>
      SharedPreferences.getInstance();

  testWidgets('未読0件でバッジが表示されない', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const NotificationButton(),
        prefs: prefs,
        db: setup.db,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    // バッジ（数字）は表示されない
    expect(find.text('0'), findsNothing);
  });

  testWidgets('未読件数バッジが表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const NotificationButton(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          unreadCountProvider.overrideWith((ref) async => 5),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('9件超は9+と表示される', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const NotificationButton(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          unreadCountProvider.overrideWith((ref) async => 15),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets('ボタンタップで通知ポップアップが開く', (tester) async {
    final prefs = await getPrefs();
    await tester.pumpWidget(
      wrapWithProviders(
        const NotificationButton(),
        prefs: prefs,
        db: setup.db,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('通知'), findsOneWidget);
    expect(find.text('新しい通知はここに届きます'), findsOneWidget);
  });

  testWidgets('通知がある場合リストに表示される', (tester) async {
    final prefs = await getPrefs();
    final notification = model.Notification(
      notificationType: model.NotificationType.achievement,
      title: '累計1時間達成！',
      message: '素晴らしい！',
    );
    await tester.pumpWidget(
      wrapWithProviders(
        const NotificationButton(),
        prefs: prefs,
        db: setup.db,
        customOverrides: [
          unreadCountProvider.overrideWith((ref) async => 1),
          allNotificationsProvider.overrideWith(
            (ref) async => [notification],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('累計1時間達成！'), findsOneWidget);
    expect(find.text('素晴らしい！'), findsOneWidget);
  });
}
