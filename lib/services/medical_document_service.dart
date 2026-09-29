import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vetcare_connect/models/medical_document.dart';
import 'package:vetcare_connect/services/storage_service.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';

class MedicalDocumentService {
  static const String _collection = 'medical_documents';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cross-platform upload (web and native) using picked bytes.
  Future<String> uploadDocumentData({
    required PickedFileData data,
    required MedicalDocument document,
    Function(double)? onProgress,
  }) async {
    try {
      final downloadUrl = await StorageService.instance.uploadPickedFile(
        data: data,
        folder: 'medical_documents',
        referenceName: '${document.petId}_${document.documentType}',
        onProgress: onProgress,
      );

      final docData = document
          .copyWith(fileUrl: downloadUrl, fileName: data.safeStorageName)
          .toMap();
      docData.remove('documentId');

      final docRef = await _firestore.collection(_collection).add(docData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<List<MedicalDocument>> getDocumentsForPet(String petId) async {
    try {
      // No orderBy: avoids requiring a composite index and avoids mixing
      // Timestamp/String uploadedAt values in old documents. Sort in memory.
      final snapshot = await _firestore
          .collection(_collection)
          .where('petId', isEqualTo: petId)
          .get();

      final docs = snapshot.docs
          .map((doc) {
            try {
              return MedicalDocument.fromMap({
                ...doc.data(),
                'documentId': doc.id,
              });
            } catch (_) {
              return null;
            }
          })
          .whereType<MedicalDocument>()
          .toList();
      docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return docs;
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  Future<List<MedicalDocument>> getDocumentsForAppointment(
      String appointmentId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('appointmentId', isEqualTo: appointmentId)
          .get();

      final docs = snapshot.docs
          .map((doc) {
            try {
              return MedicalDocument.fromMap({
                ...doc.data(),
                'documentId': doc.id,
              });
            } catch (_) {
              return null;
            }
          })
          .whereType<MedicalDocument>()
          .toList();
      docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return docs;
    } catch (e) {
      throw Exception('Failed to fetch appointment documents: $e');
    }
  }

  Future<List<MedicalDocument>> getDocumentsForHistory(String historyId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('historyId', isEqualTo: historyId)
          .get();

      final docs = snapshot.docs
          .map((doc) {
            try {
              return MedicalDocument.fromMap({
                ...doc.data(),
                'documentId': doc.id,
              });
            } catch (_) {
              return null;
            }
          })
          .whereType<MedicalDocument>()
          .toList();
      docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return docs;
    } catch (e) {
      throw Exception('Failed to fetch medical history documents: $e');
    }
  }

  Future<void> verifyDocument(String documentId, String verifiedBy) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'isVerified': true,
        'verifiedBy': verifiedBy,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to verify document: $e');
    }
  }

  Future<void> deleteDocument(String documentId, String fileUrl) async {
    try {
      await _firestore.collection(_collection).doc(documentId).delete();

      try {
        await StorageService.instance.deleteFile(fileUrl);
      } catch (e) {
        debugPrint('Failed to delete file from storage: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
}
