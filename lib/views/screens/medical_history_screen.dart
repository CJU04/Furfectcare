import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/views/widgets/medical_history_form_dialog.dart';
import 'package:vetcare_connect/services/medical_document_service.dart';

import 'package:vetcare_connect/models/medical_history.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/models/medical_document.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/medical_history_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/algorithms/fuzzy_logic.dart';
import 'package:vetcare_connect/algorithms/ui/fuzzy_assessment.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Newest first';

  static const _sortOptions = <String>[
    'Newest first',
    'Oldest first',
    'Pet name (A-Z)',
    'Diagnosis (A-Z)',
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<MedicalHistoryProvider>(context, listen: false)
        .loadMedicalHistories();
  }

  @override
  Widget build(BuildContext context) {
    final medicalHistoryProvider = Provider.of<MedicalHistoryProvider>(context);
    final petProvider = Provider.of<PetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final uid = authProvider.firebaseUser?.uid;
    final isCustomer = role?.value == 'customer';

    List<MedicalHistory> medicalHistories =
        medicalHistoryProvider.medicalHistories;

    if (isCustomer && uid != null) {
      final customerPetIds = petProvider.pets
          .where((pet) => pet.ownerUid == uid)
          .map((pet) => pet.petId)
          .toList();
      medicalHistories = medicalHistories
          .where((history) => customerPetIds.contains(history.petId))
          .toList();
    }

    String petName(String petId) {
      for (final p in petProvider.pets) {
        if (p.petId == petId) return p.name;
      }
      return '';
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      medicalHistories = medicalHistories
          .where((history) =>
              history.diagnosis.toLowerCase().contains(q) ||
              history.treatment.toLowerCase().contains(q) ||
              history.notes.toLowerCase().contains(q) ||
              history.date.toLowerCase().contains(q) ||
              petName(history.petId).toLowerCase().contains(q))
          .toList();
    }

    // Copy before sorting so the provider's internal list is never mutated.
    medicalHistories = List<MedicalHistory>.from(medicalHistories);
    switch (_sortBy) {
      case 'Oldest first':
        medicalHistories.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
        break;
      case 'Pet name (A-Z)':
        medicalHistories.sort((a, b) => petName(a.petId)
            .toLowerCase()
            .compareTo(petName(b.petId).toLowerCase()));
        break;
      case 'Diagnosis (A-Z)':
        medicalHistories.sort((a, b) =>
            a.diagnosis.toLowerCase().compareTo(b.diagnosis.toLowerCase()));
        break;
      default:
        medicalHistories.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
      ),
      drawer: const AppDrawer(currentRoute: '/medical_history'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600 ? 800 : double.infinity;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Medical History',
                            hintText:
                                'Diagnosis, treatment, notes, date or pet name',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _sortBy,
                        underline: const SizedBox.shrink(),
                        items: _sortOptions
                            .map((o) =>
                                DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: medicalHistories.isEmpty
                    ? const Center(
                        child: Text('No medical history found'),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth > 600
                                ? (constraints.maxWidth - 800) / 2
                                : 0),
                        itemCount: medicalHistories.length,
                        itemBuilder: (context, index) {
                          final history = medicalHistories[index];
                          return _buildMedicalHistoryTile(context, history);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isCustomer
          ? null
          : FloatingActionButton(
              onPressed: _addMedicalHistory,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildMedicalHistoryTile(
      BuildContext context, MedicalHistory history) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCustomer = authProvider.role?.value == 'customer';
    final canAssess = !isCustomer;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.medical_services),
        title: Text(history.diagnosis),
        onTap: () => _showMedicalHistoryDetails(context, history),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${history.date} - ${history.treatment}'),
            if (history.fuzzyUrgencyScore != null) ...[
              const SizedBox(height: 4),
              Text(
                'Fuzzy Urgency: ${history.fuzzyUrgencyScore!.toStringAsFixed(1)}/100 (${history.fuzzyConcernLevel ?? "Unknown"})',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        trailing: isCustomer
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canAssess)
                    IconButton(
                      icon: const Icon(Icons.analytics_rounded,
                          color: Colors.purple),
                      tooltip: 'Run Fuzzy Assessment',
                      onPressed: () => _runFuzzyAssessment(context, history),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editMedicalHistory(history),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteMedicalHistory(history),
                  ),
                ],
              ),
      ),
    );
  }

  /// Shows the full details of a single medical history entry in a
  /// read-only dialog. Tapping a record card opens this.
  void _showMedicalHistoryDetails(
      BuildContext context, MedicalHistory history) {
    final primary = Theme.of(context).colorScheme.primary;
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);

    Pet? pet;
    for (final p in petProvider.pets) {
      if (p.petId == history.petId) {
        pet = p;
        break;
      }
    }

    Appointment? appointment;
    for (final a in appointmentProvider.appointments) {
      if (a.appointmentId == history.appointmentId) {
        appointment = a;
        break;
      }
    }

    List<MedicalDocument> documents = const <MedicalDocument>[];
    bool documentsLoaded = history.historyId == null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (!documentsLoaded) {
              documentsLoaded = true;
              MedicalDocumentService()
                  .getDocumentsForHistory(history.historyId!)
                  .then((docs) {
                if (dialogContext.mounted) {
                  setDialogState(() => documents = docs);
                }
              }).catchError((Object error) {
                if (dialogContext.mounted) {
                  setDialogState(() => documents = const <MedicalDocument>[]);
                }
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.medical_services, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      history.diagnosis.isEmpty
                          ? 'Medical Record'
                          : history.diagnosis,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHistoryDetailTile(
                      Icons.pets,
                      'Pet',
                      pet == null
                          ? 'Unknown pet'
                          : '${pet.name} (${pet.type}'
                              '${pet.breed.isNotEmpty ? ' - ${pet.breed}' : ''}'
                              '${pet.age > 0 ? ' - ${pet.age}y' : ''})',
                    ),
                    _buildHistoryDetailTile(
                      Icons.calendar_today,
                      'Date',
                      history.date.isEmpty ? 'Not set' : history.date,
                    ),
                    _buildHistoryDetailTile(
                      Icons.healing,
                      'Treatment',
                      history.treatment.isEmpty
                          ? 'Not recorded'
                          : history.treatment,
                    ),
                    _buildHistoryDetailTile(
                      Icons.notes,
                      'Notes',
                      history.notes.isEmpty ? 'No notes' : history.notes,
                    ),
                    _buildHistoryDetailTile(
                      Icons.event_note,
                      'Related Appointment',
                      appointment == null
                          ? 'None linked'
                          : '${appointment.reason}'
                              '\n${appointment.date} ${appointment.time}'
                              ' (${appointment.status})',
                    ),
                    const Divider(height: 24),
                    _buildHistorySectionLabel(primary, Icons.analytics_rounded,
                        'Fuzzy Urgency Assessment'),
                    if (history.fuzzyUrgencyScore == null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No fuzzy assessment has been run for this record.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    else ...[
                      _buildHistoryDetailTile(
                        Icons.speed,
                        'Urgency Score',
                        '${history.fuzzyUrgencyScore!.toStringAsFixed(1)}/100',
                      ),
                      _buildHistoryDetailTile(
                        Icons.warning_amber_rounded,
                        'Concern Level',
                        history.fuzzyConcernLevel ?? 'Unknown',
                      ),
                      if (history.fuzzyAssessmentDate != null)
                        _buildHistoryDetailTile(
                          Icons.today,
                          'Assessed On',
                          history.fuzzyAssessmentDate!,
                        ),
                      if (history.fuzzyAssessmentNotes != null &&
                          history.fuzzyAssessmentNotes!.isNotEmpty)
                        _buildHistoryDetailTile(
                          Icons.recommend,
                          'Recommendation',
                          history.fuzzyAssessmentNotes!,
                        ),
                    ],
                    const Divider(height: 24),
                    _buildHistorySectionLabel(primary, Icons.attach_file,
                        'Documents (${documents.length})'),
                    if (documents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No documents attached to this record.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    else
                      ...documents.map(
                        (document) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              document.isImage
                                  ? Icons.image_outlined
                                  : (document.isPdf
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.insert_drive_file_outlined),
                              color: primary,
                            ),
                            title: Text(document.fileName),
                            subtitle: Text(
                              '${MedicalDocument.getDocumentTypeLabel(document.documentType)}'
                              ' - ${document.formattedFileSize}'
                              '${document.isVerified ? ' - Verified' : ''}',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _runFuzzyAssessment(
      BuildContext context, MedicalHistory history) async {
    final messenger = ScaffoldMessenger.of(context);
    final historyProvider =
        Provider.of<MedicalHistoryProvider>(context, listen: false);
    final result = await Navigator.push<FuzzyResult>(
      context,
      MaterialPageRoute(builder: (_) => const FuzzyAssessmentScreen()),
    );

    if (result == null) return;

    final updatedHistory = history.copyWith(
      fuzzyUrgencyScore: result.crispOutput,
      fuzzyConcernLevel: result.concernLevel,
      fuzzyAssessmentDate: DateTime.now().toIso8601String().split('T')[0],
      fuzzyAssessmentNotes: result.recommendation,
    );

    try {
      await historyProvider.updateMedicalHistory(updatedHistory);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Fuzzy assessment saved: ${result.concernLevel} (${result.crispOutput.toStringAsFixed(1)})'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Failed to save fuzzy assessment'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _addMedicalHistory() => _showMedicalHistoryForm();

  void _editMedicalHistory(MedicalHistory history) =>
      _showMedicalHistoryForm(history: history);

  Future<void> _showMedicalHistoryForm({MedicalHistory? history}) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.firebaseUser?.uid;
    final messenger = ScaffoldMessenger.of(context);
    if (uid == null) {
      messenger
          .showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }
    final customer = auth.role?.value == 'customer';
    final pets = context
        .read<PetProvider>()
        .pets
        .where((p) => !customer || p.ownerUid == uid)
        .toList();
    final appointments = context
        .read<AppointmentProvider>()
        .appointments
        .where((a) => !customer || a.ownerUid == uid)
        .toList();
    final provider = context.read<MedicalHistoryProvider>();
    // Retain this ID after a partial save so an upload retry updates the record.
    String? savedId = history?.historyId;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MedicalHistoryFormDialog(
        pets: pets,
        appointments: appointments,
        history: history,
        onSave: (record, attachment) async {
          try {
            if (savedId == null) {
              savedId = await provider.addMedicalHistory(record);
            } else {
              await provider
                  .updateMedicalHistory(record.copyWith(historyId: savedId));
            }
          } catch (_) {
            throw Exception(
                'Could not save the record. Check your connection and access, then retry.');
          }
          if (attachment != null) {
            try {
              final pet = pets.firstWhere((p) => p.petId == record.petId);
              await MedicalDocumentService().uploadDocumentData(
                data: attachment,
                document: MedicalDocument(
                  petId: record.petId,
                  appointmentId: record.appointmentId,
                  historyId: savedId!,
                  ownerUid: pet.ownerUid,
                  documentType: 'medical_record',
                  fileName: attachment.name,
                  fileUrl: '',
                  fileSizeBytes: attachment.size,
                  mimeType: attachment.mimeType,
                  uploadedBy: uid,
                ),
              );
            } catch (_) {
              throw Exception(
                  'Record saved, but the attachment failed. Retry Save to upload it, or remove the selected file to continue without it.');
            }
          }
        },
      ),
    );
    if (!mounted || saved != true) return;
    messenger.showSnackBar(const SnackBar(
      content: Text('Medical history saved successfully.'),
      backgroundColor: Colors.green,
    ));
  }

  void _deleteMedicalHistory(MedicalHistory history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medical History'),
        content: Text('Are you sure you want to delete ${history.diagnosis}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Deleting medical history...'),
                    duration: Duration(seconds: 1)),
              );
              try {
                await Provider.of<MedicalHistoryProvider>(context,
                        listen: false)
                    .deleteMedicalHistory(history.historyId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Medical history deleted successfully'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to delete medical history'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Small section heading used inside the medical history details dialog.
  Widget _buildHistorySectionLabel(Color color, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// One labeled row inside the medical history details dialog.
  Widget _buildHistoryDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
