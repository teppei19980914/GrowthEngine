/// Web環境でのファイル保存/読込.
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

/// ファイルを保存する（Web版）.
///
/// ブラウザのダウンロード機能を使用する.
Future<bool> saveFile({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
  List<String> allowedExtensions = const ['xlsx'],
}) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = fileName
        ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  web.document.body?.removeChild(anchor);
  web.URL.revokeObjectURL(url);
  return true;
}

/// ファイルを読み込む（Web版）.
Future<Uint8List?> pickFile({
  required List<String> allowedExtensions,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  return result.files.first.bytes;
}
