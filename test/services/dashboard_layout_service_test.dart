import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/services/dashboard_layout_service.dart';
import 'package:yume_log/services/study_stats_types.dart';

void main() {
  late DashboardLayoutService service;

  setUp(() {
    service = DashboardLayoutService();
  });

  group('DashboardLayoutService', () {
    group('getDefaultLayout', () {
      test('デフォルトレイアウトは11ウィジェット', () {
        final layout = service.getDefaultLayout();
        expect(layout.length, 11);
      });

      test('最初のウィジェットはtoday_banner', () {
        final layout = service.getDefaultLayout();
        expect(layout.first.widgetType, 'today_banner');
        expect(layout.first.columnSpan, 2);
      });
    });

    group('getAvailableWidgets', () {
      test('全ウィジェット使用中は空', () {
        final layout = service.getDefaultLayout();
        final available = service.getAvailableWidgets(layout);
        expect(available, isEmpty);
      });

      test('一部ウィジェット使用中は残りを返す', () {
        const layout = [
          DashboardWidgetConfig(
            widgetType: 'today_banner',
            columnSpan: 2,
          ),
        ];
        final available = service.getAvailableWidgets(layout);
        expect(available.length, widgetRegistry.length - 1);
      });

      test('空レイアウトでは全ウィジェット利用可能', () {
        final available =
            service.getAvailableWidgets(const <DashboardWidgetConfig>[]);
        expect(available.length, widgetRegistry.length);
      });
    });

    group('reorder', () {
      test('ウィジェットの順序を変更する', () {
        final layout = service.getDefaultLayout();
        final reordered = service.reorder(layout, 0, 2);
        expect(reordered[0].widgetType, layout[1].widgetType);
        expect(reordered[2].widgetType, layout[0].widgetType);
      });

      test('無効なインデックスでは変更しない', () {
        final layout = service.getDefaultLayout();
        final reordered = service.reorder(layout, -1, 0);
        expect(reordered.length, layout.length);
      });

      test('範囲外のtoIndexでは変更しない', () {
        final layout = service.getDefaultLayout();
        final reordered = service.reorder(layout, 0, 100);
        expect(reordered.length, layout.length);
      });
    });

    group('addWidget', () {
      test('ウィジェットを追加する', () {
        const layout = <DashboardWidgetConfig>[
          DashboardWidgetConfig(
            widgetType: 'today_banner',
            columnSpan: 2,
          ),
        ];
        final result = service.addWidget(layout, 'bookshelf');
        expect(result.length, 2);
        expect(result.last.widgetType, 'bookshelf');
        expect(result.last.columnSpan, 2); // default span
      });

      test('重複追加は無視する', () {
        const layout = [
          DashboardWidgetConfig(
            widgetType: 'today_banner',
            columnSpan: 2,
          ),
        ];
        final result = service.addWidget(layout, 'today_banner');
        expect(result.length, 1);
      });

      test('未知のウィジェットタイプは無視する', () {
        final result = service.addWidget([], 'unknown_widget');
        expect(result, isEmpty);
      });
    });

    group('removeWidget', () {
      test('ウィジェットを削除する', () {
        final layout = service.getDefaultLayout();
        final result = service.removeWidget(layout, 0);
        expect(result.length, layout.length - 1);
      });

      test('無効なインデックスでは変更しない', () {
        final layout = service.getDefaultLayout();
        final result = service.removeWidget(layout, -1);
        expect(result.length, layout.length);
      });

      test('範囲外のインデックスでは変更しない', () {
        final layout = service.getDefaultLayout();
        final result = service.removeWidget(layout, 100);
        expect(result.length, layout.length);
      });
    });

    group('resizeWidget', () {
      test('半幅から全幅に変更する', () {
        const layout = [
          DashboardWidgetConfig(
            widgetType: 'total_time_card',
            columnSpan: 1,
          ),
        ];
        final result = service.resizeWidget(layout, 0);
        expect(result[0].columnSpan, 2);
      });

      test('全幅から半幅に変更する', () {
        const layout = [
          DashboardWidgetConfig(
            widgetType: 'total_time_card',
            columnSpan: 2,
          ),
        ];
        final result = service.resizeWidget(layout, 0);
        expect(result[0].columnSpan, 1);
      });

      test('無効なインデックスでは変更しない', () {
        const layout = [
          DashboardWidgetConfig(
            widgetType: 'total_time_card',
            columnSpan: 1,
          ),
        ];
        final result = service.resizeWidget(layout, -1);
        expect(result[0].columnSpan, 1);
      });

      test('未知のウィジェットでは変更しない', () {
        const layout = [
          DashboardWidgetConfig(
            widgetType: 'unknown',
            columnSpan: 1,
          ),
        ];
        final result = service.resizeWidget(layout, 0);
        expect(result[0].columnSpan, 1);
      });
    });
  });

  group('widgetRegistry', () {
    test('11種のウィジェットが登録されている', () {
      expect(widgetRegistry.length, 11);
    });

    test('各ウィジェットにメタデータがある', () {
      for (final meta in widgetRegistry.values) {
        expect(meta.widgetType, isNotEmpty);
        expect(meta.displayName, isNotEmpty);
        expect(meta.icon, isNotEmpty);
        expect(meta.allowedSpans, isNotEmpty);
      }
    });
  });
}
