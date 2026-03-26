/// アカウント連携ダイアログ.
///
/// 匿名ユーザーがメール/パスワードでアカウント昇格するか、
/// 既存アカウントでログインしてデータを復元するためのダイアログ.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_sync_service.dart';
import '../theme/app_theme.dart';

/// アカウント連携ダイアログの結果.
enum CloudAuthResult {
  /// アカウント連携成功（匿名→メール昇格）.
  linked,

  /// 既存アカウントでログイン成功（データ復元が必要）.
  loggedIn,

  /// スキップ（後で設定する）.
  skipped,
}

/// アカウント連携ダイアログを表示する.
Future<CloudAuthResult?> showCloudAuthDialog(BuildContext context) async {
  return showDialog<CloudAuthResult>(
    context: context,
    builder: (context) => const _CloudAuthDialog(),
  );
}

class _CloudAuthDialog extends StatefulWidget {
  const _CloudAuthDialog();

  @override
  State<_CloudAuthDialog> createState() => _CloudAuthDialogState();
}

class _CloudAuthDialogState extends State<_CloudAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // false=アカウント昇格（新規連携）, true=既存ログイン
  bool _isLogin = false;
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  final _syncService = FirestoreSyncService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        // 既存アカウントでログイン（別端末からの復元用）
        await _syncService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // 匿名アカウントをメール/パスワードに昇格
        await _syncService.linkWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.pop(
          context,
          _isLogin ? CloudAuthResult.loggedIn : CloudAuthResult.linked,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = _authErrorMessage(e.code);
      });
    } on StateError catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return 'このメールアドレスは既に登録されています。'
            '「既にアカウントをお持ちの方」からログインしてください。';
      case 'weak-password':
        return 'パスワードは6文字以上で設定してください。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'user-not-found':
        return 'アカウントが見つかりません。新規連携してください。';
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません。';
      default:
        return '認証エラーが発生しました（$code）';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      title: Row(
        children: [
          Icon(Icons.link, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_isLogin ? 'アカウントでログイン' : 'アカウント連携'),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 説明
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLogin ? Icons.cloud_download : Icons.shield_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLogin
                              ? '登録済みのアカウントでログインしてデータを復元します。'
                              : 'メールアドレスを連携すると、端末変更やキャッシュクリア時も'
                                  'データを復元できます。',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: colors.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Text('メールアドレス', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '必須項目です';
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@'
                      r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}'
                      r'[a-zA-Z0-9])?(?:\.[a-zA-Z0-9]'
                      r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
                    );
                    if (!emailRegex.hasMatch(v.trim())) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Text('パスワード', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '6文字以上',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '必須項目です';
                    if (v.length < 6) return '6文字以上で入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 切り替えリンク
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                    }),
                    child: Text(
                      _isLogin
                          ? '初めてご利用の方はこちら（アカウント連携）'
                          : '既にアカウントをお持ちの方はこちら（ログイン）',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () => Navigator.pop(context, CloudAuthResult.skipped),
          child: const Text('あとで'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLogin ? 'ログイン' : '連携する'),
        ),
      ],
    );
  }
}
