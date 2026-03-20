/// アプリケーションデータベース.
library;

import 'package:drift/drift.dart';

import 'daos/book_dao.dart';
import 'daos/dream_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/notification_dao.dart';
import 'daos/study_log_dao.dart';
import 'daos/task_dao.dart';
import 'tables/books_table.dart';
import 'tables/dreams_table.dart';
import 'tables/goals_table.dart';
import 'tables/notifications_table.dart';
import 'tables/study_logs_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

/// アプリケーションのメインデータベース.
@DriftDatabase(
  tables: [Dreams, Goals, Tasks, Books, StudyLogs, Notifications],
  daos: [DreamDao, GoalDao, TaskDao, BookDao, StudyLogDao, NotificationDao],
)
class AppDatabase extends _$AppDatabase {
  /// AppDatabaseを作成する.
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(dreams);
            await m.addColumn(goals, goals.dreamId);
          }
          if (from < 3) {
            await m.addColumn(dreams, dreams.why);
          }
          if (from < 4) {
            await m.addColumn(books, books.why);
            await m.addColumn(books, books.description);
          }
          if (from < 5) {
            await m.addColumn(books, books.category);
          }
          if (from < 6) {
            await m.addColumn(dreams, dreams.category);
          }
        },
      );
}
