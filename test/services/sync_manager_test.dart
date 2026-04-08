import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yume_hashi/database/app_database.dart';
import 'package:yume_hashi/services/data_export_service.dart';
import 'package:yume_hashi/services/firestore_sync_service.dart' show CloudSyncClient;
import 'package:yume_hashi/services/sync_manager.dart';
import 'package:yume_hashi/services/sync_payload_codec.dart';

/// テスト用のCloudSyncClient実装.
class FakeCloudSyncClient implements CloudSyncClient {
  bool signedIn = true;
  DateTime? cloudUpdatedAt;
  String? cloudData;
  String? lastUploadedData;
  int uploadCount = 0;
  int downloadCount = 0;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<DateTime?> getLastSyncTime() async => cloudUpdatedAt;

  @override
  Future<void> uploadData(String exportedJson) async {
    lastUploadedData = exportedJson;
    cloudData = exportedJson;
    uploadCount++;
  }

  @override
  Future<String?> downloadData() async {
    downloadCount++;
    return cloudData;
  }
}

AppDatabase _createDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late DataExportService exportService;
  late FakeCloudSyncClient fakeSyncClient;
  late SyncManager syncManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = _createDb();
    exportService = DataExportService(
      dreamDao: db.dreamDao,
      goalDao: db.goalDao,
      taskDao: db.taskDao,
      bookDao: db.bookDao,
      studyLogDao: db.studyLogDao,
      notificationDao: db.notificationDao,
    );
    fakeSyncClient = FakeCloudSyncClient();

    syncManager = SyncManager.forTest(webMode: true);
    final prefs = await SharedPreferences.getInstance();
    syncManager.init(
      exportService,
      prefs: prefs,
      syncService: fakeSyncClient,
    );
  });

  tearDown(() async {
    syncManager.reset();
    await db.close();
  });

  Future<void> insertGoal() async {
    final now = DateTime.now();
    await db.goalDao.insertGoal(GoalsCompanion(
      id: const Value('goal-1'),
      dreamId: const Value(''),
      why: const Value('テスト'),
      whenTarget: const Value(''),
      whenType: const Value('none'),
      what: const Value('テスト目標'),
      how: const Value(''),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  group('SyncManager', () {
    test('syncNow uploads when cloud has no data', () async {
      await insertGoal();

      await syncManager.syncNow();

      expect(fakeSyncClient.uploadCount, 1);
      expect(fakeSyncClient.downloadCount, 0);
      expect(fakeSyncClient.lastUploadedData, isNotNull);

      // v2.1.0: アップロードペイロードは format 2 (gzip + Base64) で送信される
      expect(
        isCompressedSyncPayload(fakeSyncClient.lastUploadedData!),
        isTrue,
        reason: 'v2.1.0以降はクラウド同期は gzip 圧縮形式で送信される',
      );
      final decodedJson = decodeSyncPayload(fakeSyncClient.lastUploadedData!);
      final uploaded = json.decode(decodedJson) as Map<String, dynamic>;
      expect(uploaded['goals'], hasLength(1));
    });

    test('syncNow downloads when cloud is newer than local', () async {
      // クラウドに先にデータを置く
      final cloudJson = await exportService.exportData();
      fakeSyncClient.cloudData = cloudJson;
      fakeSyncClient.cloudUpdatedAt =
          DateTime.now().toUtc().add(const Duration(hours: 1));

      await syncManager.syncNow();

      expect(fakeSyncClient.downloadCount, 1);
      expect(fakeSyncClient.uploadCount, 0);
    });

    test('syncNow uploads when local is newer than cloud', () async {
      await insertGoal();

      // ローカルの同期時刻を未来に設定
      final prefs = await SharedPreferences.getInstance();
      final futureMs = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 2))
          .millisecondsSinceEpoch;
      await prefs.setInt('cloud_last_sync_ms', futureMs);

      // クラウドの時刻はローカルより古い
      fakeSyncClient.cloudUpdatedAt =
          DateTime.now().toUtc().subtract(const Duration(hours: 1));

      await syncManager.syncNow();

      expect(fakeSyncClient.uploadCount, 1);
      expect(fakeSyncClient.downloadCount, 0);
    });

    test('syncNow downloads and imports data into local DB', () async {
      // 別DBでデータを作成しエクスポート
      final otherDb = _createDb();
      final otherExport = DataExportService(
        dreamDao: otherDb.dreamDao,
        goalDao: otherDb.goalDao,
        taskDao: otherDb.taskDao,
        bookDao: otherDb.bookDao,
        studyLogDao: otherDb.studyLogDao,
        notificationDao: otherDb.notificationDao,
      );
      final now = DateTime.now();
      await otherDb.goalDao.insertGoal(GoalsCompanion(
        id: const Value('cloud-goal'),
        dreamId: const Value(''),
        why: const Value('クラウドから'),
        whenTarget: const Value(''),
        whenType: const Value('none'),
        what: const Value('クラウド目標'),
        how: const Value(''),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      final cloudJson = await otherExport.exportData();
      await otherDb.close();

      // クラウドにデータを配置（ローカルより新しい）
      fakeSyncClient.cloudData = cloudJson;
      fakeSyncClient.cloudUpdatedAt =
          DateTime.now().toUtc().add(const Duration(hours: 1));

      // ローカルDBは空
      final goalsBefore = await db.goalDao.getAll();
      expect(goalsBefore, isEmpty);

      await syncManager.syncNow();

      // ダウンロード後、ローカルDBにクラウドのデータが反映される
      final goalsAfter = await db.goalDao.getAll();
      expect(goalsAfter, hasLength(1));
      expect(goalsAfter.first.id, 'cloud-goal');
      expect(goalsAfter.first.what, 'クラウド目標');
    });

    test('syncNow saves local sync timestamp after upload', () async {
      await insertGoal();
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getInt('cloud_last_sync_ms'), isNull);
      await syncManager.syncNow();
      expect(prefs.getInt('cloud_last_sync_ms'), isNotNull);
      expect(prefs.getInt('cloud_last_sync_ms')!, greaterThan(0));
    });

    test('syncNow saves local sync timestamp after download', () async {
      final cloudJson = await exportService.exportData();
      fakeSyncClient.cloudData = cloudJson;
      fakeSyncClient.cloudUpdatedAt =
          DateTime.now().toUtc().add(const Duration(hours: 1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('cloud_last_sync_ms'), isNull);

      await syncManager.syncNow();

      expect(prefs.getInt('cloud_last_sync_ms'), isNotNull);
    });

    test('syncNow skips when not signed in', () async {
      fakeSyncClient.signedIn = false;
      await insertGoal();

      await syncManager.syncNow();

      expect(fakeSyncClient.uploadCount, 0);
      expect(fakeSyncClient.downloadCount, 0);
    });

    test('syncNow does not import when cloud data is empty', () async {
      fakeSyncClient.cloudData = '';
      fakeSyncClient.cloudUpdatedAt =
          DateTime.now().toUtc().add(const Duration(hours: 1));

      await syncManager.syncNow();

      // ダウンロードは試行されるがデータが空なのでインポートされない
      expect(fakeSyncClient.downloadCount, 1);
      final goals = await db.goalDao.getAll();
      expect(goals, isEmpty);
    });

    test('legacy format 1（プレーンJSON）を保存している既存ユーザーのデータも'
        'ダウンロードできる', () async {
      // 既存ユーザーが v2.1.0 以前にアップロードしたプレーン JSON を模擬
      final otherDb = _createDb();
      final otherExport = DataExportService(
        dreamDao: otherDb.dreamDao,
        goalDao: otherDb.goalDao,
        taskDao: otherDb.taskDao,
        bookDao: otherDb.bookDao,
        studyLogDao: otherDb.studyLogDao,
        notificationDao: otherDb.notificationDao,
      );
      final now = DateTime.now();
      await otherDb.goalDao.insertGoal(GoalsCompanion(
        id: const Value('legacy-goal'),
        dreamId: const Value(''),
        why: const Value('legacy'),
        whenTarget: const Value(''),
        whenType: const Value('none'),
        what: const Value('レガシー目標'),
        how: const Value(''),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      // 旧形式: プレーン JSON 文字列（圧縮なし）として保存
      final legacyPayload = await otherExport.exportData();
      await otherDb.close();

      // legacy 形式であることを確認
      expect(isCompressedSyncPayload(legacyPayload), isFalse);

      fakeSyncClient.cloudData = legacyPayload;
      fakeSyncClient.cloudUpdatedAt =
          DateTime.now().toUtc().add(const Duration(hours: 1));

      await syncManager.syncNow();

      // 旧形式でも正しくインポートされる
      final goals = await db.goalDao.getAll();
      expect(goals, hasLength(1));
      expect(goals.first.id, 'legacy-goal');
      expect(goals.first.what, 'レガシー目標');
    });

    test('format 2（gzip圧縮）でアップロード後、別端末で正しくダウンロードできる', () async {
      // 端末A: データ作成 + アップロード
      await insertGoal();
      await syncManager.syncNow();

      // ペイロードが圧縮形式である
      expect(
        isCompressedSyncPayload(fakeSyncClient.cloudData!),
        isTrue,
      );

      // クラウド側のタイムスタンプを設定（FakeCloudSyncClient は uploadData で
      // cloudUpdatedAt を自動更新しないため、本物の Firestore を模擬して手動で設定）
      fakeSyncClient.cloudUpdatedAt =
          DateTime.now().toUtc().add(const Duration(hours: 1));

      // 端末B: 別 DB で同じクラウドデータをダウンロード
      final otherDb = _createDb();
      addTearDown(otherDb.close);
      final otherExport = DataExportService(
        dreamDao: otherDb.dreamDao,
        goalDao: otherDb.goalDao,
        taskDao: otherDb.taskDao,
        bookDao: otherDb.bookDao,
        studyLogDao: otherDb.studyLogDao,
        notificationDao: otherDb.notificationDao,
      );
      final otherSync = SyncManager.forTest(webMode: true);
      addTearDown(otherSync.reset);
      // 別端末の prefs を別インスタンスで用意し、ローカル時刻は過去にする
      SharedPreferences.setMockInitialValues({
        'cloud_last_sync_ms': DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
      });
      final otherPrefs = await SharedPreferences.getInstance();
      otherSync.init(
        otherExport,
        prefs: otherPrefs,
        syncService: fakeSyncClient,
      );

      await otherSync.syncNow();

      // 端末 B の DB に端末 A のデータが反映される
      final goalsB = await otherDb.goalDao.getAll();
      expect(goalsB, hasLength(1));
      expect(goalsB.first.id, 'goal-1');
    });
  });
}
