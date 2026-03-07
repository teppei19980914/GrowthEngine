/// Web プラットフォーム用データベース接続.
library;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web環境でのデータベース接続を作成する.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'yume_log',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
