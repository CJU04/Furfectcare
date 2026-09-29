import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/models/appointment_log.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/models/user.dart' show AppNotification;
import 'package:vetcare_connect/providers/notification_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/utils/appointment_scheduling.dart';
import 'package:vetcare_connect/utils/appointment_slot_offer_selector.dart';
import 'package:vetcare_connect/services/firestore/user_service.dart';

class AppointmentProvider with ChangeNotifier {
  final NotificationProvider _notificationProvider;
  final DatabaseService? _databaseOverride;
  final Future<List<Map<String, dynamic>>> Function()? _loadUsersOverride;

  AppointmentProvider({
    NotificationProvider? notificationProvider,
    DatabaseService? database,
    Future<List<Map<String, dynamic>>> Function()? loadUsers,
  })  : _notificationProvider = notificationProvider ?? NotificationProvider(),
        _databaseOverride = database,
        _loadUsersOverride = loadUsers;

  Future<List<Map<String, dynamic>>> _loadUsers() =>
      _loadUsersOverride?.call() ?? UserService().getAllUsers();

  DatabaseService get _store => _databaseOverride ?? DatabaseService();

  List<Appointment> _appointments = [];

  List<Appointment> get appointments => _appointments;

  // ---- Appointment activity history (audit trail) ----
  List<AppointmentLog> _appointmentLogs = [];
  bool _isLoadingLogs = false;

  List<AppointmentLog> get appointmentLogs => _appointmentLogs;
  bool get isLoadingLogs => _isLoadingLogs;

  /// Loads the appointment activity history for the admin/clinic views.
  Future<void> loadAppointmentLogs() async {
    _isLoadingLogs = true;
    notifyListeners();
    try {
      _appointmentLogs = await _store.getAppointmentLogs();
    } catch (e) {
      debugPrint('Could not load appointment logs: $e');
    }
    _isLoadingLogs = false;
    notifyListeners();
  }

  /// Appends an immutable audit record for an appointment lifecycle action
  /// (created / updated / cancelled / completed / deleted / rebooked).
  Future<void> _logAppointmentActivity(
    Appointment appointment,
    String action, {
    String? oldStatus,
    String? details,
  }) async {
    try {
      final directory = await _userDirectory();
      final actorName = await _displayNameFor(_actorUid, directory);
      final petName = await _petNameFor(appointment.petId);
      await _store.insertAppointmentLog(AppointmentLog(
        appointmentId: appointment.appointmentId ?? '',
        petId: appointment.petId,
        ownerUid: appointment.ownerUid,
        actorUid: _actorUid,
        actorName: actorName,
        action: action,
        details: details ??
            'Pet: $petName • ${appointment.date} ${appointment.time} • '
                '${appointment.reason}',
        oldStatus: oldStatus ?? '',
        newStatus: appointment.status,
        appointmentDate: appointment.date,
        appointmentTime: appointment.time,
      ));
    } catch (e) {
      // Audit logging must never break the main appointment flow.
      debugPrint('Could not write appointment activity log: $e');
    }
  }

  Future<void> loadAppointments() async {
    _appointments = await _store.getAppointments();
    notifyListeners();
  }

  Future<String> addAppointment(Appointment appointment) async {
    final id = await _store.insertAppointment(appointment);
    appointment.appointmentId = id;
    await loadAppointments();
    await _logAppointmentActivity(appointment, 'created',
        details: 'New appointment submitted for review');
    await _notifyAppointmentCreated(appointment);
    return id;
  }

  /// Re-booking entry point: creates a fresh appointment from a finished
  /// (completed/cancelled/rejected) record. The old record is kept as
  /// history and every activity is logged for the admin audit trail.
  Future<String> rebookAppointment(Appointment appointment,
      {Appointment? previousAppointment}) async {
    final id = await _store.insertAppointment(appointment);
    appointment.appointmentId = id;
    await loadAppointments();
    await _logAppointmentActivity(
      appointment,
      'rebooked',
      oldStatus: previousAppointment?.status ?? 'completed',
      details: 'Re-booked from previous appointment '
          '(${previousAppointment?.appointmentId ?? 'n/a'})',
    );
    await _notifyAppointmentCreated(appointment);
    return id;
  }

