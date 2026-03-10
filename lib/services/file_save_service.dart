/// ファイル保存のプラットフォーム抽象化.
library;

import 'dart:typed_data';

import 'file_save_service_native.dart'
    if (dart.library.js_interop) 'file_save_service_web.dart' as platform;

/// ファイルを保存する.
///
/// Web: ブラウザのダウンロード機能を使用.
/// Native: file_pickerで保存先を選択して保存.
Future<bool> saveFile({
  required Uint8List bytes,
  required String fileName,
}) {
  return platform.saveFile(bytes: bytes, fileName: fileName);
}

/// ファイルを読み込む.
///
/// file_pickerで選択したファイルのバイトデータを返す.
Future<Uint8List?> pickFile({
  required List<String> allowedExtensions,
}) {
  return platform.pickFile(allowedExtensions: allowedExtensions);
}
