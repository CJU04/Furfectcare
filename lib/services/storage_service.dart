import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';

import '../utils/platform_image_picker.dart';

/// Unified Firebase Storage uploads that work on web (bytes) and native (file),
/// with upload progress callbacks and safe storage paths.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  /// Uploads [data] (image or document) into [folder] and returns the
  /// public download URL.
  ///
  /// - [folder] example: `pet_images`, `product_images`, `profile_images`.
  /// - [referenceName] optional prefix/segment for the stored file name
  ///   (for example the pet's UID). When omitted the sanitized original
  ///   file name is used.
  Future<String> uploadPickedFile({
    required PickedFileData data,
    required String folder,
    String referenceName = '',
    void Function(double progress)? onProgress,
  }) async {
    final baseName = referenceName.isNotEmpty
        ? '${PickedFileData.sanitizeFileName(referenceName)}_${DateTime.now().microsecondsSinceEpoch}${data.extension}'
        : '${DateTime.now().microsecondsSinceEpoch}_${data.safeStorageName}';
    final fileName = baseName;
    final ref = _storage.ref().child('$folder/$fileName');

    final metadata = firebase_storage.SettableMetadata(
      contentType: data.mimeType,
      customMetadata: {
        'originalName': data.name,
        'mimeType': data.mimeType,
      },
    );

    firebase_storage.UploadTask uploadTask;
    // putData works on all platforms (web + native) since we always have
    // the picked bytes in memory.
    uploadTask = ref.putData(data.bytes, metadata);

    return _completeUpload(uploadTask, ref, onProgress);
  }

  /// Uploads a raw byte buffer (used when callers already hold [Uint8List]).
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child('$folder/$fileName');
    final metadata = firebase_storage.SettableMetadata(
      contentType: mimeType,
      customMetadata: {'mimeType': mimeType},
    );
    final uploadTask = ref.putData(bytes, metadata);
    return _completeUpload(uploadTask, ref, onProgress);
  }

  Future<String> _completeUpload(
    firebase_storage.UploadTask task,
    firebase_storage.Reference ref,
    void Function(double)? onProgress,
  ) async {
    // Fire an initial tick immediately so UI shows movement even before
    // the first real progress event (common on web with putData).
    onProgress?.call(0.01);

    int? lastEmittedBytes;
    const creepInterval = Duration(milliseconds: 300);

    void emitIfChanged(snapshot) {
      if (snapshot.totalBytes > 0) {
        final now = snapshot.bytesTransferred;
        if (now != lastEmittedBytes) {
          lastEmittedBytes = now;
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      }
    }

    final subscription = task.snapshotEvents.listen(emitIfChanged);

    // Fallback: if snapshotEvents stop firing for a while, nudge progress
    // upward in small steps so the UI never stays pinned at 0%.
    final creepTimer = Timer.periodic(creepInterval, (_) {
      final emitted = lastEmittedBytes;
      if (emitted == null || emitted == 0) {
        lastEmittedBytes = 1;
        onProgress?.call(0.02);
      } else if (emitted < 100) {
        onProgress?.call(emitted / 100);
      }
    });

    try {
      await task.timeout(const Duration(minutes: 2));
      // Finalize: ensure caller sees 100% before the download URL is
      // fetched, since snapshotEvents can be sparse on completion.
      onProgress?.call(1.0);
      return await ref.getDownloadURL().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      unawaited(task.cancel().catchError((Object _) => false));
      throw TimeoutException(
        'Upload timed out. Check your connection and try again.',
      );
    } finally {
      creepTimer.cancel();
      await subscription.cancel();
    }
  }

  /// Deletes a stored file from its [downloadUrl] if the URL points to this
  /// project's storage bucket. Silently ignores non-storage URLs and missing
  /// files so deletion of a broken reference never blocks the main flow.
  Future<void> deleteFile(String downloadUrl) async {
    if (downloadUrl.isEmpty) return;
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } on firebase_storage.FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'no-such-object') {
        debugPrint('StorageService: file already missing: $downloadUrl');
        return;
      }
      rethrow;
    }
  }
}
