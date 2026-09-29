import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Cross-platform picked file (web uses bytes, native also keeps a path).
class PickedFileData {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  final int size;
  final String? nativePath;

  PickedFileData({
    required this.name,
    required this.bytes,
    required this.mimeType,
    required this.size,
    this.nativePath,
  });

  static const List<String> imageExts = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  ];

  bool get isImage =>
      mimeType.startsWith('image/') || imageExts.contains(extension);

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot).toLowerCase();
  }

  String get safeStorageName => sanitizeFileName(name);

  ImageProvider? get previewProvider {
    if (!isImage || bytes.isEmpty) return null;
    return MemoryImage(bytes);
  }

  static String sanitizeFileName(String raw) {
    var base = raw.trim();
    final slash = base.lastIndexOf('/');
    if (slash >= 0) base = base.substring(slash + 1);
    final back = base.lastIndexOf('\\');
    if (back >= 0) base = base.substring(back + 1);
    base = base.trim();
    if (base.isEmpty) return 'file_${DateTime.now().millisecondsSinceEpoch}';
    final cleaned = base.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (cleaned.isEmpty) return 'file_${DateTime.now().millisecondsSinceEpoch}';
    return cleaned;
  }

  static String mimeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.csv')) return 'text/csv';
    return 'application/octet-stream';
  }
}

// Cross-platform picking for web, Android, iOS and desktop.
class PlatformImagePicker {
  static const List<String> allowedDocExts = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
  ];
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int maxFileBytes = 10 * 1024 * 1024;

  static bool isSupportedImage({required String mime, required String name}) {
    if (mime.startsWith('image/')) return true;
    final ext = name.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp');
  }

  static String describeSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static List<String> get allowedDocumentExtensions => allowedDocExts;
  static int get maxFileSizeBytes => maxFileBytes;
  static int get maxImageSizeBytes => maxImageBytes;

  static String mimeTypeForExtension(String ext) => mimeForExt(ext);

  static String mimeTypeForFileName(String name) =>
      PickedFileData.mimeForName(name);

  static String sanitizeFileName(String raw) =>
      PickedFileData.sanitizeFileName(raw);

  static String mimeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<PickedFileData?> pickFileData({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    int? maxSizeBytes,
    String? dialogTitle,
  }) async {
    // file_picker 12.x exposes a static pickFiles() API that returns the
    // files directly. withData is required so web picks carry bytes.
    final result = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
    );
    if (result.isEmpty) return null;
    final pf = result.single;
    Uint8List bytes;
    try {
      // file_picker 12.x PlatformFile has no bytes getter; readAsBytes()
      // works on all platforms (web implementation buffers the picked blob).
      bytes = await pf.readAsBytes();
    } catch (e) {
      debugPrint('PlatformImagePicker: cannot read bytes: $e');
      return null;
    }
    if (bytes.isEmpty) {
      debugPrint('PlatformImagePicker: picked file has no readable bytes.');
      return null;
    }
    final size = bytes.length;
    if (maxSizeBytes != null && size > maxSizeBytes) {
      throw PickedFileTooLargeException(
        'Selected file is ${describeSize(size)}. '
        'Maximum allowed size is ${describeSize(maxSizeBytes)}.',
      );
    }
    final name = pf.name.isEmpty
        ? 'file_${DateTime.now().millisecondsSinceEpoch}'
        : pf.name;
    final ext = pf.extension;
    final mime = (ext != null && ext.isNotEmpty)
        ? mimeForExt(ext)
        : PickedFileData.mimeForName(name);
    final path = pf.path;
    if (path != null && !kIsWeb) {
      debugPrint('PlatformImagePicker: native path available, using bytes.');
    }
    return PickedFileData(
      name: name,
      bytes: bytes,
      mimeType: mime,
      size: size,
      nativePath: (!kIsWeb) ? pf.path : null,
    );
  }

  static Future<PickedFileData?> pickImageData() {
    return pickFileData(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      maxSizeBytes: maxImageBytes,
    );
  }
}

class PickedFileTooLargeException implements Exception {
  final String message;
  PickedFileTooLargeException(this.message);
  @override
  String toString() => message;
}
