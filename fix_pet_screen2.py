#!/usr/bin/env python3
"""Add the _PetDetailsDialog class"""

with open('lib/views/screens/pet_management_screen.dart', 'r') as f:
    content = f.read()

# Add the _PetDetailsDialog class at the end of the file (before the final })
dialog_class = '''
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
      final docs = await MedicalDocumentService().getDocumentsForPet(widget.pet.petId ?? '');
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
    final ageLabel = pet.age <= 1 ? '${pet.age} year old' : '${pet.age} years old';
    
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 48, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              Center(child: CircleAvatar(radius: 48, backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1), backgroundImage: pet.imageUrl != null && pet.imageUrl!.isNotEmpty ? CachedNetworkImageProvider(pet.imageUrl!) : null, child: pet.imageUrl == null || pet.imageUrl!.isEmpty ? const Icon(Icons.pets, size: 44, color: AppTheme.primaryGreen) : null)),
              const SizedBox(height: 12),
              Center(child: Text(pet.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              const SizedBox(height: 4),
              Center(child: Text(ageLabel, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
              const SizedBox(height: 16),
              _detailRow(Icons.pets, 'Type', pet.type),
              _detailRow(Icons.info_outline, 'Breed', pet.breed),
              _detailRow(Icons.cake, 'Age', '${pet.age} ${pet.age == 1 ? 'year' : 'years'}'),
              _detailRow(pet.gender.toLowerCase() == 'female' ? Icons.female : Icons.male, 'Gender', pet.gender),
              _detailRow(Icons.vaccines, 'Vaccination', pet.vaccinationStatus.isEmpty ? 'Not specified' : pet.vaccinationStatus, valueColor: pet.vaccinationStatus.toLowerCase().contains('up to date') ? Colors.green : Colors.orange),
              _detailRow(Icons.medical_information_outlined, 'Health notes', pet.healthNotes.isEmpty ? 'None recorded' : pet.healthNotes),
              const SizedBox(height: 16),
              Text('Documents (${petDocuments.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (documentsLoading)
                const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Loading documents...', style: TextStyle(fontSize: 13, color: Colors.grey)))
              else if (petDocuments.isEmpty)
                Text('No documents uploaded for this pet.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
              else
                ...petDocuments.take(5).map((doc) => Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: Icon(doc.isImage ? Icons.image_outlined : Icons.insert_drive_file, color: AppTheme.primaryGreen, size: 20), title: Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(MedicalDocument.getDocumentTypeLabel(doc.documentType) + ' - ' + doc.formattedFileSize + (doc.isVerified ? ' - Verified' : ''), style: const TextStyle(fontSize: 12)), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening: ' + doc.fileName), duration: const Duration(seconds: 2)))),)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); }, icon: const Icon(Icons.edit, size: 18), label: const Text('Edit'))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Delete'))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 18, color: AppTheme.primaryGreen),
    const SizedBox(width: 10),
    SizedBox(width: 92, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
    Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: valueColor), softWrap: true)),
  ]),
);
'''

# Find the last } and insert before it
last_brace = content.rfind('}')
if last_brace > 0:
    content = content[:last_brace] + dialog_class + '\n' + content[last_brace:]

with open('lib/views/screens/pet_management_screen.dart', 'w') as f:
    f.write(content)

print('Part 2 done')