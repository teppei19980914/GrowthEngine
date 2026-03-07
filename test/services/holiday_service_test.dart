import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/services/holiday_service.dart';

void main() {
  late HolidayService service;

  setUp(() {
    service = HolidayService();
  });

  group('HolidayService', () {
    group('isHoliday', () {
      test('元日を祝日と判定する', () {
        expect(service.isHoliday(DateTime(2025, 1, 1)), isTrue);
      });

      test('平日を祝日と判定しない', () {
        expect(service.isHoliday(DateTime(2025, 6, 2)), isFalse);
      });

      test('建国記念の日を判定する', () {
        expect(service.isHoliday(DateTime(2025, 2, 11)), isTrue);
      });

      test('天皇誕生日（2020年以降）', () {
        expect(service.isHoliday(DateTime(2025, 2, 23)), isTrue);
      });

      test('昭和の日を判定する', () {
        expect(service.isHoliday(DateTime(2025, 4, 29)), isTrue);
      });

      test('憲法記念日を判定する', () {
        expect(service.isHoliday(DateTime(2025, 5, 3)), isTrue);
      });

      test('みどりの日を判定する', () {
        expect(service.isHoliday(DateTime(2025, 5, 4)), isTrue);
      });

      test('こどもの日を判定する', () {
        expect(service.isHoliday(DateTime(2025, 5, 5)), isTrue);
      });

      test('文化の日を判定する', () {
        expect(service.isHoliday(DateTime(2025, 11, 3)), isTrue);
      });

      test('勤労感謝の日を判定する', () {
        expect(service.isHoliday(DateTime(2025, 11, 23)), isTrue);
      });

      test('山の日を判定する', () {
        expect(service.isHoliday(DateTime(2025, 8, 11)), isTrue);
      });
    });

    group('getHolidayName', () {
      test('祝日名を取得する', () {
        expect(service.getHolidayName(DateTime(2025, 1, 1)), '元日');
      });

      test('平日ではnullを返す', () {
        expect(service.getHolidayName(DateTime(2025, 6, 2)), isNull);
      });

      test('春分の日を取得する', () {
        final name = service.getHolidayName(DateTime(2025, 3, 20));
        expect(name, '春分の日');
      });

      test('秋分の日を取得する', () {
        final name = service.getHolidayName(DateTime(2025, 9, 23));
        expect(name, '秋分の日');
      });
    });

    group('getHolidaysInMonth', () {
      test('1月の祝日を取得する', () {
        final holidays = service.getHolidaysInMonth(2025, 1);
        expect(holidays.isNotEmpty, isTrue);
        expect(holidays[DateTime(2025, 1, 1)], '元日');
      });

      test('5月の祝日（GW）を取得する', () {
        final holidays = service.getHolidaysInMonth(2025, 5);
        expect(holidays.length, greaterThanOrEqualTo(3));
      });

      test('祝日のない月は空', () {
        // 6月は祝日がない（振替休日を除く）
        final holidays = service.getHolidaysInMonth(2025, 6);
        expect(holidays.isEmpty, isTrue);
      });
    });

    group('isSaturday / isSunday', () {
      test('土曜日を判定する', () {
        expect(service.isSaturday(DateTime(2025, 3, 1)), isTrue);
        expect(service.isSaturday(DateTime(2025, 3, 3)), isFalse);
      });

      test('日曜日を判定する', () {
        expect(service.isSunday(DateTime(2025, 3, 2)), isTrue);
        expect(service.isSunday(DateTime(2025, 3, 3)), isFalse);
      });
    });

    group('振替休日', () {
      test('日曜日の祝日は翌日に振替', () {
        // 2025-11-03 (月) 文化の日 — 振替なし
        // 2025-11-23 (日) 勤労感謝の日 → 11/24が振替休日
        expect(service.isHoliday(DateTime(2025, 11, 24)), isTrue);
        expect(service.getHolidayName(DateTime(2025, 11, 24)), '振替休日');
      });
    });

    group('成人の日（1月第2月曜）', () {
      test('2025年の成人の日', () {
        expect(service.isHoliday(DateTime(2025, 1, 13)), isTrue);
        expect(service.getHolidayName(DateTime(2025, 1, 13)), '成人の日');
      });
    });

    group('海の日（7月第3月曜）', () {
      test('2025年の海の日', () {
        expect(service.isHoliday(DateTime(2025, 7, 21)), isTrue);
        expect(service.getHolidayName(DateTime(2025, 7, 21)), '海の日');
      });
    });

    group('敬老の日（9月第3月曜）', () {
      test('2025年の敬老の日', () {
        expect(service.isHoliday(DateTime(2025, 9, 15)), isTrue);
        expect(service.getHolidayName(DateTime(2025, 9, 15)), '敬老の日');
      });
    });

    group('スポーツの日（10月第2月曜）', () {
      test('2025年のスポーツの日', () {
        expect(service.isHoliday(DateTime(2025, 10, 13)), isTrue);
        expect(
          service.getHolidayName(DateTime(2025, 10, 13)),
          'スポーツの日',
        );
      });
    });

    group('キャッシュ', () {
      test('キャッシュが動作する', () {
        service.isHoliday(DateTime(2025, 1, 1));
        service.isHoliday(DateTime(2025, 6, 1)); // same year, cached
        expect(service.getHolidayName(DateTime(2025, 1, 1)), '元日');
      });

      test('キャッシュクリアが動作する', () {
        service.isHoliday(DateTime(2025, 1, 1));
        service.clearCache();
        // After clearing, should still work
        expect(service.isHoliday(DateTime(2025, 1, 1)), isTrue);
      });
    });
  });
}
