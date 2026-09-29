import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalDocument {
  String? documentId;
  String petId;
  String appointmentId;
  String historyId;
  String ownerUid;
  String documentType;
  String fileName;
  String fileUrl;
  String? thumbnailUrl;
  int fileSizeBytes;
  String mimeType;
  String? uploadedBy;
  DateTime uploadedAt;
  DateTime? expiryDate;
  String? notes;
  bool isVerified;
  String? verifiedBy;
  DateTime? verifiedAt;

  MedicalDocument({
    this.documentId,
    required this.petId,
    required this.appointmentId,
    required this.historyId,
    required this.ownerUid,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.fileSizeBytes,
    required this.mimeType,
    this.uploadedBy,
    DateTime? uploadedAt,
    this.expiryDate,
    this.notes,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'petId': petId,
      'appointmentId': appointmentId,
      'historyId': historyId,
      'ownerUid': ownerUid,
      'documentType': documentType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'expiryDate': expiryDate == null ? null : Timestamp.fromDate(expiryDate!),
      'notes': notes,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt == null ? null : Timestamp.fromDate(verifiedAt!),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory MedicalDocument.fromMap(Map<String, dynamic> map) {
    return MedicalDocument(
      documentId: map['documentId'] as String?,
      petId: map['petId'] as String? ?? '',
      appointmentId: map['appointmentId'] as String? ?? '',
      historyId: map['historyId'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      documentType: map['documentType'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String?,
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      mimeType: map['mimeType'] as String? ?? '',
      uploadedBy: map['uploadedBy'] as String?,
      uploadedAt: _parseDate(map['uploadedAt']),
      expiryDate: _parseNullableDate(map['expiryDate']),
      notes: map['notes'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: _parseNullableDate(map['verifiedAt']),
    );
  }

  MedicalDocument copyWith({
    String? documentId,
    String? petId,
    String? appointmentId,
    String? historyId,
    String? ownerUid,
    String? documentType,
    String? fileName,
    String? fileUrl,
    String? thumbnailUrl,
    int? fileSizeBytes,
    String? mimeType,
    String? uploadedBy,
    DateTime? uploadedAt,
    DateTime? expiryDate,
    String? notes,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
  }) {
    return MedicalDocument(
      documentId: documentId ?? this.documentId,
      petId: petId ?? this.petId,
      appointmentId: appointmentId ?? this.appointmentId,
      historyId: historyId ?? this.historyId,
      ownerUid: ownerUid ?? this.ownerUid,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024)
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static List<String> get allowedDocumentTypes => [
        'vaccine_certificate',
        'lab_result',
        'radiology',
        'prescription',
        'surgery_report',
        'dental_record',
        'deworming_record',
        'fecal_exam',
        'blood_test',
        'urinalysis',
        'other',
      ];

  static String getDocumentTypeLabel(String type) {
    switch (type) {
      case 'vaccine_certificate':
        return 'Vaccine Certificate';
      case 'lab_result':
        return 'Lab Result';
      case 'radiology':
        return 'Radiology / X-Ray';
      case 'prescription':
        return 'Prescription';
      case 'surgery_report':
        return 'Surgery Report';
      case 'dental_record':
        return 'Dental Record';
      case 'deworming_record':
        return 'Deworming Record';
      case 'fecal_exam':
        return 'Fecal Exam';
      case 'blood_test':
        return 'Blood Test';
      case 'urinalysis':
        return 'Urinalysis';
      default:
        return 'Other Document';
    }
  }
}
