import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Native implementation: writes the CSV into the app documents directory
/// (always writable) and reports success. Using FilePicker.saveFile was
/// returning null/crashing on some platforms which made Reports look broken.
Future<bool> saveTextFileImpl({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  try {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(content));
    final dir = await getApplicationDocumentsDirectory();
    final safeName = fileName.isEmpty
        ? 'report_${DateTime.now().millisecondsSinceEpoch}.csv'
        : fileName;
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    debugPrint('Exporter: saved report to ${file.path}');
    return true;
  } catch (e) {
    debugPrint('Exporter: native save failed: $e');
    return false;
  }
}
