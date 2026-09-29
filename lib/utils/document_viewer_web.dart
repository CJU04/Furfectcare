import 'dart:html' as html;

/// Opens [url] in a new browser tab (web implementation).
Future<void> openExternalUrl(String url) async {
  html.window.open(url, '_blank');
}
