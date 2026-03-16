/// サービス層のProvider定義.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/book_gantt_service.dart';
import '../services/book_service.dart';
import '../services/dashboard_layout_service.dart';
import '../services/data_export_service.dart';
import '../services/dream_service.dart';
import '../services/feedback_service.dart';
import '../services/invite_service.dart';
import '../services/gantt_excel_export_service.dart';
import '../services/gantt_excel_import_service.dart';
import '../services/goal_service.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';
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

/// リモートユーザー設定のProvider.
///
/// main()でoverrideして使用する.
final remoteConfigProvider = Provider<UserConfig>((ref) {
  return UserConfig.defaultConfig;
});

/// InviteServiceのProvider.
final inviteServiceProvider = Provider<InviteService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return InviteService(prefs);
});

/// 招待コードの有効状態Provider.
final inviteStatusProvider = Provider<InviteStatus>((ref) {
  final inviteService = ref.watch(inviteServiceProvider);
  return inviteService.getStatus();
});

/// 現在の解除レベルのProvider.
///
/// 招待コードが有効な場合はfeedbackMaxLevelを返す.
/// リモート設定でunlimitedの場合はfeedbackMaxLevelを返す.
/// それ以外はリモート設定のunlockLevelとフィードバックの大きい方を返す.
final unlockLevelProvider = Provider<int>((ref) {
  final inviteStatus = ref.watch(inviteStatusProvider);
  if (inviteStatus.isActive) return feedbackMaxLevel;

  final remoteConfig = ref.watch(remoteConfigProvider);
  if (remoteConfig.unlimited) return feedbackMaxLevel;

  final feedbackLevel = ref.watch(feedbackServiceProvider).unlockLevel;
  final remoteLevel = remoteConfig.unlockLevel;
  return remoteLevel > feedbackLevel ? remoteLevel : feedbackLevel;
});

/// TutorialServiceのProvider.
final tutorialServiceProvider = Provider<TutorialService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TutorialService(prefs);
});

/// GanttExcelExportServiceのProvider.
final ganttExcelExportServiceProvider =
    Provider<GanttExcelExportService>((ref) {
  return GanttExcelExportService();
});

/// GanttExcelImportServiceのProvider.
final ganttExcelImportServiceProvider =
    Provider<GanttExcelImportService>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return GanttExcelImportService(taskService: taskService);
});
