import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vetcare_connect/utils/appointment_scheduling.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/models/medical_history.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/models/medical_document.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/medical_history_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/services/medical_document_service.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key, this.recordId});
  final String? recordId;

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'date_desc';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false)
          .loadAppointments();
      Provider.of<PetProvider>(context, listen: false).loadPets();
      Provider.of<MedicalHistoryProvider>(context, listen: false)
          .loadMedicalHistories();
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

    if (widget.recordId != null) {
      appointments = appointments
          .where((a) => a.appointmentId == widget.recordId)
          .toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      String petName(String petId) {
        for (final p in petProvider.pets) {
          if (p.petId == petId) return p.name;
        }
        return '';
      }

      appointments = appointments.where((a) {
        return a.reason.toLowerCase().contains(q) ||
            a.status.toLowerCase().contains(q) ||
            a.date.contains(q) ||
            a.time.toLowerCase().contains(q) ||
            petName(a.petId).toLowerCase().contains(q);
      }).toList();
    }

    // Greedy STF ordering: active (confirmed, pending) first by earliest
    // time, finished (completed/cancelled/rejected) grouped at the bottom
    // behind a visual separator. Manual sort options still apply on top.
    appointments = AppointmentScheduler.greedyOrder(
      appointments,
      startTime: (a) => a.scheduledDateTime,
      statusOf: (a) => a.status,
    );
    int dateRank(Appointment a) => a.scheduledDateTime.millisecondsSinceEpoch;
    switch (_sortOption) {
      case 'date_asc':
        // Within STF groups keep earliest-first.
        break;
      case 'pet_asc':
        String petName(String petId) {
          for (final p in petProvider.pets) {
            if (p.petId == petId) return p.name;
          }
          return '';
        }

        appointments.sort((a, b) => petName(a.petId)
            .toLowerCase()
            .compareTo(petName(b.petId).toLowerCase()));
        break;
      case 'status_asc':
        appointments.sort(
            (a, b) => a.status.toLowerCase().compareTo(b.status.toLowerCase()));
        break;
      default:
        appointments.sort((a, b) => dateRank(b).compareTo(dateRank(a)));
    }

    final bool isCustomer = role == 'customer';
    final int firstFinishedIndex =
        appointments.indexWhere((a) => AppointmentStatus.isFinished(a.status));
    // Sorting (in-memory, works regardless of backend ordering).
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (!isCustomer)
            IconButton(
              tooltip: 'Appointment activity history',
              icon: const Icon(Icons.history),
              onPressed: () =>
                  _showAppointmentHistoryDialog(appointmentProvider),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/appointment_management'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      hintText: 'Reason, status, date, time or pet name',
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
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortOption,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                        value: 'date_desc', child: Text('STF schedule')),
                    DropdownMenuItem(
                        value: 'date_asc', child: Text('Oldest first')),
                    DropdownMenuItem(value: 'pet_asc', child: Text('Pet A-Z')),
                    DropdownMenuItem(
                        value: 'status_asc', child: Text('Status A-Z')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOption = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: appointments.length + (firstFinishedIndex > 0 ? 1 : 0),
              itemBuilder: (context, index) {
                if (firstFinishedIndex > 0 && index == firstFinishedIndex) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Finished',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider()),
                    ]),
                  );
                }
                final adj =
                    (firstFinishedIndex > 0 && index > firstFinishedIndex)
                        ? index - 1
                        : index;
                final a = appointments[adj];
                final normalized = AppointmentStatus.normalize(a.status);
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(a.reason,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Date: ${a.date}\nTime: ${a.time}',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                    onTap: () => _showAppointmentDetails(context, a),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(normalized),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppointmentStatus.label(normalized).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (normalized == AppointmentStatus.pending &&
                            (role == 'staff' || role == 'veterinarian')) ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            tooltip: 'Accept',
                            onPressed: () => _updateAppointmentStatus(
                                a,
                                AppointmentStatus.confirmed,
                                appointmentProvider),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.cancel, color: Colors.orange),
                            tooltip: 'Reject',
                            onPressed: () =>
                                _showRejectDialog(a, appointmentProvider),
                          ),
                        ] else if (!isCustomer) ...[
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
                        ],
                        if (isCustomer &&
                            (normalized == AppointmentStatus.pending ||
                                normalized == AppointmentStatus.confirmed))
                          TextButton(
                            onPressed: () => _updateAppointmentStatus(
                                a,
                                AppointmentStatus.cancelled,
                                appointmentProvider),
                            child: const Text('Cancel'),
                          )
                        else if (!isCustomer)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteAppointment(a, appointmentProvider),
                          ),
                        if (isCustomer &&
                            AppointmentStatus.isFinished(normalized))
                          TextButton(
                            onPressed: () {
                              // Re-booking: opens the booking form prefilled
                              // from the finished appointment and creates a
                              // brand-new record (the old one is kept as
                              // history).
                              _showAppointmentDialog(
                                appointment: null,
                                prefillFrom: a,
                                appointmentProvider: appointmentProvider,
                                petProvider: petProvider,
                                medicalHistoryProvider: medicalHistoryProvider,
                              );
                            },
                            child: const Text('Book Again'),
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
        if (excludeAppointmentId != null &&
            appt.appointmentId == excludeAppointmentId) continue;
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
    Appointment? prefillFrom,
  }) {
    final formKey = GlobalKey<FormState>();
    final authProvider = context.read<AuthProvider>();
    final firebaseUserProvider = context.read<FirebaseUserProvider>();
    final uid = authProvider.firebaseUser?.uid;

    // `prefillFrom` seeds the form from a finished (completed / cancelled /
    // rejected) appointment for re-booking, while still creating a brand-new
    // record instead of rewriting the old one.
    final Appointment? source = appointment ?? prefillFrom;
    final bool isRebooking = appointment == null && prefillFrom != null;

    if (uid == null) return;

    final role = authProvider.role?.value;

    // Load users if not already loaded
    if (firebaseUserProvider.users.isEmpty) {
      firebaseUserProvider.loadUsers();
    }

    final reasonController = TextEditingController(text: source?.reason ?? '');
    final dateController = TextEditingController(text: source?.date ?? '');
    // Normalize stored time to HH:mm (legacy rows may carry :00 or :ss
    // suffixes from the old ":00" append in showTimePicker).
    final rawTime = source?.time ?? '';
    final timeController = TextEditingController(
      text: _normalizeTime(rawTime),
    );
    final petDescriptionController = TextEditingController();
    final medicalHistoryController = TextEditingController();
    PickedFileData? attachmentFile;
    String? attachmentUrl;

    // For staff/veterinarian creating new appointment, they need to select a customer
    // For customers or when editing, use the current logic
    final bool isStaffOrVet = role == 'staff' || role == 'veterinarian';
    final bool isNewAppointment = appointment == null;

    // Get list of customers for staff/vet to choose from
    List<FirebaseUser> customers = firebaseUserProvider.users
        .where((u) => u.role.value == 'customer')
        .toList();

    FirebaseUser? selectedCustomer;
    String ownerUid;

    if (isNewAppointment && isStaffOrVet) {
      // Staff/Vet must select a customer
      ownerUid = '';
    } else {
      ownerUid = source?.ownerUid ?? uid;
      if (ownerUid.isNotEmpty && ownerUid != uid) {
        // Try to find the customer for display
        selectedCustomer = customers.where((c) => c.uid == ownerUid).isNotEmpty
            ? customers.firstWhere((c) => c.uid == ownerUid)
            : null;
      }
    }

    List<Pet> availablePets = ownerUid.isNotEmpty
        ? petProvider.pets.where((p) => p.ownerUid == ownerUid).toList()
        : <Pet>[];

    Pet? selectedPet;

    if (source != null) {
      selectedPet =
          availablePets.where((p) => p.petId == source.petId).isNotEmpty
              ? availablePets.firstWhere((p) => p.petId == source.petId)
              : null;
      if (selectedPet != null) {
        petDescriptionController.text = selectedPet.name;
      }
    }

    String status = AppointmentStatus.normalize(
        appointment?.status ?? AppointmentStatus.pending);

    List<MedicalHistory> selectedPetHistories = [];

    void populatePetDetails(Pet? pet) {
      if (pet == null) {
        petDescriptionController.clear();
        medicalHistoryController.clear();
        selectedPetHistories = [];
        return;
      }
      petDescriptionController.text =
          'Type: ${pet.type}, Breed: ${pet.breed}, Age: ${pet.age}y';
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

    // Don't block dialog opening for staff/vet - they can select customer first
    // Only return early for customers who have no pets (not for staff/vet who need to select customer first)
    if (availablePets.isEmpty && appointment == null && !isStaffOrVet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No pets found. Please add a pet first in Pet Management.'),
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
              title: Text(appointment == null
                  ? 'Book Appointment'
                  : 'Edit Appointment'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Customer selection for staff/veterinarian when creating new appointment
                        if (isNewAppointment && isStaffOrVet)
                          DropdownButtonFormField<FirebaseUser>(
                            decoration: const InputDecoration(
                              labelText: 'Select Customer',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            initialValue: selectedCustomer,
                            isExpanded: true,
                            items: customers.map((customer) {
                              return DropdownMenuItem<FirebaseUser>(
                                value: customer,
                                child: Text(
                                    '${customer.fullname} (${customer.email})',
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (FirebaseUser? customer) {
                              setState(() {
                                selectedCustomer = customer;
                                ownerUid = customer?.uid ?? '';
                                availablePets = ownerUid.isNotEmpty
                                    ? petProvider.pets
                                        .where((p) => p.ownerUid == ownerUid)
                                        .toList()
                                    : <Pet>[];
                                selectedPet = availablePets.isNotEmpty
                                    ? availablePets.first
                                    : null;
                                populatePetDetails(selectedPet);
                              });
                            },
                            validator: (value) {
                              if (value == null)
                                return 'Please select a customer';
                              return null;
                            },
                          ),
                        if (isNewAppointment && isStaffOrVet)
                          const SizedBox(height: 8),
                        DropdownButtonFormField<Pet>(
                          decoration: const InputDecoration(
                            labelText: 'Select Pet',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          initialValue: selectedPet,
                          isExpanded: true,
                          items: availablePets.map((pet) {
                            return DropdownMenuItem<Pet>(
                              value: pet,
                              child: Text(pet.name,
                                  overflow: TextOverflow.ellipsis),
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
                          title: const Text('Pet Info',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          children: [
                            Text(
                              petDescriptionController.text.isEmpty
                                  ? '-'
                                  : petDescriptionController.text,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black87),
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
                              initialDate:
                                  (dateController.text.trim().isNotEmpty)
                                      ? DateTime.tryParse(
                                              dateController.text.trim()) ??
                                          DateTime.now()
                                      : DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                dateController.text =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                              });
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
                              dateController.text.isEmpty
                                  ? 'Select Date'
                                  : dateController.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: dateController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            // If there's already a value, try to set initialTime from it.
                            final existing = timeController.text.trim();
                            TimeOfDay initialTime = TimeOfDay.now();
                            if (existing.isNotEmpty) {
                              final parts = existing.split(':');
                              if (parts.length >= 2) {
                                final h = int.tryParse(parts[0]);
                                final m = int.tryParse(parts[1]);
                                if (h != null && m != null) {
                                  initialTime = TimeOfDay(hour: h, minute: m);
                                }
                              }
                            }

                            final time = await showTimePicker(
                              context: dialogContext,
                              initialTime: initialTime,
                            );
                            if (time != null) {
                              setState(() {
                                // Store as HH:mm exactly — the Cloud Function
                                // minute() regex expects HH:mm (with optional legacy
                                // HH:mm:ss). Never append ":00" so the regex keeps
                                // matching.
                                final hh = time.hour.toString().padLeft(2, '0');
                                final mm =
                                    time.minute.toString().padLeft(2, '0');
                                timeController.text = '$hh:$mm';
                              });
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
                              timeController.text.isEmpty
                                  ? 'Select Time'
                                  : timeController.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: timeController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
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
                            initialValue: status,
                            items: const [
                              DropdownMenuItem(
                                  value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(
                                  value: 'confirmed', child: Text('Scheduled')),
                              DropdownMenuItem(
                                  value: 'completed', child: Text('Completed')),
                              DropdownMenuItem(
                                  value: 'cancelled', child: Text('Cancelled')),
                              DropdownMenuItem(
                                  value: 'rejected', child: Text('Rejected')),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                status = v;
                              });
                            },
                          ),
                        const SizedBox(height: 8),
                        if (attachmentFile != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    attachmentFile!.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      attachmentFile = null;
                                      attachmentUrl = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (attachmentUrl != null && attachmentFile == null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link, color: Colors.green),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Attachment attached',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () async {
                            PickedFileData? picked;
                            try {
                              picked = await PlatformImagePicker.pickFileData(
                                type: FileType.custom,
                                allowedExtensions: PlatformImagePicker
                                    .allowedDocumentExtensions,
                                maxSizeBytes:
                                    PlatformImagePicker.maxFileSizeBytes,
                                dialogTitle:
                                    'Select attachment (PDF, DOC, JPG, PNG)',
                              );
                            } on PickedFileTooLargeException catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  SnackBar(
                                      content: Text(e.message),
                                      backgroundColor: Colors.orange),
                                );
                              }
                              return;
                            } catch (_) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Could not select a file. Please try again.'),
                                      backgroundColor: Colors.orange),
                                );
                              }
                              return;
                            }
                            if (picked == null) return;
                            setState(() {
                              attachmentFile = picked;
                            });
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Attach File'),
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    // For staff/vet creating new appointment, validate customer is selected
                    if (isNewAppointment && isStaffOrVet && ownerUid.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a customer'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final selectedDate = dateController.text.trim();
                    final selectedTime = timeController.text.trim();

                    // Validate date and time are selected
                    if (selectedDate.isEmpty || selectedTime.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select both date and time'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Check for overlapping appointments
                    final hasConflict = _hasOverlap(
                      date: selectedDate,
                      time: selectedTime,
                      ownerUid: ownerUid,
                      petId: selectedPet?.petId,
                      allAppointments: appointmentProvider.appointments,
                      excludeAppointmentId: appointment?.appointmentId ??
                          prefillFrom?.appointmentId,
                    );

                    if (hasConflict) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'You already have an appointment at this time. Please choose a different time.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Show confirmation dialog before saving
                    final confirmed = await _showConfirmationDialog(
                      context: dialogContext,
                      selectedPet: selectedPet,
                      selectedDate: selectedDate,
                      selectedTime: selectedTime,
                      reason: reasonController.text.trim(),
                      isCustomer: role == 'customer',
                    );

                    if (!confirmed || !dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    // Create or update appointment
                    // For new customer appointments, set status to 'pending' for approval
                    String finalStatus = status;
                    if (isNewAppointment && role == 'customer') {
                      finalStatus = 'pending';
                    }

                    try {
                      Appointment appt = Appointment(
                        appointmentId: appointment?.appointmentId,
                        petId: selectedPet?.petId ?? '',
                        ownerUid: ownerUid,
                        // New customer bookings must be unassigned and
                        // pending — the Cloud Function rejects anything else
                        // ("New appointments must be unassigned and pending").
                        assignedUserId: appointment?.assignedUserId ??
                            (isNewAppointment && role == 'customer'
                                ? null
                                : uid),
                        date: selectedDate,
                        time: selectedTime,
                        reason: reasonController.text.trim(),
                        status: finalStatus,
                      );

                      if (appointment == null) {
                        final String newId;
                        if (isRebooking) {
                          // Creates a NEW record and writes a 'rebooked'
                          // activity log for the admin history.
                          newId = await appointmentProvider.rebookAppointment(
                            appt,
                            previousAppointment: prefillFrom,
                          );
                        } else {
                          newId =
                              await appointmentProvider.addAppointment(appt);
                        }
                        appt = appt.copyWith(appointmentId: newId);
                      } else {
                        await appointmentProvider.updateAppointment(appt);
                      }

                      // Upload attachment once and link it to the saved appointment.
                      if (attachmentFile != null &&
                          appt.appointmentId != null &&
                          appt.appointmentId!.isNotEmpty) {
                        try {
                          final doc = MedicalDocument(
                            petId: appt.petId,
                            appointmentId: appt.appointmentId!,
                            historyId: '',
                            ownerUid: appt.ownerUid,
                            documentType: 'appointment_attachment',
                            fileName: attachmentFile!.name,
                            fileUrl: '',
                            fileSizeBytes: attachmentFile!.size,
                            mimeType: attachmentFile!.mimeType,
                            uploadedBy: uid,
                          );

                          final docId =
                              await MedicalDocumentService().uploadDocumentData(
                            data: attachmentFile!,
                            document: doc,
                          );
                          debugPrint('Appointment attachment saved: $docId');

                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Attachment uploaded: ${attachmentFile!.name}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Failed to upload attachment: $e');
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Attachment could not be saved: $e. '
                                    'The appointment was saved; please retry '
                                    'the file in Edit.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }

                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(role == 'customer'
                                ? 'Appointment submitted for approval. You will be notified once reviewed.'
                                : 'Appointment updated successfully'),
                            backgroundColor:
                                role == 'customer' ? Colors.blue : Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save appointment: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
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

  void _deleteAppointment(
      Appointment appointment, AppointmentProvider appointmentProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text(
            'Are you sure you want to delete "${appointment.reason}" on ${appointment.date}? This action cannot be undone.'),
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
                      content: Text(
                          'Failed to delete appointment. Please try again.'),
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

  /// Admin/clinic-side activity history for appointments: every create,
  /// update, cancel, complete, delete and re-book activity is recorded in
  /// the `appointment_logs` audit collection.
  void _showAppointmentHistoryDialog(AppointmentProvider appointmentProvider) {
    appointmentProvider.loadAppointmentLogs();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Appointment Activity History',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh),
                        onPressed: () =>
                            appointmentProvider.loadAppointmentLogs(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Consumer<AppointmentProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoadingLogs) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final logs = provider.appointmentLogs;
                      if (logs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No activity recorded yet.\n\n'
                              'Booking, cancelling, completing and re-booking '
                              'appointments will appear here as a permanent '
                              'audit history.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: _activityColor(log.action)
                                    .withValues(alpha: 0.15),
                                child: Icon(_activityIcon(log.action),
                                    size: 16,
                                    color: _activityColor(log.action)),
                              ),
                              title: Text(
                                '${_activityLabel(log.action)} • '
                                '${DateFormat('MMM d, yyyy • h:mm a').format(log.createdAt)}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${log.actorName.isNotEmpty ? log.actorName : log.actorUid}\n'
                                '${log.details}'
                                '${log.oldStatus.isNotEmpty && log.newStatus.isNotEmpty && log.oldStatus != log.newStatus ? '\nStatus: ${AppointmentStatus.label(log.oldStatus)} → ${AppointmentStatus.label(log.newStatus)}' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _activityColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
      case 'rebooked':
        return Colors.green;
      case 'cancelled':
      case 'deleted':
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _activityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Icons.add_circle_outline;
      case 'rebooked':
        return Icons.event_repeat;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'deleted':
        return Icons.delete_outline;
      case 'completed':
        return Icons.check_circle_outline;
      case 'assigned':
        return Icons.person_add_alt_1;
      default:
        return Icons.edit_note;
    }
  }

  String _activityLabel(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return 'Booked';
      case 'rebooked':
        return 'Re-booked';
      case 'cancelled':
        return 'Cancelled';
      case 'deleted':
        return 'Deleted';
      case 'completed':
        return 'Completed';
      case 'assigned':
        return 'Assigned';
      case 'status_changed':
        return 'Status changed';
      default:
        return 'Updated';
    }
  }

  Future<bool> _showConfirmationDialog({
    required BuildContext context,
    required Pet? selectedPet,
    required String selectedDate,
    required String selectedTime,
    required String reason,
    required bool isCustomer,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            isCustomer ? 'Confirm Appointment Request' : 'Confirm Appointment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCustomer)
                const Text(
                  'Please review your appointment details before submitting:',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 12),
              _buildConfirmRow('Pet', selectedPet?.name ?? '-'),
              _buildConfirmRow('Date', selectedDate),
              _buildConfirmRow('Time', selectedTime),
              _buildConfirmRow('Reason', reason),
              if (isCustomer) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your appointment will be submitted for approval. You will receive a notification once the veterinarian reviews your request.',
                          style: TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(isCustomer ? 'Submit Request' : 'Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _updateAppointmentStatus(Appointment appointment, String newStatus,
      AppointmentProvider appointmentProvider) async {
    try {
      final id = appointment.appointmentId;
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot update: appointmentId missing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updated = appointment.copyWith(status: newStatus);
      await appointmentProvider.updateAppointment(updated);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Appointment ${newStatus == 'confirmed' ? 'accepted' : newStatus} successfully'),
          backgroundColor:
              newStatus == 'confirmed' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update appointment status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(
      Appointment appointment, AppointmentProvider appointmentProvider) {
    final rejectReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Please provide a reason for rejecting "${appointment.reason}" on ${appointment.date}:'),
            const SizedBox(height: 12),
            TextField(
              controller: rejectReasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText:
                    'e.g., Veterinarian unavailable, scheduling conflict, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (rejectReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              // Update status with rejection reason stored in reason field
              final originalReason = appointment.reason;
              final updatedReason =
                  '$originalReason\n[REJECTED: ${rejectReasonController.text.trim()}]';
              final updatedAppointment = appointment.copyWith(
                status: 'rejected',
                reason: updatedReason,
              );

              try {
                final id = appointment.appointmentId;
                if (id == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot reject: appointmentId missing'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                await appointmentProvider.updateAppointment(updatedAppointment);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment rejected'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reject appointment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Shows the full details of a single appointment in a read-only dialog.
  /// Tapping an appointment card anywhere in the list opens this.
  void _showAppointmentDetails(BuildContext context, Appointment appointment) {
    final petProvider = context.read<PetProvider>();
    final historyProvider = context.read<MedicalHistoryProvider>();
    final userProvider = context.read<FirebaseUserProvider>();

    Pet? pet;
    for (final p in petProvider.pets) {
      if (p.petId == appointment.petId) {
        pet = p;
        break;
      }
    }

    FirebaseUser? owner;
    FirebaseUser? assigned;
    for (final u in userProvider.users) {
      if (u.uid == appointment.ownerUid) owner = u;
      if (u.uid == appointment.assignedUserId) assigned = u;
    }

    final relatedHistories = historyProvider.medicalHistories
        .where((h) => h.appointmentId == appointment.appointmentId)
        .toList();

    List<MedicalDocument> documents = const <MedicalDocument>[];
    bool documentsLoaded = appointment.appointmentId == null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (!documentsLoaded) {
              documentsLoaded = true;
              MedicalDocumentService()
                  .getDocumentsForAppointment(appointment.appointmentId!)
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
                  const Icon(Icons.event_note, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.reason.isEmpty
                          ? 'Appointment Details'
                          : appointment.reason,
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
                    _buildDetailLabel(Icons.flag_outlined, 'Status'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildDetailTile(
                      Icons.calendar_today,
                      'Date',
                      appointment.date.isEmpty ? 'Not set' : appointment.date,
                    ),
                    _buildDetailTile(
                      Icons.access_time,
                      'Time',
                      appointment.time.isEmpty ? 'Not set' : appointment.time,
                    ),
                    _buildDetailTile(
                      Icons.pets,
                      'Pet',
                      pet == null
                          ? 'Unknown pet'
                          : '${pet.name} (${pet.type}'
                              '${pet.breed.isNotEmpty ? ' - ${pet.breed}' : ''}'
                              '${pet.age > 0 ? ' - ${pet.age}y' : ''})',
                    ),
                    if (pet != null)
                      _buildDetailTile(
                        Icons.health_and_safety_outlined,
                        'Vaccination',
                        pet.vaccinationStatus.isEmpty
                            ? 'Not recorded'
                            : pet.vaccinationStatus,
                      ),
                    if (pet != null && pet.healthNotes.isNotEmpty)
                      _buildDetailTile(
                        Icons.notes,
                        'Health Notes',
                        pet.healthNotes,
                      ),
                    _buildDetailTile(
                      Icons.person_outline,
                      'Owner',
                      owner == null
                          ? 'Not available'
                          : '${owner.name}\n${owner.email}'
                              '${owner.contactNumber.isNotEmpty ? '\n${owner.contactNumber}' : ''}',
                    ),
                    _buildDetailTile(
                      Icons.badge_outlined,
                      'Assigned To',
                      assigned == null
                          ? 'Unassigned'
                          : '${assigned.name} (${assigned.role.value})',
                    ),
                    _buildDetailTile(
                      Icons.description_outlined,
                      'Reason',
                      appointment.reason.isEmpty
                          ? 'Not provided'
                          : appointment.reason,
                    ),
                    const Divider(height: 24),
                    _buildDetailLabel(Icons.history,
                        'Medical History (${relatedHistories.length})'),
                    if (relatedHistories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No medical history linked to this appointment.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    else
                      ...relatedHistories.map(
                        (history) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.medical_services,
                                color: AppTheme.primaryGreen),
                            title: Text(history.diagnosis),
                            subtitle: Text(
                              '${history.date} - ${history.treatment}'
                              '${history.fuzzyConcernLevel != null ? '\nUrgency: ${history.fuzzyConcernLevel}' : ''}',
                            ),
                          ),
                        ),
                      ),
                    const Divider(height: 24),
                    _buildDetailLabel(
                        Icons.attach_file, 'Documents (${documents.length})'),
                    if (documents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No documents uploaded for this appointment.',
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
                              color: AppTheme.primaryGreen,
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

  /// Small section heading used inside the appointment details dialog.
  Widget _buildDetailLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// One key/value row inside the appointment details dialog.
  Widget _buildDetailTile(IconData icon, String label, String value) {
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

  /// Normalizes a stored time string to HH:mm.
  ///
  /// Legacy rows written with the old ":00" append in showTimePicker may
  /// carry "HH:mm:00" or "HH:mm:ss"; this collapses them to the canonical
  /// "HH:mm" that the Cloud Function minute() regex accepts.
  String _normalizeTime(String? time) {
    if (time == null || time.isEmpty) return '';
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(time);
    if (m == null) return time;
    final hh = m.group(1)!.padLeft(2, '0');
    final mm = m.group(2)!.padLeft(2, '0');
    return '$hh:$mm';
  }
}