  Future<void> updateAppointment(Appointment appointment) async {
    final previousAppointment = _appointments.firstWhere(
      (a) => a.appointmentId == appointment.appointmentId,
      orElse: () => appointment,
    );
    await _store.updateAppointment(appointment);
    await loadAppointments();
    final statusChanged = previousAppointment.status != appointment.status;
    final detailsChanged = previousAppointment.date != appointment.date ||
        previousAppointment.time != appointment.time ||
        previousAppointment.reason != appointment.reason;
    await _logAppointmentActivity(
      appointment,
      statusChanged ? 'status_changed' : 'updated',
      oldStatus: previousAppointment.status,
      details: detailsChanged
          ? 'Rescheduled/edited to ${appointment.date} ${appointment.time}'
          : (statusChanged
              ? 'Status: ${AppointmentStatus.label(previousAppointment.status)} '
                  '→ ${AppointmentStatus.label(appointment.status)}'
              : 'Record details updated'),
    );
    await _notifyAppointmentChanged(appointment, previousAppointment);
  }

  Future<void> deleteAppointment(String id, [String? cancellerName]) async {
    final appointment = _appointments.firstWhere(
      (a) => a.appointmentId == id,
      orElse: () => Appointment(
        appointmentId: id,
        petId: '',
        ownerUid: '',
        date: '',
        time: '',
        reason: '',
        status: '',
      ),
    );
    await _store.deleteAppointment(id);
    await loadAppointments();
    await _logAppointmentActivity(
      appointment,
      'deleted',
      oldStatus: appointment.status,
      details: cancellerName != null && cancellerName.isNotEmpty
          ? 'Record removed by $cancellerName'
          : 'Record removed',
    );
    await _notifyAppointmentCancelled(appointment, cancellerName);
  }

  Future<void> cancelAppointment(String id, [String? cancellerName]) async {
    final appointment = _appointments.firstWhere(
      (a) => a.appointmentId == id,
      orElse: () => Appointment(
        appointmentId: id,
        petId: '',
        ownerUid: '',
        date: '',
        time: '',
        reason: '',
        status: '',
      ),
    );
    if (!AppointmentStatus.isActive(appointment.status)) return;
    final updatedAppointment = appointment.copyWith(status: 'cancelled');
    await _store.updateAppointment(updatedAppointment);
    await loadAppointments();
    await _logAppointmentActivity(
      updatedAppointment,
      'cancelled',
      oldStatus: appointment.status,
      details: cancellerName != null && cancellerName.isNotEmpty
          ? 'Cancelled by $cancellerName'
          : 'Cancelled',
    );
    final candidate = AppointmentSlotOfferSelector.nextCandidate(
      cancelledAppointment: updatedAppointment,
      appointments: _appointments,
      now: DateTime.now(),
    );
    if (candidate != null) {
      await _persistNotification(
        recipientUid: candidate.ownerUid,
        title: 'Earlier Appointment Slot Available',
        message: 'An earlier slot is available on ${updatedAppointment.date} '
            'at ${updatedAppointment.time}. Your current appointment is on '
            '${candidate.date} at ${candidate.time}. '
            'If you would like the earlier time, contact the clinic to request '
            'the change. Your current appointment remains unchanged; '
            'the earlier slot is not reserved.',
        relatedDocumentId: candidate.appointmentId,
      );
    }
    await _notifyAppointmentCancelled(appointment, cancellerName);
  }

