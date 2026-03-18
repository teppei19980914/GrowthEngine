import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/dialogs/reading_log_dialog.dart';

void main() {
  group('bookLogTaskId', () {
    test('書籍IDからログ用taskIdを生成する', () {
      expect(bookLogTaskId('abc123'), 'book__abc123');
    });

    test('isBookLogTaskIdが正しく判定する', () {
      expect(isBookLogTaskId('book__abc123'), isTrue);
      expect(isBookLogTaskId('task-123'), isFalse);
      expect(isBookLogTaskId(''), isFalse);
    });
  });

  // 読書ログのDB操作テストは study_log_service_test.dart で
  // 既存のStudyLogServiceテストがカバーしている（taskIdの値が異なるだけ）
}
