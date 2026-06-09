import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/models/medical_history.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/medical_history_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).loadAppointments();
      Provider.of<PetProvider>(context, listen: false).loadPets();
      Provider.of<MedicalHistoryProvider>(context, listen: false).loadMedicalHistories();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;

    final role = authProvider.role?.value;
    final appointmentProvider = context.watch<AppointmentProvider>();
    final petProvider = context.watch<PetProvider>();
    final medicalHistoryProvider = context.watch<MedicalHistoryProvider>();

    List<Appointment> appointments = appointmentProvider.appointments;

    // Filter based on role:
    // - customer: only their appointments (ownerUid == current uid)
    // - staff/veterinarian: you might want to show assigned or all; keep it broad but consistent:
    if (role == 'customer' && uid != null) {
      appointments = appointments.where((a) => a.ownerUid == uid).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      appointments = appointments
          .where((a) => a.reason.toLowerCase().contains(q) || a.status.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: '/appointment_management'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search appointments (reason or status)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final a = appointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(a.reason),
                    subtitle: Text('Date: ${a.date}\nTime: ${a.time}\nStatus: ${a.status}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showAppointmentDialog(
                              appointment: a,
                              appointmentProvider: appointmentProvider,
                              petProvider: petProvider,
                              medicalHistoryProvider: medicalHistoryProvider,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAppointment(a, appointmentProvider),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (uid == null) return;
          _showAppointmentDialog(
            appointment: null,
            appointmentProvider: appointmentProvider,
            petProvider: petProvider,
            medicalHistoryProvider: medicalHistoryProvider,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPetAge(Pet? pet) {
    if (pet == null) return '-';
    return '${pet.age} years';
  }

  bool _hasOverlap({
    required String date,
    required String time,
    required String ownerUid,
    required String? petId,
    required List<Appointment> allAppointments,
    String? excludeAppointmentId,
  }) {
    try {
      final newTimeMinutes = _timeToMinutes(time);
      if (newTimeMinutes == null) return false;

      for (final appt in allAppointments) {
        if (excludeAppointmentId != null && appt.appointmentId == excludeAppointmentId) continue;
        if (appt.ownerUid != ownerUid) continue;
        if (date != appt.date) continue;

        final existingTimeMinutes = _timeToMinutes(appt.time);
        if (existingTimeMinutes == null) continue;

        final diff = (newTimeMinutes - existingTimeMinutes).abs();
        if (diff < 60) return true;
      }
    } catch (_) {}
    return false;
  }

  int? _timeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }

  void _showAppointmentDialog({
    required AppointmentProvider appointmentProvider,
    required PetProvider petProvider,
    required MedicalHistoryProvider medicalHistoryProvider,
    Appointment? appointment,
  }) {
    final formKey = GlobalKey<FormState>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;

    if (uid == null) return;

    final role = authProvider.role?.value;

    final reasonController = TextEditingController(text: appointment?.reason ?? '');
    final dateController = TextEditingController(text: appointment?.date ?? '');
    final timeController = TextEditingController(text: appointment?.time ?? '');
    final petDescriptionController = TextEditingController();
    final medicalHistoryController = TextEditingController();

    final String ownerUid = appointment?.ownerUid ?? uid;
    List<Pet> availablePets = petProvider.pets.where((p) => p.ownerUid == ownerUid).toList();

    Pet? selectedPet;

    if (appointment == null) {
      selectedPet = availablePets.isNotEmpty ? availablePets.first : null;
    } else {
      selectedPet = availablePets.where((p) => p.petId == appointment.petId).isNotEmpty
          ? availablePets.firstWhere((p) => p.petId == appointment.petId)
          : null;
      if (selectedPet != null) {
        petDescriptionController.text = selectedPet.name;
      }
    }

    String status = appointment?.status ?? 'scheduled';

    List<MedicalHistory> selectedPetHistories = [];

    void populatePetDetails(Pet? pet) {
      if (pet == null) {
        petDescriptionController.clear();
        medicalHistoryController.clear();
        selectedPetHistories = [];
        return;
      }
      petDescriptionController.text = 'Type: ${pet.type}, Breed: ${pet.breed}, Age: ${pet.age}y';
      selectedPetHistories = medicalHistoryProvider.medicalHistories
          .where((h) => h.petId == pet.petId)
          .toList();
      if (selectedPetHistories.isNotEmpty) {
        medicalHistoryController.text = selectedPetHistories
            .take(2)
            .map((h) => '${h.date}: ${h.diagnosis}')
            .join(' | ');
      } else {
        medicalHistoryController.text = 'No medical history';
      }
    }

    populatePetDetails(selectedPet);

    if (availablePets.isEmpty && appointment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pets found. Please add a pet first in Pet Management.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(appointment == null ? 'Book Appointment' : 'Edit Appointment'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      DropdownButtonFormField<Pet>(
                        decoration: const InputDecoration(
                          labelText: 'Select Pet',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        value: selectedPet,
                        isExpanded: true,
                        items: availablePets.map((pet) {
                          return DropdownMenuItem<Pet>(
                            value: pet,
                            child: Text(pet.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (Pet? pet) {
                          setState(() {
                            selectedPet = pet;
                            if (pet != null) {
                              petDescriptionController.text = pet.name;
                            }
                            populatePetDetails(pet);
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select a pet';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      ExpansionTile(
                        title: const Text('Pet Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        children: [
                          Text(
                            petDescriptionController.text.isEmpty ? '-' : petDescriptionController.text,
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: medicalHistoryController,
                        decoration: const InputDecoration(
                          labelText: 'Medical History',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 1,
                        enabled: false,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: dialogContext,
                            initialDate: (dateController.text.trim().isNotEmpty)
                                ? DateTime.tryParse(dateController.text.trim()) ?? DateTime.now()
                                : DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                            isDense: true,
                          ),
                          child: Text(
                            dateController.text.isEmpty ? 'Select Date' : dateController.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: dateController.text.isEmpty ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time, size: 18),
                            isDense: true,
                          ),
                          child: Text(
                            timeController.text.isEmpty ? 'Select Time' : timeController.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: timeController.text.isEmpty ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 1,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please describe the reason for your visit';
                          }
                          if (value.trim().length < 3) {
                            return 'Reason must be at least 3 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (role != 'customer' || appointment != null)
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          value: status,
                          items: const [
                            DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                            DropdownMenuItem(value: 'completed', child: Text('Completed')),
                            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              status = v;
                            });
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final selectedDate = dateController.text.trim();
                    final selectedTime = timeController.text.trim();

                    if (selectedDate.isNotEmpty && selectedTime.isNotEmpty) {
                      final hasConflict = _hasOverlap(
                        date: selectedDate,
                        time: selectedTime,
                        ownerUid: ownerUid,
                        petId: selectedPet?.petId,
                        allAppointments: appointmentProvider.appointments,
                        excludeAppointmentId: appointment?.appointmentId,
                      );

                      if (hasConflict) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You already have an appointment at this time. Please choose a different time.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteAppointment(Appointment appointment, AppointmentProvider appointmentProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Are you sure you want to delete "${appointment.reason}" on ${appointment.date}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Deleting appointment...'),
                  duration: Duration(seconds: 1),
                ),
              );
              try {
                final id = appointment.appointmentId;
                if (id == null) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot delete: appointmentId missing'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                await appointmentProvider.deleteAppointment(id);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete appointment. Please try again.'),
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
}
