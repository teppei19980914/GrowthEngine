import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/models/goal.dart';

void main() {
  group('WhenType', () {
    test('values have correct string values', () {
      expect(WhenType.date.value, 'date');
      expect(WhenType.period.value, 'period');
    });

    test('fromValue returns correct enum', () {
      expect(WhenType.fromValue('date'), WhenType.date);
      expect(WhenType.fromValue('period'), WhenType.period);
    });

    test('fromValue throws on invalid value', () {
      expect(
        () => WhenType.fromValue('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('goalColors', () {
    test('has 8 colors', () {
      expect(goalColors.length, 8);
    });

    test('all colors start with #', () {
      for (final color in goalColors) {
        expect(color.startsWith('#'), isTrue);
      }
    });
  });

  group('Goal', () {
    late Goal goal;

    setUp(() {
      goal = Goal(
        dreamId: 'dream-1',
        why: 'キャリアアップ',
        whenTarget: '2026-12-31',
        whenType: WhenType.date,
        what: 'Flutter開発',
        how: '毎日1時間練習',
      );
    });

    test('creates with default values', () {
      expect(goal.id, isNotEmpty);
      expect(goal.why, 'キャリアアップ');
      expect(goal.whenTarget, '2026-12-31');
      expect(goal.whenType, WhenType.date);
      expect(goal.what, 'Flutter開発');
      expect(goal.how, '毎日1時間練習');
      expect(goal.color, goalColors[0]);
      expect(goal.createdAt, isNotNull);
      expect(goal.updatedAt, isNotNull);
    });

    test('creates with custom id', () {
      final customGoal = Goal(
        id: 'custom-id',
        dreamId: 'dream-1',
        why: 'テスト',
        whenTarget: '2026-06-30',
        whenType: WhenType.period,
        what: 'テスト目標',
        how: 'テスト方法',
      );
      expect(customGoal.id, 'custom-id');
    });

    test('creates with custom color', () {
      final colorGoal = Goal(
        dreamId: 'dream-1',
        why: 'テスト',
        whenTarget: '2026-06-30',
        whenType: WhenType.date,
        what: 'テスト',
        how: 'テスト',
        color: '#FF0000',
      );
      expect(colorGoal.color, '#FF0000');
    });

    group('getTargetDate', () {
      test('returns DateTime for DATE type with valid date', () {
        final targetDate = goal.getTargetDate();
        expect(targetDate, isNotNull);
        expect(targetDate!.year, 2026);
        expect(targetDate.month, 12);
        expect(targetDate.day, 31);
      });

      test('returns null for PERIOD type', () {
        final periodGoal = Goal(
          dreamId: 'dream-1',
          why: 'テスト',
          whenTarget: '3ヶ月以内',
          whenType: WhenType.period,
          what: 'テスト',
          how: 'テスト',
        );
        expect(periodGoal.getTargetDate(), isNull);
      });

      test('returns null for DATE type with invalid date string', () {
        final invalidGoal = Goal(
          dreamId: 'dream-1',
          why: 'テスト',
          whenTarget: 'invalid-date',
          whenType: WhenType.date,
          what: 'テスト',
          how: 'テスト',
        );
        expect(invalidGoal.getTargetDate(), isNull);
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final copied = goal.copyWith(
          why: '新しい理由',
          color: '#FF0000',
        );
        expect(copied.why, '新しい理由');
        expect(copied.color, '#FF0000');
        expect(copied.what, goal.what);
        expect(copied.id, goal.id);
      });

      test('copies with no changes returns equivalent', () {
        final copied = goal.copyWith();
        expect(copied.id, goal.id);
        expect(copied.why, goal.why);
        expect(copied.whenTarget, goal.whenTarget);
        expect(copied.whenType, goal.whenType);
        expect(copied.what, goal.what);
        expect(copied.how, goal.how);
        expect(copied.color, goal.color);
      });
    });

    group('toMap / fromMap', () {
      test('round-trip serialization', () {
        final map = goal.toMap();
        final restored = Goal.fromMap(map);
        expect(restored.id, goal.id);
        expect(restored.why, goal.why);
        expect(restored.whenTarget, goal.whenTarget);
        expect(restored.whenType, goal.whenType);
        expect(restored.what, goal.what);
        expect(restored.how, goal.how);
        expect(restored.color, goal.color);
      });

      test('toMap contains correct keys', () {
        final map = goal.toMap();
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('why'), isTrue);
        expect(map.containsKey('when_target'), isTrue);
        expect(map.containsKey('when_type'), isTrue);
        expect(map.containsKey('what'), isTrue);
        expect(map.containsKey('how'), isTrue);
        expect(map.containsKey('created_at'), isTrue);
        expect(map.containsKey('updated_at'), isTrue);
        expect(map.containsKey('color'), isTrue);
      });

      test('toMap stores enum as string value', () {
        final map = goal.toMap();
        expect(map['when_type'], 'date');
      });

      test('fromMap uses default color when missing', () {
        final map = goal.toMap();
        map.remove('color');
        final restored = Goal.fromMap(map);
        expect(restored.color, goalColors[0]);
      });
    });

    group('equality', () {
      test('equal when same id', () {
        final goal1 = Goal(
          id: 'same-id',
          dreamId: 'dream-1',
          why: 'A',
          whenTarget: '2026-01-01',
          whenType: WhenType.date,
          what: 'A',
          how: 'A',
        );
        final goal2 = Goal(
          id: 'same-id',
          dreamId: 'dream-1',
          why: 'B',
          whenTarget: '2026-12-31',
          whenType: WhenType.period,
          what: 'B',
          how: 'B',
        );
        expect(goal1, equals(goal2));
        expect(goal1.hashCode, goal2.hashCode);
      });

      test('not equal when different id', () {
        final goal1 = Goal(
          id: 'id-1',
          dreamId: 'dream-1',
          why: 'テスト',
          whenTarget: '2026-01-01',
          whenType: WhenType.date,
          what: 'テスト',
          how: 'テスト',
        );
        final goal2 = Goal(
          id: 'id-2',
          dreamId: 'dream-1',
          why: 'テスト',
          whenTarget: '2026-01-01',
          whenType: WhenType.date,
          what: 'テスト',
          how: 'テスト',
        );
        expect(goal1, isNot(equals(goal2)));
      });
    });

    test('toString contains id and what', () {
      final str = goal.toString();
      expect(str, contains(goal.id));
      expect(str, contains(goal.what));
    });
  });
}
