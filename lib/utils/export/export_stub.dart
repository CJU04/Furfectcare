import 'dart:async';

/// Fallback used only when neither html nor io library is available.
Future<bool> saveTextFileImpl({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  throw UnsupportedError('Saving files is not supported on this platform.');
}
