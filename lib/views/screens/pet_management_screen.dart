import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

import 'package:vetcare_connect/models/medical_document.dart';
import 'package:vetcare_connect/services/medical_document_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/services/storage_service.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';

class PetManagementScreen extends StatefulWidget {
  const PetManagementScreen({super.key});

  @override
  State<PetManagementScreen> createState() => _PetManagementScreenState();
}

class _PetManagementScreenState extends State<PetManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Provider.of<PetProvider>(context, listen: false).loadPets();
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = Provider.of<PetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;

    List<Pet> pets = petProvider.pets;

    // Filter pets based on user role
    if (role?.value == 'customer') {
      final uid = authProvider.firebaseUser?.uid;
      if (uid != null) {
        pets = pets.where((pet) => pet.ownerUid == uid).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      pets = pets
          .where((pet) =>
              pet.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Management'),
      ),
      drawer: const AppDrawer(currentRoute: '/pet_management'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600 ? 800 : double.infinity;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Pets',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: pets.isEmpty
                    ? const Center(
                        child: Text('No pets found'),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth > 600
                                ? (constraints.maxWidth - 800) / 2
                                : 0),
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ExpansionTile(
                              leading: const Icon(Icons.pets),
                              title: InkWell(
                                  onTap: () => _showPetDetails(pet),
                                  child: Text(pet.name)),
                              subtitle: Text(
                                  '${pet.type} - ${pet.breed}, Age: ${pet.age}, ${pet.gender}'),
                              trailing: role?.value == 'customer'
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editPet(pet),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _deletePet(pet),
                                        ),
                                      ],
                                    ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Vaccination Status: ${pet.vaccinationStatus}'),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Health Notes: ${pet.healthNotes.isNotEmpty ? pet.healthNotes : 'No notes available'}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPet,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addPet() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.firebaseUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final ageController = TextEditingController();
    final healthController = TextEditingController();

    String selectedType = 'Dog';
    String selectedGender = 'Male';
    String selectedVaccination = 'Up to date';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Pet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                        DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                        DropdownMenuItem(value: 'Bird', child: Text('Bird')),
                        DropdownMenuItem(
                            value: 'Rabbit', child: Text('Rabbit')),
                        DropdownMenuItem(
                            value: 'Hamster', child: Text('Hamster')),
                        DropdownMenuItem(
                            value: 'Guinea Pig', child: Text('Guinea Pig')),
                        DropdownMenuItem(value: 'Fish', child: Text('Fish')),
                        DropdownMenuItem(
                            value: 'Reptile', child: Text('Reptile')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: breedController,
                      decoration: const InputDecoration(labelText: 'Breed'),
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value!;
                        });
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: selectedVaccination,
                      decoration: const InputDecoration(
                          labelText: 'Vaccination Status'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Up to date', child: Text('Up to date')),
                        DropdownMenuItem(
                            value: 'Needs booster',
                            child: Text('Needs booster')),
                        DropdownMenuItem(
                            value: 'Not vaccinated',
                            child: Text('Not vaccinated')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedVaccination = value!;
                        });
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: healthController,
                      decoration:
                          const InputDecoration(labelText: 'Health Notes'),
                      maxLines: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newPet = Pet(
                  petId: null,
                  ownerUid: uid,
                  name: nameController.text,
                  type: selectedType,
                  breed: breedController.text,
                  age: int.tryParse(ageController.text) ?? 0,
                  gender: selectedGender,
                  vaccinationStatus: selectedVaccination,
                  healthNotes: healthController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Adding pet...'),
                      duration: Duration(seconds: 1)),
                );
                try {
                  await Provider.of<PetProvider>(context, listen: false)
                      .addPet(newPet);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Pet added successfully'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Failed to add pet'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editPet(Pet pet) {
    final nameController = TextEditingController(text: pet.name);
    final typeController = TextEditingController(text: pet.type);
    final breedController = TextEditingController(text: pet.breed);
    final ageController = TextEditingController(text: pet.age.toString());
    final genderController = TextEditingController(text: pet.gender);
    final vaccinationController =
        TextEditingController(text: pet.vaccinationStatus);
    final healthController = TextEditingController(text: pet.healthNotes);

    // Existing proof is preserved unless the user picks a replacement.
    String? proofUrl = pet.vaccinationProofUrl;

    // Captured up-front so the async save never touches the dialog context
    // after it has been popped.
    final messenger = ScaffoldMessenger.of(context);
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Pet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: breedController,
                    decoration: const InputDecoration(labelText: 'Breed'),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: genderController,
                    decoration: const InputDecoration(labelText: 'Gender'),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: vaccinationController,
                    decoration:
                        const InputDecoration(labelText: 'Vaccination Status'),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: healthController,
                    decoration:
                        const InputDecoration(labelText: 'Health Notes'),
                    maxLines: 3,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _VaccinationProofField(
                    initialUrl: pet.vaccinationProofUrl,
                    referenceName: pet.petId ?? pet.name,
                    messenger: messenger,
                    onChanged: (url) => proofUrl = url,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedPet = Pet(
                petId: pet.petId,
                ownerUid: pet.ownerUid,
                name: nameController.text,
                type: typeController.text,
                breed: breedController.text,
                age: int.tryParse(ageController.text) ?? 0,
                gender: genderController.text,
                vaccinationStatus: vaccinationController.text,
                healthNotes: healthController.text,
                imageUrl: pet.imageUrl,
                vaccinationProofUrl: proofUrl,
              );
              Navigator.pop(dialogContext);
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Updating pet...'),
                    duration: Duration(seconds: 1)),
              );
              try {
                await petProvider.updatePet(updatedPet);
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Pet updated successfully'),
                      backgroundColor: Colors.green),
                );
              } catch (e) {
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Failed to update pet'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deletePet(Pet pet) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text(
            'Are you sure you want to delete ${pet.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await Provider.of<PetProvider>(context, listen: false)
                    .deletePet(pet.petId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${pet.name} has been deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Failed to delete ${pet.name}. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPetDetails(Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _PetDetailsDialog(pet: pet),
    );
  }
}

