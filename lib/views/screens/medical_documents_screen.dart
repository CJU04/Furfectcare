import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/models/medical_document.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/services/medical_document_service.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/medical_history_provider.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';
import 'package:vetcare_connect/views/widgets/app_dialog.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/utils/document_viewer.dart';

class MedicalDocumentsScreen extends StatefulWidget {
  const MedicalDocumentsScreen({super.key});

  @override
  State<MedicalDocumentsScreen> createState() => _MedicalDocumentsScreenState();
}

class _MedicalDocumentsScreenState extends State<MedicalDocumentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPetId;
  String _selectedDocumentType = 'vaccine_certificate';
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<PetProvider>(context, listen: false).loadPets();
      Provider.of<AppointmentProvider>(context, listen: false)
          .loadAppointments();
      Provider.of<MedicalHistoryProvider>(context, listen: false)
          .loadMedicalHistories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final petProvider = Provider.of<PetProvider>(context);
    // Subscribed without capturing the value so this screen rebuilds when
    // appointments or medical histories change (the filter is pet-based).
    Provider.of<AppointmentProvider>(context);
    Provider.of<MedicalHistoryProvider>(context);
    final uid = authProvider.firebaseUser?.uid;
    final isCustomer = authProvider.role?.value == 'customer';

    List<Pet> availablePets = petProvider.pets;

    if (isCustomer && uid != null) {
      availablePets =
          availablePets.where((pet) => pet.ownerUid == uid).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Documents'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _isUploading ? null : _pickAndUploadDocument,
            tooltip: 'Upload Document',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/medical_documents'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth =
              constraints.maxWidth > 900 ? 900 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedPetId,
                            decoration: const InputDecoration(
                              labelText: 'Filter by Pet',
                              prefixIcon: Icon(Icons.pets),
                              border: OutlineInputBorder(),
                            ),
                            items: availablePets.map((pet) {
                              return DropdownMenuItem<String>(
                                value: pet.petId,
                                child: Text('${pet.name} (${pet.type})',
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedPetId = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedDocumentType,
                            decoration: const InputDecoration(
                              labelText: 'Document Type',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            items: MedicalDocument.allowedDocumentTypes
                                .map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                    MedicalDocument.getDocumentTypeLabel(type),
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() =>
                                _selectedDocumentType =
                                    value ?? 'vaccine_certificate'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Documents',
                        hintText: 'File name, type, notes, or pet name',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: 16),
                    if (_isUploading)
                      Column(
                        children: [
                          LinearProgressIndicator(value: _uploadProgress),
                          const SizedBox(height: 8),
                          Text(_uploadProgress >= 1
                              ? 'File transferred. Saving document details…'
                              : 'Uploading… ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _buildQuery(uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                    'Could not load documents: ${snapshot.error}'),
                              ),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          final documents = <MedicalDocument>[];
                          for (final doc in docs) {
                            try {
                              documents.add(MedicalDocument.fromMap({
                                ...doc.data() as Map<String, dynamic>,
                                'documentId': doc.id,
                              }));
                            } catch (_) {
                              // Skip malformed/legacy documents instead of crashing the list.
                            }
                          }
                          // Client-side filters (avoids composite-index failures).
                          String petName(String petId) {
                            for (final p in petProvider.pets) {
                              if (p.petId == petId) return p.name;
                            }
                            return '';
                          }

                          final q = _searchQuery.trim().toLowerCase();
                          final filtered = documents.where((d) {
                            if (d.documentType != _selectedDocumentType)
                              return false;
                            if (uid != null &&
                                d.ownerUid.isNotEmpty &&
                                d.ownerUid != uid) return false;
                            if (q.isNotEmpty) {
                              final matches = d.fileName
                                      .toLowerCase()
                                      .contains(q) ||
                                  MedicalDocument.getDocumentTypeLabel(
                                          d.documentType)
                                      .toLowerCase()
                                      .contains(q) ||
                                  (d.notes ?? '').toLowerCase().contains(q) ||
                                  petName(d.petId).toLowerCase().contains(q);
                              if (!matches) return false;
                            }
                            return true;
                          }).toList();
                          final sorted = _sortDocuments(filtered);
                          if (sorted.isEmpty) {
                            return const Center(
                                child: Text('No medical documents found.'));
                          }
                          return ListView.builder(
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              return _buildDocumentTile(context, sorted[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadDocument,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery(String? uid) {
    // Single-field filters only: compound where() clauses require composite
    // indexes in Firestore and fail with FAILED_PRECONDITION. Filter by pet
    // here and apply documentType/ownerUid client-side in the builder.
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('medical_documents');

    if (_selectedPetId != null) {
      query = query.where('petId', isEqualTo: _selectedPetId);
    }

    return query.snapshots();
  }

  List<MedicalDocument> _sortDocuments(List<MedicalDocument> docs) {
    docs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return docs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDocumentTile(BuildContext context, MedicalDocument doc) {
    final isExpired = doc.isExpired;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              doc.isImage ? Colors.blue.shade50 : Colors.red.shade50,
          child: Icon(
            doc.isImage ? Icons.image : Icons.picture_as_pdf,
            color: doc.isImage ? Colors.blue : Colors.red,
          ),
        ),
        title: Text(
          MedicalDocument.getDocumentTypeLabel(doc.documentType),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.fileName),
            Text('${doc.formattedFileSize} • ${_formatDate(doc.uploadedAt)}'),
            if (isExpired)
              Text(
                'EXPIRED',
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            if (doc.isVerified)
              Row(
                children: [
                  Icon(Icons.verified, size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text('Verified',
                      style: TextStyle(
                          fontSize: 12, color: Colors.green.shade700)),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _viewDocument(context, doc),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteDocument(context, doc),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadDocument() async {
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);
    final medicalHistoryProvider =
        Provider.of<MedicalHistoryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.firebaseUser?.uid;

    if (_selectedPetId == null || uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a pet first'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    PickedFileData? picked;
    try {
      picked = await PlatformImagePicker.pickFileData(
        type: FileType.custom,
        allowedExtensions: PlatformImagePicker.allowedDocumentExtensions,
        maxSizeBytes: PlatformImagePicker.maxFileSizeBytes,
      );
    } on PickedFileTooLargeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
        );
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not select a file. Please try again.'),
              backgroundColor: Colors.orange),
        );
      }
      return;
    }
    if (picked == null) return;

    // Link to the same pet's appointment/history when one exists, otherwise
    // leave the link empty (never 'none') so detail screens can still find it.
    String linkedAppointmentId = '';
    String linkedHistoryId = '';
    try {
      final petAppointments = appointmentProvider.appointments
          .where((a) => a.petId == _selectedPetId)
          .toList();
      if (petAppointments.isNotEmpty) {
        linkedAppointmentId = petAppointments.first.appointmentId ?? '';
      }
    } catch (_) {}
    try {
      final petHistories = medicalHistoryProvider.medicalHistories
          .where((h) => h.petId == _selectedPetId)
          .toList();
      if (petHistories.isNotEmpty) {
        linkedHistoryId = petHistories.first.historyId ?? '';
      }
    } catch (_) {}

    final document = MedicalDocument(
      petId: _selectedPetId!,
      appointmentId: linkedAppointmentId,
      historyId: linkedHistoryId,
      ownerUid: uid,
      documentType: _selectedDocumentType,
      fileName: picked.safeStorageName,
      fileUrl: '',
      fileSizeBytes: picked.size,
      mimeType: picked.mimeType,
      uploadedBy: uid,
    );

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      await MedicalDocumentService().uploadDocumentData(
        data: picked,
        document: document,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Document uploaded successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _viewDocument(BuildContext context, MedicalDocument doc) async {
    if (doc.fileUrl.isEmpty) return;

    if (doc.isImage) {
      // Full-screen viewer with zoom; CachedNetworkImage gives proper
      // loading/error states (unlike the previous Image.network which
      // failed silently without errorWidget support).
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(doc.fileName)),
            body: Center(
              child: InteractiveViewer(
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: doc.fileUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // PDFs and other files open outside the app (new tab on web,
      // OS default handler on desktop).
      await openExternalUrl(doc.fileUrl);
    }
  }

  Future<void> _deleteDocument(
      BuildContext context, MedicalDocument doc) async {
    final confirm = await AppDialog.confirm(
      context,
      title: 'Delete Document',
      message:
          'Are you sure you want to delete "${doc.fileName}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('medical_documents')
          .doc(doc.documentId)
          .delete();
      try {
        await FirebaseStorage.instance.refFromURL(doc.fileUrl).delete();
      } catch (e) {
        debugPrint('Storage delete failed: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Document deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Delete failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
