import 'export_stub.dart'
    if (dart.library.html) 'export_web.dart'
    if (dart.library.io) 'export_io.dart';

/// Saves [content] to the user's device as [fileName].
///
/// - Web: triggers a browser download of the file.
/// - Desktop/mobile: opens a save dialog (falls back to the documents
///   directory when the dialog is cancelled without a choice).
/// Returns true when the file was actually saved so callers can show
/// accurate success/failure feedback.
Future<bool> saveTextFile({
  required String fileName,
  required String content,
  String mimeType = 'text/csv',
}) {
  return saveTextFileImpl(
    fileName: fileName,
    content: content,
    mimeType: mimeType,
  );
}

/// Builds a RFC-4180 compatible CSV document from [rows]
/// (first row is expected to be the header).
String buildCsv(List<List<String>> rows) {
  final buffer = StringBuffer();
  for (final row in rows) {
    buffer.write(row.map(_csvField).join(','));
    buffer.writeln();
  }
  return buffer.toString();
}

String _csvField(Object? value) {
  final text = value?.toString() ?? '';
  final needsQuotes =
      text.contains(',') || text.contains('"') || text.contains('\n');
  final escaped = text.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}
