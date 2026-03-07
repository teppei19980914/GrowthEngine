import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yume_log/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Dreams table', () {
    test('insert and read back a dream', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      await db.dreamDao.insertDream(DreamsCompanion(
        id: const Value('dream-1'),
        title: const Value('Become a software architect'),
        description: const Value('Build large-scale systems'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final dreams = await db.dreamDao.getAll();
      expect(dreams, hasLength(1));

      final dream = dreams.first;
      expect(dream.id, 'dream-1');
      expect(dream.title, 'Become a software architect');
      expect(dream.description, 'Build large-scale systems');
      expect(dream.createdAt, now);
      expect(dream.updatedAt, now);
    });

    test('description defaults to empty string', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      await db.dreamDao.insertDream(DreamsCompanion(
        id: const Value('dream-2'),
        title: const Value('Minimal dream'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final dream = (await db.dreamDao.getAll()).first;
      expect(dream.description, '');
    });
  });

  group('Goals table', () {
    test('insert and read back a goal', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      await db.goalDao.insertGoal(GoalsCompanion(
        id: const Value('goal-1'),
        dreamId: const Value('dream-1'),
        why: const Value('To improve career prospects'),
        whenTarget: const Value('2026-12-31'),
        whenType: const Value('date'),
        what: const Value('Learn system design'),
        how: const Value('Online courses and books'),
        color: const Value('#FF5733'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final goals = await db.goalDao.getAll();
      expect(goals, hasLength(1));

      final goal = goals.first;
      expect(goal.id, 'goal-1');
      expect(goal.dreamId, 'dream-1');
      expect(goal.why, 'To improve career prospects');
      expect(goal.whenTarget, '2026-12-31');
      expect(goal.whenType, 'date');
      expect(goal.what, 'Learn system design');
      expect(goal.how, 'Online courses and books');
      expect(goal.color, '#FF5733');
      expect(goal.createdAt, now);
      expect(goal.updatedAt, now);
    });

    test('dreamId and color have defaults', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      await db.goalDao.insertGoal(GoalsCompanion(
        id: const Value('goal-2'),
        why: const Value('Curiosity'),
        whenTarget: const Value('soon'),
        whenType: const Value('period'),
        what: const Value('Dart'),
        how: const Value('Practice'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final goal = (await db.goalDao.getAll()).first;
      expect(goal.dreamId, '');
      expect(goal.color, '#4A9EFF');
    });
  });

  group('Tasks table', () {
    test('insert and read back a task', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      final start = DateTime(2026, 3, 1);
      final end = DateTime(2026, 3, 31);

      await db.taskDao.insertTask(TasksCompanion(
        id: const Value('task-1'),
        goalId: const Value('goal-1'),
        title: const Value('Read chapter 1'),
        startDate: Value(start),
        endDate: Value(end),
        status: const Value('in_progress'),
        progress: const Value(50),
        memo: const Value('Good progress so far'),
        bookId: const Value('book-1'),
        order: const Value(1),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final tasks = await db.taskDao.getAll();
      expect(tasks, hasLength(1));

      final task = tasks.first;
      expect(task.id, 'task-1');
      expect(task.goalId, 'goal-1');
      expect(task.title, 'Read chapter 1');
      expect(task.startDate, start);
      expect(task.endDate, end);
      expect(task.status, 'in_progress');
      expect(task.progress, 50);
      expect(task.memo, 'Good progress so far');
      expect(task.bookId, 'book-1');
      expect(task.order, 1);
    });

    test('status, progress, memo, bookId, and order have defaults', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      await db.taskDao.insertTask(TasksCompanion(
        id: const Value('task-2'),
        goalId: const Value('goal-1'),
        title: const Value('Minimal task'),
        startDate: Value(now),
        endDate: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final task = (await db.taskDao.getAll()).first;
      expect(task.status, 'not_started');
      expect(task.progress, 0);
      expect(task.memo, '');
      expect(task.bookId, '');
      expect(task.order, 0);
    });
  });

  group('Books table', () {
    test('insert and read back a book', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      final completed = DateTime(2026, 2, 15);

      await db.bookDao.insertBook(BooksCompanion(
        id: const Value('book-1'),
        title: const Value('Clean Architecture'),
        status: const Value('completed'),
        summary: const Value('Great book on architecture'),
        impressions: const Value('Very insightful'),
        completedDate: Value(completed),
        startDate: Value(DateTime(2026, 1, 1)),
        endDate: Value(DateTime(2026, 2, 15)),
        progress: const Value(100),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final books = await db.bookDao.getAll();
      expect(books, hasLength(1));

      final book = books.first;
      expect(book.id, 'book-1');
      expect(book.title, 'Clean Architecture');
      expect(book.status, 'completed');
      expect(book.summary, 'Great book on architecture');
      expect(book.impressions, 'Very insightful');
      expect(book.completedDate, completed);
      expect(book.progress, 100);
    });

    test('status, summary, impressions, and progress have defaults; dates are nullable', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      await db.bookDao.insertBook(BooksCompanion(
        id: const Value('book-2'),
        title: const Value('Minimal book'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final book = (await db.bookDao.getAll()).first;
      expect(book.status, 'unread');
      expect(book.summary, '');
      expect(book.impressions, '');
      expect(book.completedDate, isNull);
      expect(book.startDate, isNull);
      expect(book.endDate, isNull);
      expect(book.progress, 0);
    });
  });

  group('StudyLogs table', () {
    test('insert and read back a study log', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      final studyDate = DateTime(2026, 3, 5);

      await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
        id: const Value('log-1'),
        taskId: const Value('task-1'),
        studyDate: Value(studyDate),
        durationMinutes: const Value(90),
        memo: const Value('Studied chapter 3'),
        taskName: const Value('Read chapter 3'),
        createdAt: Value(now),
      ));

      final logs = await db.studyLogDao.getAll();
      expect(logs, hasLength(1));

      final log = logs.first;
      expect(log.id, 'log-1');
      expect(log.taskId, 'task-1');
      expect(log.studyDate, studyDate);
      expect(log.durationMinutes, 90);
      expect(log.memo, 'Studied chapter 3');
      expect(log.taskName, 'Read chapter 3');
      expect(log.createdAt, now);
    });

    test('memo and taskName default to empty string', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      await db.studyLogDao.insertStudyLog(StudyLogsCompanion(
        id: const Value('log-2'),
        taskId: const Value('task-1'),
        studyDate: Value(now),
        durationMinutes: const Value(30),
        createdAt: Value(now),
      ));

      final log = (await db.studyLogDao.getAll()).first;
      expect(log.memo, '');
      expect(log.taskName, '');
    });
  });

  group('Notifications table', () {
    test('insert and read back a notification', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);

      await db.notificationDao.insertNotification(NotificationsCompanion(
        id: const Value('notif-1'),
        notificationType: const Value('achievement'),
        title: const Value('Goal completed!'),
        message: const Value('You finished your first goal'),
        isRead: const Value(false),
        createdAt: Value(now),
        dedupKey: const Value('achievement-goal-1'),
      ));

      final notifications = await db.notificationDao.getAll();
      expect(notifications, hasLength(1));

      final notif = notifications.first;
      expect(notif.id, 'notif-1');
      expect(notif.notificationType, 'achievement');
      expect(notif.title, 'Goal completed!');
      expect(notif.message, 'You finished your first goal');
      expect(notif.isRead, false);
      expect(notif.createdAt, now);
      expect(notif.dedupKey, 'achievement-goal-1');
    });

    test('isRead defaults to false and dedupKey defaults to empty string', () async {
      final n = DateTime.now(); final now = DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
      await db.notificationDao.insertNotification(NotificationsCompanion(
        id: const Value('notif-2'),
        notificationType: const Value('system'),
        title: const Value('Welcome'),
        message: const Value('Welcome to the app'),
        createdAt: Value(now),
      ));

      final notif = (await db.notificationDao.getAll()).first;
      expect(notif.isRead, false);
      expect(notif.dedupKey, '');
    });
  });
}
