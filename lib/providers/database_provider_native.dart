/// ネイティブプラットフォーム用データベース接続.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ネイティブ環境でのデータベース接続を作成する.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(dbDir.path, 'YumeLog'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File(p.join(dir.path, 'yume_log.db'));
    return NativeDatabase.createInBackground(file);
  });
}