/// Attachment control for a pet's vaccination/booster proof document.
///
/// The field starts out showing [initialUrl] as "already on file" and only
/// uploads (and reports a new URL through [onChanged]) when the user explicitly
/// picks a replacement file. That way saving without touching the button keeps
/// the existing proof.
class _VaccinationProofField extends StatefulWidget {
  const _VaccinationProofField({
    required this.initialUrl,
    required this.referenceName,
    required this.messenger,
    required this.onChanged,
  });

  final String? initialUrl;
  final String referenceName;
  final ScaffoldMessengerState messenger;
  final ValueChanged<String?> onChanged;

  @override
  State<_VaccinationProofField> createState() => _VaccinationProofFieldState();
}

class _VaccinationProofFieldState extends State<_VaccinationProofField> {
  static const String _folder = 'pet_vaccination_proofs';

  String? _url;
  String? _fileName;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _url = widget.initialUrl;
  }

  bool get _hasProof => _url != null && _url!.isNotEmpty;

  Future<void> _pickAndUpload() async {
    PickedFileData? pickedFile;
    try {
      pickedFile = await PlatformImagePicker.pickFileData(
        allowedExtensions: PlatformImagePicker.allowedDocExts,
        maxSizeBytes: PlatformImagePicker.maxFileBytes,
      );
    } on PickedFileTooLargeException catch (e) {
      _showError(e.message);
      return;
    } catch (_) {
      _showError('Could not open the file picker. Please try again.');
      return;
    }

    final picked = pickedFile;
    if (picked == null || !mounted) return;

    setState(() {
      _uploading = true;
      _fileName = picked.name;
    });

    try {
      final url = await StorageService.instance.uploadPickedFile(
        data: picked,
        folder: _folder,
        referenceName: widget.referenceName,
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _url = url;
      });
      widget.onChanged(url);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _fileName = null;
      });
      _showError('Failed to upload proof. Please try again.');
    }
  }

  void _showError(String message) {
    widget.messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _uploading ? null : _pickAndUpload,
          icon: Icon(
            _hasProof ? Icons.check_circle : Icons.upload_file,
            size: 18,
          ),
          label: Text(
            _uploading
                ? 'Uploading proof...'
                : _fileName != null
                    ? 'Proof: $_fileName'
                    : 'Attach vaccination/booster proof',
          ),
        ),
        if (_hasProof) ...[
          const SizedBox(height: 8),
          Text(
            'A proof document is already on file. Attaching a new file replaces it.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}

class _PetDetailsDialog extends StatefulWidget {
  final Pet pet;
  const _PetDetailsDialog({required this.pet});
  @override
  State<_PetDetailsDialog> createState() => _PetDetailsDialogState();
}

class _PetDetailsDialogState extends State<_PetDetailsDialog> {
  List<MedicalDocument> petDocuments = [];
  bool documentsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final docs = await MedicalDocumentService()
          .getDocumentsForPet(widget.pet.petId ?? '');
      if (mounted) {
        setState(() {
          petDocuments = docs;
          documentsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          petDocuments = [];
          documentsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final ageLabel =
        pet.age <= 1 ? '${pet.age} year old' : '${pet.age} years old';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
              Center(
                  child: CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.1),
                      backgroundImage:
                          pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(pet.imageUrl!)
                              : null,
                      child: pet.imageUrl == null || pet.imageUrl!.isEmpty
                          ? const Icon(Icons.pets,
                              size: 44, color: AppTheme.primaryGreen)
                          : null)),
              const SizedBox(height: 12),
              Center(
                  child: Text(pet.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold))),
              const SizedBox(height: 4),
              Center(
                  child: Text(ageLabel,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600))),
              const SizedBox(height: 16),
              _detailRow(Icons.pets, 'Type', pet.type),
              _detailRow(Icons.info_outline, 'Breed', pet.breed),
              _detailRow(Icons.cake, 'Age',
                  '${pet.age} ${pet.age == 1 ? 'year' : 'years'}'),
              _detailRow(
                  pet.gender.toLowerCase() == 'female'
                      ? Icons.female
                      : Icons.male,
                  'Gender',
                  pet.gender),
              _detailRow(
                  Icons.vaccines,
                  'Vaccination',
                  pet.vaccinationStatus.isEmpty
                      ? 'Not specified'
                      : pet.vaccinationStatus,
                  valueColor:
                      pet.vaccinationStatus.toLowerCase().contains('up to date')
                          ? Colors.green
                          : Colors.orange),
              _detailRow(Icons.medical_information_outlined, 'Health notes',
                  pet.healthNotes.isEmpty ? 'None recorded' : pet.healthNotes),
              const SizedBox(height: 16),
              Text('Documents (${petDocuments.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (documentsLoading)
                const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Loading documents...',
                        style: TextStyle(fontSize: 13, color: Colors.grey)))
              else if (petDocuments.isEmpty)
                Text('No documents uploaded for this pet.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
              else
                ...petDocuments.take(5).map((doc) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(
                              doc.isImage
                                  ? Icons.image_outlined
                                  : Icons.insert_drive_file,
                              color: AppTheme.primaryGreen,
                              size: 20),
                          title: Text(doc.fileName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              MedicalDocument.getDocumentTypeLabel(
                                      doc.documentType) +
                                  ' - ' +
                                  doc.formattedFileSize +
                                  (doc.isVerified ? ' - Verified' : ''),
                              style: const TextStyle(fontSize: 12)),
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text('Opening: ' + doc.fileName),
                                  duration: const Duration(seconds: 2)))),
                    )),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'))),
                const SizedBox(width: 12),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _detailRow(IconData icon, String label, String value,
        {Color? valueColor}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 10),
        SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 13, color: valueColor),
                softWrap: true)),
      ]),
    );
