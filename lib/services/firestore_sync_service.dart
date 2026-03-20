/// Firestore データ同期サービス.
///
/// プレミアムプランユーザーのローカルデータをFirestoreに同期する.
/// ローカルSQLiteをマスターとし、Firestoreをバックアップとして使用する.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestoreデータ同期サービス.
class FirestoreSyncService {
  /// FirestoreSyncServiceを作成する.
  FirestoreSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// 現在のFirebaseユーザー.
  User? get currentUser => _auth.currentUser;

  /// ログイン済みかどうか.
  bool get isSignedIn => _auth.currentUser != null;

  /// ユーザーのドキュメント参照.
  DocumentReference? get _userDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  /// メール+パスワードでサインアップ（新規ユーザー作成）.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// メール+パスワードでサインイン.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// サインアウト.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ローカルデータをFirestoreにアップロード（全データ同期）.
  ///
  /// [exportedJson] はDataExportService.exportData()の結果.
  Future<void> uploadData(String exportedJson) async {
    final doc = _userDoc;
    if (doc == null) return;

    await doc.set({
      'data': exportedJson,
      'updatedAt': FieldValue.serverTimestamp(),
      'email': _auth.currentUser?.email,
    }, SetOptions(merge: true));
  }

  /// Firestoreからデータをダウンロード.
  ///
  /// 保存済みデータのJSON文字列を返す. データがない場合はnull.
  Future<String?> downloadData() async {
    final doc = _userDoc;
    if (doc == null) return null;

    final snapshot = await doc.get();
    if (!snapshot.exists) return null;

    final data = snapshot.data() as Map<String, dynamic>?;
    return data?['data'] as String?;
  }

  /// 最終同期日時を取得する.
  Future<DateTime?> getLastSyncTime() async {
    final doc = _userDoc;
    if (doc == null) return null;

    final snapshot = await doc.get();
    if (!snapshot.exists) return null;

    final data = snapshot.data() as Map<String, dynamic>?;
    final timestamp = data?['updatedAt'] as Timestamp?;
    return timestamp?.toDate();
  }

  /// ユーザーアカウントを削除する.
  Future<void> deleteAccount() async {
    final doc = _userDoc;
    if (doc != null) {
      await doc.delete();
    }
    await _auth.currentUser?.delete();
  }
}
