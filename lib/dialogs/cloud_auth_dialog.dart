/// クラウド認証ダイアログ.
///
/// プレミアムプランユーザーがFirebaseアカウントを作成/ログインするためのダイアログ.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_sync_service.dart';
import '../theme/app_theme.dart';

/// クラウド認証ダイアログの結果.
enum CloudAuthResult {
  /// サインイン/サインアップ成功.
  success,

  /// スキップ（後で設定する）.
  skipped,
}

/// クラウド認証ダイアログを表示する.
Future<CloudAuthResult?> showCloudAuthDialog(
  BuildContext context, {
  String? initialEmail,
}) async {
  return showDialog<CloudAuthResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _CloudAuthDialog(initialEmail: initialEmail),
  );
}

class _CloudAuthDialog extends StatefulWidget {
  const _CloudAuthDialog({this.initialEmail});
  final String? initialEmail;

  @override
  State<_CloudAuthDialog> createState() => _CloudAuthDialogState();
}

class _CloudAuthDialogState extends State<_CloudAuthDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _isLogin = false; // false=新規作成, true=ログイン
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  final _syncService = FirestoreSyncService();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

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
        await _syncService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _syncService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) Navigator.pop(context, CloudAuthResult.success);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = _authErrorMessage(e.code);
      });
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に登録されています。ログインしてください。';
      case 'weak-password':
        return 'パスワードは6文字以上で設定してください。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'user-not-found':
        return 'アカウントが見つかりません。新規登録してください。';
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
      title: Row(
        children: [
          Icon(Icons.cloud_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(_isLogin ? 'クラウドにログイン' : 'クラウドアカウント作成'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLogin
                      ? '登録済みのアカウントでログインしてデータを復元します。'
                      : 'データをクラウドに保存するためのアカウントを作成します。\n'
                          'キャッシュクリアや端末変更時もデータを復元できます。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
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
                    if (!v.contains('@')) return '有効なメールアドレスを入力してください';
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
                          ? '初めてご利用の方はこちら（新規登録）'
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
          child: const Text('あとで設定する'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLogin ? 'ログイン' : 'アカウント作成'),
        ),
      ],
    );
  }
}
