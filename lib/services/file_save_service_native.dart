/// ネイティブ環境でのファイル保存/読込.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// ファイルを保存する（Native版）.
///
/// file_pickerで保存先を選択して保存する.
Future<bool> saveFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  final result = await FilePicker.platform.saveFile(
    dialogTitle: 'ファイルの保存先を選択',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    bytes: bytes,
  );
  return result != null;
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
