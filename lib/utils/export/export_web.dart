// The web export implementation uses dart:html directly. It is only ever
// reachable on Flutter Web through the conditional import in
// report_exporter.dart, which is the sanctioned escape hatch until the
// project migrates to package:web.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web implementation: triggers a browser download of the generated file.
Future<bool> saveTextFileImpl({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  try {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(content));
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (e) {
    html.window.console.error('Export failed: $e');
    return false;
  }
}