  Future<void> completeAppointment(
    String id,
    String vetName,
    String vetUid,
  ) async {
    final appointment = _appointments.firstWhere(
      (a) => a.appointmentId == id,
      orElse: () => Appointment(
        appointmentId: id,
        petId: '',
        ownerUid: '',
        date: '',
        time: '',
        reason: '',
        status: '',
      ),
    );
    final updatedAppointment = appointment.copyWith(
      status: 'completed',
      assignedUserId: vetUid,
    );
    await _store.updateAppointment(updatedAppointment);
    await loadAppointments();
    await _logAppointmentActivity(
      updatedAppointment,
      'completed',
      oldStatus: appointment.status,
      details: 'Visit completed by $vetName',
    );
    await _notifyAppointmentCompleted(updatedAppointment, vetName);
  }

  Future<void> assignVet(
    String appointmentId,
    String vetName,
    String vetUid,
  ) async {
    final appointment = _appointments.firstWhere(
      (a) => a.appointmentId == appointmentId,
      orElse: () => Appointment(
        appointmentId: appointmentId,
        petId: '',
        ownerUid: '',
        date: '',
        time: '',
        reason: '',
        status: '',
      ),
    );
    final updatedAppointment = appointment.copyWith(
      assignedUserId: vetUid,
      status: 'assigned',
    );
    await _store.updateAppointment(updatedAppointment);
    await loadAppointments();
    await _logAppointmentActivity(
      updatedAppointment,
      'assigned',
      oldStatus: appointment.status,
      details: 'Assigned to $vetName',
    );
    await _notifyAppointmentAssigned(updatedAppointment, vetName);
  }

  Future<void> loadAppointmentsForOwner(String ownerUid) async {
    _appointments = await DatabaseService().getAppointmentsByOwner(ownerUid);
    notifyListeners();
  }

  List<Appointment> getAppointmentsByOwner(String ownerUid) {
    return _appointments.where((a) => a.ownerUid == ownerUid).toList();
  }

  List<Appointment> getAppointmentsByPet(String petId) {
    return _appointments.where((a) => a.petId == petId).toList();
  }

  // ==========================================================
  // Appointment notifications
  //
  // Every appointment lifecycle event (created / updated / cancelled /
  // assigned / completed) now (a) writes an in-app `AppNotification`
  // record for everyone involved and (b) fires a device notification,
  // mirroring the product-order notifications.
  // ==========================================================

