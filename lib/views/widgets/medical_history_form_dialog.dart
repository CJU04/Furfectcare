import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/models/medical_history.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';
import 'package:vetcare_connect/views/widgets/modal_form_shell.dart';

/// Shared add/edit UI. Clinical findings are never inferred from booking reasons.
class MedicalHistoryFormDialog extends StatefulWidget {
  final List<Pet> pets;
  final List<Appointment> appointments;
  final MedicalHistory? history;
  final Future<void> Function(MedicalHistory, PickedFileData?) onSave;

  const MedicalHistoryFormDialog({
    super.key,
    required this.pets,
    required this.appointments,
    required this.onSave,
    this.history,
  });

  @override
  State<MedicalHistoryFormDialog> createState() =>
      _MedicalHistoryFormDialogState();
}

class _MedicalHistoryFormDialogState extends State<MedicalHistoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _date;
  late final TextEditingController _diagnosis;
  late final TextEditingController _treatment;
  late final TextEditingController _notes;
  String? _petId;
  String? _appointmentId;
  String? _error;
  PickedFileData? _attachment;
  bool _busy = false;
  bool _picking = false;

  List<Pet> get _pets => widget.pets.where((p) => p.petId != null).toList();
  Pet? get _pet {
    for (final pet in _pets) {
      if (pet.petId == _petId) return pet;
    }
    return null;
  }

  List<Appointment> get _appointments {
    final items = widget.appointments
        .where((a) =>
            a.appointmentId != null &&
            a.petId == _petId &&
            a.ownerUid == _pet?.ownerUid)
        .toList();
    items.sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
    return items;
  }

  Appointment? get _appointment {
    for (final appointment in _appointments) {
      if (appointment.appointmentId == _appointmentId) return appointment;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final history = widget.history;
    _petId =
        _pets.any((p) => p.petId == history?.petId) ? history?.petId : null;
    _appointmentId =
        _appointments.any((a) => a.appointmentId == history?.appointmentId)
            ? history?.appointmentId
            : null;
    _date = TextEditingController(text: history?.date ?? '');
    _diagnosis = TextEditingController(text: history?.diagnosis ?? '');
    _treatment = TextEditingController(text: history?.treatment ?? '');
    _notes = TextEditingController(text: history?.notes ?? '');
  }

  void _selectPet(String? value) {
    setState(() {
      _petId = value;
      _appointmentId =
          _appointments.isEmpty ? null : _appointments.first.appointmentId;
      _date.text = _appointment?.date.split('T').first ?? '';
      // Never carry clinical findings from a different pet into this record.
      _diagnosis.clear();
      _treatment.clear();
      _notes.text = _pet?.healthNotes ?? '';
      _attachment = null;
      _error = null;
    });
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _validateDate(String? value) {
    if (_required(value) != null) {
      return 'Select an appointment to fill the date.';
    }
    final text = value!.trim();
    final parsed = DateTime.tryParse(text);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
        parsed == null ||
        parsed.toIso8601String().split('T').first != text) {
      return 'Enter a valid date in YYYY-MM-DD format.';
    }
    final now = DateTime.now();
    if (parsed.isAfter(DateTime(now.year, now.month, now.day))) {
      return 'A medical record cannot be dated in the future.';
    }
    return null;
  }

  Future<void> _pickAttachment() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final picked = await PlatformImagePicker.pickFileData(
        type: FileType.custom,
        allowedExtensions: PlatformImagePicker.allowedDocumentExtensions,
        maxSizeBytes: PlatformImagePicker.maxFileSizeBytes,
      );
      if (mounted && picked != null) setState(() => _attachment = picked);
    } on PickedFileTooLargeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not select the file. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _picking || !_formKey.currentState!.validate()) return;
    final base = widget.history ??
        MedicalHistory(
          petId: _petId!,
          appointmentId: _appointmentId!,
          date: '',
          diagnosis: '',
          treatment: '',
          notes: '',
        );
    final record = base.copyWith(
      petId: _petId!,
      appointmentId: _appointmentId!,
      date: _date.text.trim(),
      diagnosis: _diagnosis.text.trim(),
      treatment: _treatment.text.trim(),
      notes: _notes.text.trim(),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(record, _attachment);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy && !_picking,
      child: ModalFormShell(
        title: widget.history == null
            ? 'Add Medical History'
            : 'Edit Medical History',
        icon: Icons.medical_information_outlined,
        submitLabel: widget.history == null ? 'Add record' : 'Save changes',
        isBusy: _busy || _picking,
        onSubmit: _save,
        children: [
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _petId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Pet'),
                  items: _pets
                      .map((p) => DropdownMenuItem(
                            value: p.petId,
                            child: Text('${p.name} (${p.type})',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _busy ? null : _selectPet,
                  validator: _required,
                ),
                const SizedBox(height: 16),
                if (_pet != null) ...[
                  Text(
                      '${_pet!.name} • ${_pet!.breed} • ${_pet!.age} years • ${_pet!.gender}'),
                  Text('Vaccination: ${_pet!.vaccinationStatus}'),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<String>(
                  key: ValueKey('appointment-$_petId-$_appointmentId'),
                  initialValue: _appointmentId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Appointment',
                    helperText: _petId != null && _appointments.isEmpty
                        ? 'No appointments for this pet. Book an appointment first.'
                        : null,
                    helperMaxLines: 3,
                  ),
                  items: _appointments
                      .map((a) => DropdownMenuItem(
                            value: a.appointmentId,
                            child: Text('${a.date} ${a.time} — ${a.reason}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                            _appointmentId = value;
                            _date.text =
                                _appointment?.date.split('T').first ?? '';
                          }),
                  validator: _required,
                ),
                if (_appointment != null) ...[
                  const SizedBox(height: 8),
                  Text('Reason for visit: ${_appointment!.reason}'),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _date,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                      labelText: 'Record date (YYYY-MM-DD)'),
                  validator: _validateDate,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diagnosis,
                  enabled: !_busy,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Diagnosis',
                      helperText:
                          'Enter clinical findings, not the booking reason.',
                      helperMaxLines: 3),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _treatment,
                  enabled: !_busy,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Treatment'),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notes,
                  enabled: !_busy,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Additional notes'),
                ),
              ],
            ),
          ),
          if (_attachment != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file),
              title: Text(_attachment!.name),
              trailing: IconButton(
                tooltip: 'Remove selected attachment',
                onPressed:
                    _busy ? null : () => setState(() => _attachment = null),
                icon: const Icon(Icons.close),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _busy || _picking ? null : _pickAttachment,
            icon: const Icon(Icons.attach_file),
            label: Text(_picking ? 'Selecting file…' : 'Attach file'),
          ),
          if (widget.history != null)
            const Text(
                'Existing documents are kept and can be viewed in record details.'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _date.dispose();
    _diagnosis.dispose();
    _treatment.dispose();
    _notes.dispose();
    super.dispose();
  }
}
