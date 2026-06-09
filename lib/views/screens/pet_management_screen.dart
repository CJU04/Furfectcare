import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

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
      pets = pets.where((pet) => pet.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
                        padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth > 600 ? (constraints.maxWidth - 800) / 2 : 0),
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: ExpansionTile(
                              leading: const Icon(Icons.pets),
                              title: Text(pet.name),
                              subtitle: Text('${pet.type} - ${pet.breed}, Age: ${pet.age}, ${pet.gender}'),
                              trailing: role?.value == 'customer' ? null : Row(
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Vaccination Status: ${pet.vaccinationStatus}'),
                                      const SizedBox(height: 8),
                                      Text('Health Notes: ${pet.healthNotes.isNotEmpty ? pet.healthNotes : 'No notes available'}'),
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
                        DropdownMenuItem(value: 'Rabbit', child: Text('Rabbit')),
                        DropdownMenuItem(value: 'Hamster', child: Text('Hamster')),
                        DropdownMenuItem(value: 'Guinea Pig', child: Text('Guinea Pig')),
                        DropdownMenuItem(value: 'Fish', child: Text('Fish')),
                        DropdownMenuItem(value: 'Reptile', child: Text('Reptile')),
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
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
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
                      decoration: const InputDecoration(labelText: 'Vaccination Status'),
                      items: const [
                        DropdownMenuItem(value: 'Up to date', child: Text('Up to date')),
                        DropdownMenuItem(value: 'Needs booster', child: Text('Needs booster')),
                        DropdownMenuItem(value: 'Not vaccinated', child: Text('Not vaccinated')),
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
                      decoration: const InputDecoration(labelText: 'Health Notes'),
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
                  const SnackBar(content: Text('Adding pet...'), duration: Duration(seconds: 1)),
                );
                try {
                  await Provider.of<PetProvider>(context, listen: false).addPet(newPet);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pet added successfully'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add pet'), backgroundColor: Colors.red),
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
    final vaccinationController = TextEditingController(text: pet.vaccinationStatus);
    final healthController = TextEditingController(text: pet.healthNotes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                    decoration: const InputDecoration(labelText: 'Vaccination Status'),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: healthController,
                    decoration: const InputDecoration(labelText: 'Health Notes'),
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
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updating pet...'), duration: Duration(seconds: 1)),
              );
              try {
                await Provider.of<PetProvider>(context, listen: false).updatePet(updatedPet);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pet updated successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update pet'), backgroundColor: Colors.red),
                  );
                }
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
        content: Text('Are you sure you want to delete ${pet.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await Provider.of<PetProvider>(context, listen: false).deletePet(pet.petId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${pet.name} has been deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete ${pet.name}. Please try again.'),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