  /// UID of the signed-in user performing the current action.
  String get _actorUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Human readable label for an appointment status.
  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'rescheduled':
        return 'Rescheduled';
      case 'no_show':
        return 'No Show';
      case 'assigned':
        return 'Assigned';
      default:
        return status.isEmpty ? 'Updated' : status;
    }
  }

  /// Resolves a pet's display name from its id.
  Future<String> _petNameFor(String petId) async {
    if (petId.isEmpty) return 'your pet';
    try {
      final List<Pet> pets = await _store.getPets();
      final matches = pets.where((pet) => pet.petId == petId);
      if (matches.isNotEmpty && matches.first.name.trim().isNotEmpty) {
        return matches.first.name.trim();
      }
    } catch (e) {
      debugPrint('Could not resolve pet name: $e');
    }
    return 'your pet';
  }

  /// Loads the user directory once as a `uid -> name` lookup.
  ///
  /// Uses the collection list endpoint (allowed for every signed-in user)
  /// instead of reading individual documents, which the `users` security
  /// rule restricts to the owner and admins.
  Future<Map<String, String>> _userDirectory() async {
    try {
      final users = await _loadUsers();
      final directory = <String, String>{};
      for (final user in users) {
        final uid = user['uid'] as String?;
        if (uid == null || uid.isEmpty) continue;
        directory[uid] = (user['name'] as String? ?? '').trim();
      }
      return directory;
    } catch (e) {
      debugPrint('Could not load user directory: $e');
      return <String, String>{};
    }
  }

  /// Display name for [uid], falling back to a neutral label.
  Future<String> _displayNameFor(
    String uid,
    Map<String, String> directory,
  ) async {
    if (uid.isEmpty) return 'a user';
    final name = directory[uid];
    if (name != null && name.isNotEmpty) return name;
    return 'a user';
  }

  /// UIDs of every clinic-side user that should hear about appointments.
  Future<List<String>> _staffRecipientUids() async {
    try {
      final users = await _loadUsers();
      final uids = <String>[];
      for (final user in users) {
        final role = (user['role'] as String? ?? '').toLowerCase();
        if (role != 'admin' && role != 'staff' && role != 'veterinarian') {
          continue;
        }
        final uid = user['uid'] as String?;
        if (uid != null && uid.isNotEmpty) uids.add(uid);
      }
      return uids;
    } catch (e) {
      debugPrint('Could not load staff recipients: $e');
      return <String>[];
    }
  }

  /// Writes an in-app notification for [recipientUid].
  Future<void> _persistNotification({
    required String recipientUid,
    required String title,
    required String message,
    String? relatedDocumentId,
  }) async {
    if (recipientUid.isEmpty) return;
    try {
      await _store.insertNotification(
        AppNotification(
          recipientUserId: recipientUid,
          title: title,
          message: message,
          type: 'appointment',
          relatedDocumentId: relatedDocumentId,
        ),
      );
    } catch (e) {
      debugPrint('Failed to persist appointment notification: $e');
    }
  }

  /// Schedules a local reminder one hour before the slot when it is still
  /// in the future. Best effort - scheduling failures never block saving.
  Future<void> _scheduleReminder(
    Appointment appointment,
    String petName,
    String ownerName,
  ) async {
    final appointmentId = appointment.appointmentId ?? '';
    if (appointmentId.isEmpty) return;

    final status = appointment.status.toLowerCase();
    if (status == 'cancelled' ||
        status == 'completed' ||
        status == 'rejected' ||
        status == 'no_show') {
      return;
    }

    final scheduled = appointment.scheduledDateTime;
    if (scheduled.millisecondsSinceEpoch == 0) return;

    final reminderTime = scheduled.subtract(const Duration(hours: 1));
    if (!reminderTime.isAfter(DateTime.now())) return;

    try {
      await _notificationProvider.scheduleAppointmentReminder(
        appointmentId: appointmentId,
        petName: petName,
        date: appointment.date,
        time: appointment.time,
        ownerName: ownerName,
        reason: appointment.reason,
        scheduledTime: reminderTime,
      );
    } catch (e) {
      debugPrint('Appointment reminder scheduling failed: $e');
    }
  }

  /// Fires a device (local push) notification, swallowing failures so the
  /// appointment itself is never lost because of a notification problem.
  Future<void> _pushNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationProvider.showNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Appointment push notification failed: $e');
    }
  }

  /// Notifies the owner + clinic staff that an appointment was booked.
  Future<void> _notifyAppointmentCreated(Appointment appointment) async {
    final appointmentId = appointment.appointmentId ?? '';
    final petName = await _petNameFor(appointment.petId);
    final directory = await _userDirectory();
    final ownerName = await _displayNameFor(appointment.ownerUid, directory);
    final staffUids = await _staffRecipientUids();

    // Customer confirmation.
    await _persistNotification(
      recipientUid: appointment.ownerUid,
      title: 'Appointment Submitted',
      message: 'Your appointment for $petName on ${appointment.date} at '
          '${appointment.time} was received. We will notify you once it is '
          'scheduled.',
      relatedDocumentId: appointmentId,
    );

    // Front-desk / vet feed.
    final staffMessage = '$ownerName requested an appointment for $petName on '
        '${appointment.date} at ${appointment.time}';
    for (final uid in staffUids) {
      if (uid == _actorUid) continue;
      await _persistNotification(
        recipientUid: uid,
        title: 'New Appointment Request',
        message: staffMessage,
        relatedDocumentId: appointmentId,
      );
    }

    try {
      await _notificationProvider.showAppointmentCreated(
        appointmentId: appointmentId,
        petName: petName,
        ownerName: ownerName,
        date: appointment.date,
        time: appointment.time,
      );
    } catch (e) {
      debugPrint('Appointment created notification failed: $e');
    }

    await _scheduleReminder(appointment, petName, ownerName);
  }

  /// Dispatches the right notification for an appointment edit.
  Future<void> _notifyAppointmentChanged(
    Appointment updated,
    Appointment previous,
  ) async {
    final statusChanged =
        updated.status.toLowerCase() != previous.status.toLowerCase();

    // Route dedicated status transitions to their own notification flows.
    if (statusChanged && updated.status.toLowerCase() == 'cancelled') {
      await _notifyAppointmentCancelled(previous, null);
      return;
    }
    if (statusChanged && updated.status.toLowerCase() == 'rejected') {
      await _notifyAppointmentRejected(updated, previous);
      return;
    }
    if (statusChanged && updated.status.toLowerCase() == 'confirmed') {
      await _notifyAppointmentConfirmed(updated, previous);
      return;
    }
    if (statusChanged && updated.status.toLowerCase() == 'completed') {
      final directory = await _userDirectory();
      final vetName = await _displayNameFor(
        updated.assignedUserId ?? _actorUid,
        directory,
      );
      await _notifyAppointmentCompleted(updated, vetName);
      return;
    }

    final assignedChanged =
        (updated.assignedUserId ?? '') != (previous.assignedUserId ?? '');
    if (assignedChanged && (updated.assignedUserId ?? '').isNotEmpty) {
      final directory = await _userDirectory();
      final vetName = await _displayNameFor(updated.assignedUserId!, directory);
      await _notifyAppointmentAssigned(updated, vetName);
      return;
    }

    await _notifyAppointmentEdited(updated, previous, statusChanged);
  }

  /// Handles plain edits: reschedules, status changes and reason changes.
  Future<void> _notifyAppointmentEdited(
    Appointment updated,
    Appointment previous,
    bool statusChanged,
  ) async {
    final timeChanged =
        updated.date != previous.date || updated.time != previous.time;
    final reasonChanged = updated.reason != previous.reason;
    if (!timeChanged && !reasonChanged && !statusChanged) return;

    final appointmentId = updated.appointmentId ?? previous.appointmentId ?? '';
    final petName = await _petNameFor(updated.petId);
    final directory = await _userDirectory();
    final actorName = await _displayNameFor(_actorUid, directory);
    final staffUids = await _staffRecipientUids();

    final staffMessage = timeChanged
        ? '$actorName rescheduled $petName from ${previous.date} '
            '${previous.time} to ${updated.date} at ${updated.time}'
        : '$actorName updated the appointment for $petName '
            '(${_statusLabel(updated.status)})';

    for (final uid in staffUids) {
      if (uid == _actorUid) continue;
      await _persistNotification(
        recipientUid: uid,
        title: timeChanged ? 'Appointment Rescheduled' : 'Appointment Updated',
        message: staffMessage,
        relatedDocumentId: appointmentId,
      );
    }

    // Keep the pet owner informed about their own appointment.
    await _persistNotification(
      recipientUid: updated.ownerUid,
      title: 'Appointment ${_statusLabel(updated.status)}',
      message: timeChanged
          ? 'Your appointment for $petName was moved to ${updated.date} at '
              '${updated.time}.'
          : 'Your appointment for $petName on ${updated.date} at '
              '${updated.time} is now ${_statusLabel(updated.status)}.',
      relatedDocumentId: appointmentId,
    );

    if (timeChanged && appointmentId.isNotEmpty) {
      try {
        await _notificationProvider.showAppointmentChanged(
          appointmentId: appointmentId,
          petName: petName,
          changerName: actorName,
          newDate: updated.date,
          newTime: updated.time,
          oldDate: previous.date,
          oldTime: previous.time,
        );
        await _scheduleReminder(updated, petName, actorName);
      } catch (e) {
        debugPrint('Appointment changed notification failed: $e');
      }
    } else {
      await _pushNotification(
        title: 'Appointment ${_statusLabel(updated.status)}',
        body: 'The appointment for $petName on ${updated.date} at '
            '${updated.time} is now ${_statusLabel(updated.status)}.',
        payload: 'appointment:$appointmentId',
      );
    }
  }

  /// Broadcasts an appointment cancellation to owner, vet and staff.
  Future<void> _notifyAppointmentCancelled(
    Appointment appointment,
    String? cancellerName,
  ) async {
    final appointmentId = appointment.appointmentId ?? '';
    final petName = await _petNameFor(appointment.petId);
    final directory = await _userDirectory();
    final actorName = (cancellerName ?? '').trim().isNotEmpty
        ? cancellerName!.trim()
        : await _displayNameFor(_actorUid, directory);
    final staffUids = await _staffRecipientUids();

    final message = '$actorName cancelled the appointment for $petName on '
        '${appointment.date} at ${appointment.time}';

    final recipients = <String>{
      appointment.ownerUid,
      if ((appointment.assignedUserId ?? '').isNotEmpty)
        appointment.assignedUserId!,
      ...staffUids,
    };

    for (final uid in recipients) {
      await _persistNotification(
        recipientUid: uid,
        title: 'Appointment Cancelled',
        message: message,
        relatedDocumentId: appointmentId,
      );
    }

    try {
      await _notificationProvider.showAppointmentCancelled(
        appointmentId: appointmentId,
        petName: petName,
        cancellerName: actorName,
        date: appointment.date,
        time: appointment.time,
      );
      if (appointmentId.isNotEmpty) {
        await _notificationProvider.cancelAppointmentReminder(appointmentId);
      }
    } catch (e) {
      debugPrint('Appointment cancelled notification failed: $e');
    }
  }

  /// Broadcasts that a pending appointment was accepted/confirmed.
  Future<void> _notifyAppointmentConfirmed(
    Appointment appointment,
    Appointment previous,
  ) async {
    final appointmentId =
        appointment.appointmentId ?? previous.appointmentId ?? '';
    final petName = await _petNameFor(appointment.petId);
    final directory = await _userDirectory();
    final actorName = await _displayNameFor(_actorUid, directory);
    final assigneeUid = appointment.assignedUserId ?? '';
    final staffUids = await _staffRecipientUids();

    // The pet owner is the one who needs to know.
    await _persistNotification(
      recipientUid: appointment.ownerUid,
      title: 'Appointment Scheduled',
      message: 'Your appointment for $petName on ${appointment.date} at '
          '${appointment.time} has been scheduled.',
      relatedDocumentId: appointmentId,
    );

    // Keep the vet handling the case and the front desk in the loop.
    for (final uid in {...staffUids, if (assigneeUid.isNotEmpty) assigneeUid}) {
      if (uid == _actorUid) continue;
      await _persistNotification(
        recipientUid: uid,
        title: 'Appointment Scheduled',
        message: '$actorName scheduled $petName\'s appointment for '
            '${appointment.date} at ${appointment.time}.',
        relatedDocumentId: appointmentId,
      );
    }

    try {
      await _notificationProvider.showAppointmentConfirmed(
        appointmentId: appointmentId,
        petName: petName,
        date: appointment.date,
        time: appointment.time,
      );
      await _scheduleReminder(appointment, petName, actorName);
    } catch (e) {
      debugPrint('Appointment confirmed notification failed: $e');
    }
  }

  /// Broadcasts that a requested appointment was rejected.
  Future<void> _notifyAppointmentRejected(
    Appointment appointment,
    Appointment previous,
  ) async {
    final appointmentId =
        appointment.appointmentId ?? previous.appointmentId ?? '';
    final petName = await _petNameFor(appointment.petId);
    final directory = await _userDirectory();
    final actorName = await _displayNameFor(_actorUid, directory);
    final staffUids = await _staffRecipientUids();

    // The rejection reason is appended to the reason field by the UI.
    final match =
        RegExp(r'\[REJECTED:\s*(.+?)\]').firstMatch(appointment.reason);
    final rejectionReason = match?.group(1)?.trim() ?? '';
    final suffix = rejectionReason.isEmpty ? '' : ' Reason: $rejectionReason';

    await _persistNotification(
      recipientUid: appointment.ownerUid,
      title: 'Appointment Rejected',
      message: 'Your appointment for $petName on ${appointment.date} at '
          '${appointment.time} was rejected.$suffix',
      relatedDocumentId: appointmentId,
    );

    for (final uid in staffUids) {
      if (uid == _actorUid) continue;
      await _persistNotification(
        recipientUid: uid,
        title: 'Appointment Rejected',
        message: '$actorName rejected $petName\'s appointment for '
            '${appointment.date} at ${appointment.time}.$suffix',
        relatedDocumentId: appointmentId,
      );
    }

    try {
      await _notificationProvider.showAppointmentRejected(
        appointmentId: appointmentId,
        petName: petName,
        date: appointment.date,
        reason: rejectionReason,
      );
      if (appointmentId.isNotEmpty) {
        await _notificationProvider.cancelAppointmentReminder(appointmentId);
      }
    } catch (e) {
      debugPrint('Appointment rejected notification failed: $e');
    }
  }

  /// Broadcasts that an appointment was completed.
  Future<void> _notifyAppointmentCompleted(
    Appointment appointment,
    String vetName,
  ) async {
    final appointmentId = appointment.appointmentId ?? '';
    final petName = await _petNameFor(appointment.petId);
    final staffUids = await _staffRecipientUids();

    final message = 'The appointment for $petName with $vetName on '
        '${appointment.date} has been completed';

    final recipients = <String>{appointment.ownerUid, ...staffUids};

    for (final uid in recipients) {
      await _persistNotification(
        recipientUid: uid,
        title: 'Appointment Completed',
        message: message,
        relatedDocumentId: appointmentId,
      );
    }

    try {
      await _notificationProvider.showAppointmentCompleted(
        appointmentId: appointmentId,
        petName: petName,
        vetName: vetName,
        date: appointment.date,
      );
      if (appointmentId.isNotEmpty) {
        await _notificationProvider.cancelAppointmentReminder(appointmentId);
      }
    } catch (e) {
      debugPrint('Appointment completed notification failed: $e');
    }
  }

  /// Broadcasts that a veterinarian was assigned to an appointment.
  Future<void> _notifyAppointmentAssigned(
    Appointment appointment,
    String vetName,
  ) async {
    final appointmentId = appointment.appointmentId ?? '';
    final petName = await _petNameFor(appointment.petId);
    final vetUid = appointment.assignedUserId ?? '';
    final staffUids = await _staffRecipientUids();

    // The assigned veterinarian.
    await _persistNotification(
      recipientUid: vetUid,
      title: 'New Appointment Assigned',
      message: 'You have been assigned to $petName on ${appointment.date} at '
          '${appointment.time}.',
      relatedDocumentId: appointmentId,
    );

    // The pet owner.
    await _persistNotification(
      recipientUid: appointment.ownerUid,
      title: 'Veterinarian Assigned',
      message: '$vetName will be handling $petName\'s appointment on '
          '${appointment.date} at ${appointment.time}.',
      relatedDocumentId: appointmentId,
    );

    // Front-desk feed.
    for (final uid in staffUids) {
      if (uid == _actorUid || uid == vetUid) continue;
      await _persistNotification(
        recipientUid: uid,
        title: 'Appointment Assigned',
        message: '$vetName has been assigned to $petName on '
            '${appointment.date} at ${appointment.time}.',
        relatedDocumentId: appointmentId,
      );
    }

    try {
      await _notificationProvider.showAppointmentAssigned(
        appointmentId: appointmentId,
        petName: petName,
        vetName: vetName,
        date: appointment.date,
        time: appointment.time,
      );
    } catch (e) {
      debugPrint('Appointment assigned notification failed: $e');
    }
  }
}
