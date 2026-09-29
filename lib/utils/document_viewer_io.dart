import 'dart:io';

/// Opens [url] with the OS default handler (Windows desktop implementation).
Future<void> openExternalUrl(String url) async {
  try {
    await Process.run(
      'rundll32',
      ['url.dll,FileProtocolHandler', url],
      runInShell: false,
    );
  } catch (_) {
    // No handler available; ignore.
  }
}
