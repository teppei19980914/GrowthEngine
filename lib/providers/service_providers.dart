/// サービス層のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/book_gantt_service.dart';
import '../services/book_service.dart';
import '../services/dashboard_layout_service.dart';
import '../services/data_export_service.dart';
import '../services/dream_service.dart';
import '../services/feedback_service.dart';
import '../services/goal_service.dart';
import '../services/notification_service.dart';
import '../services/study_log_service.dart';
import '../services/task_service.dart';
import '../services/tutorial_service.dart';
import 'database_provider.dart';
import 'theme_provider.dart';

/// DreamServiceのProvider.
final dreamServiceProvider = Provider<DreamService>((ref) {
  final db = ref.watch(databaseProvider);
  return DreamService(
    dreamDao: db.dreamDao,
    goalDao: db.goalDao,
    taskDao: db.taskDao,
  );
});

/// GoalServiceのProvider.
final goalServiceProvider = Provider<GoalService>((ref) {
  final db = ref.watch(databaseProvider);
  return GoalService(goalDao: db.goalDao, taskDao: db.taskDao);
});

/// TaskServiceのProvider.
final taskServiceProvider = Provider<TaskService>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskService(taskDao: db.taskDao);
});

/// BookServiceのProvider.
final bookServiceProvider = Provider<BookService>((ref) {
  final db = ref.watch(databaseProvider);
  return BookService(bookDao: db.bookDao, taskDao: db.taskDao);
});

/// StudyLogServiceのProvider.
final studyLogServiceProvider = Provider<StudyLogService>((ref) {
  final db = ref.watch(databaseProvider);
  return StudyLogService(studyLogDao: db.studyLogDao);
});

/// BookGanttServiceのProvider.
final bookGanttServiceProvider = Provider<BookGanttService>((ref) {
  final bookService = ref.watch(bookServiceProvider);
  final taskService = ref.watch(taskServiceProvider);
  return BookGanttService(bookService: bookService, taskService: taskService);
});

/// NotificationServiceのProvider.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationService(notificationDao: db.notificationDao);
});

/// DataExportServiceのProvider.
final dataExportServiceProvider = Provider<DataExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return DataExportService(
    dreamDao: db.dreamDao,
    goalDao: db.goalDao,
    taskDao: db.taskDao,
    bookDao: db.bookDao,
    studyLogDao: db.studyLogDao,
    notificationDao: db.notificationDao,
  );
});

/// DashboardLayoutServiceのProvider.
final dashboardLayoutServiceProvider =
    Provider<DashboardLayoutService>((ref) {
  return DashboardLayoutService();
});

/// FeedbackServiceのProvider.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FeedbackService(prefs);
});

/// 現在の解除レベルのProvider.
final unlockLevelProvider = Provider<int>((ref) {
  return ref.watch(feedbackServiceProvider).unlockLevel;
});

/// TutorialServiceのProvider.
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TutorialService(prefs);
});
