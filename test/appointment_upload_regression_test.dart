import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetcare_connect/utils/appointment_scheduling.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';

void main() {
  test('Legacy appointment statuses display Scheduled without changing storage',
      () {
    expect(AppointmentStatus.label('confirmed'), 'Scheduled');
    expect(AppointmentStatus.label('scheduled'), 'Scheduled');
    expect(AppointmentStatus.normalize('confirmed'), 'confirmed');
    expect(AppointmentStatus.isActive('confirmed'), isTrue);
    expect(AppointmentStatus.isActive('scheduled'), isTrue);
    expect(AppointmentStatus.isActive('cancelled'), isFalse);
  });

  test('Requested document formats retain their MIME type', () {
    final formats = {
      'record.pdf': 'application/pdf',
      'record.docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'photo.png': 'image/png',
      'photo.jpg': 'image/jpeg',
    };
    for (final entry in formats.entries) {
      expect(PickedFileData.mimeForName(entry.key), entry.value);
      expect(PlatformImagePicker.allowedDocumentExtensions,
          contains(entry.key.split('.').last));
    }
  });

  test('Browser image preview uses bytes without a native file path', () {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final image = PickedFileData(
      name: 'avatar.png',
      bytes: bytes,
      mimeType: 'image/png',
      size: 3,
    );
    expect(image.nativePath, isNull);
    expect(image.previewProvider, isA<MemoryImage>());
    expect((image.previewProvider! as MemoryImage).bytes, bytes);
  });
}
