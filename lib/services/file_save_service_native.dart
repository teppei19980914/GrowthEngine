/// ネイティブ環境でのファイル保存/読込.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// ファイルを保存する（Native版）.
///
/// file_pickerで保存先ダイアログを表示し、dart:io で明示的に書き込む.
Future<bool> saveFile({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/octet-stream',
  List<String> allowedExtensions = const ['xlsx'],
}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'ファイルの保存先を選択',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
  );
  if (path == null) return false;
  await File(path).writeAsBytes(bytes, flush: true);
  return true;
}

/// ファイルを読み込む（Native版）.
Future<Uint8List?> pickFile({
  required List<String> allowedExtensions,
}) async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: 'ファイルを選択',
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  return result.files.first.bytes;
}
