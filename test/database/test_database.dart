/// テスト用インメモリデータベース.
library;

import 'package:drift/native.dart';
import 'package:yume_log/database/app_database.dart';

/// テスト用のインメモリAppDatabaseを作成する.
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
