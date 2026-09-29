import '../models/appointment.dart';
import 'appointment_scheduling.dart';

/// Pure selection logic for an earlier-slot offer. This does not reserve a slot:
/// the booking service must recheck availability atomically on acceptance.
class AppointmentSlotOfferSelector {
  AppointmentSlotOfferSelector._();

  /// Returns the earliest eligible later appointment on the same clinic day.
  ///
  /// Pass a fresh snapshot after cancellation. A stale active source appointment
  /// intentionally blocks an offer rather than advertising an occupied slot.
  /// [declinedOwnerUids] applies to this freed slot, not to future offers.
  static Appointment? nextCandidate({
    required Appointment cancelledAppointment,
    required List<Appointment> appointments,
    required DateTime now,
    Set<String> declinedOwnerUids = const <String>{},
  }) {
    final slot = _offerableSlot(cancelledAppointment, now);
    if (slot == null) return null;

    final activeStarts = _activeStartsOrNullIfUncertain(
      appointments,
      _dateKey(cancelledAppointment),
    );
    if (activeStarts == null) return null;
    if (AppointmentScheduler.overlaps(
      candidateStart: slot,
      activeStarts: activeStarts,
    )) {
      return null;
    }

    final candidates = appointments
        .where((appointment) => _isEligibleCandidate(
              appointment: appointment,
              cancelledAppointment: cancelledAppointment,
              freedSlot: slot,
              declinedOwnerUids: declinedOwnerUids,
            ))
        .toList();

    return _earliest(candidates);
  }

  // Unlike the model's display fallback, offer selection must reject invalid
  // dates/times instead of silently rolling them into another day or midnight.
  static DateTime? _validStart(Appointment appointment) {
    final dateText = _dateKey(appointment);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText)) return null;
    final date = DateTime.tryParse(dateText);
    if (date == null || date.toIso8601String().split('T').first != dateText) {
      return null;
    }
    final time =
        RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(appointment.time.trim());
    if (time == null) return null;
    final hour = int.parse(time.group(1)!);
    final minute = int.parse(time.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Shared date-key: plain `yyyy-MM-dd` day, tolerating legacy ISO rows.
  /// Extracted to replace two copies of `trim().split('T').first`.
  static String _dateKey(Appointment appointment) =>
      appointment.date.trim().split('T').first;

  /// Named intermediate concept: the freed slot is only offerable when the
  /// source snapshot is cancelled, parses cleanly, and lies in the future.
  static DateTime? _offerableSlot(
    Appointment cancelledAppointment,
    DateTime now,
  ) {
    if (AppointmentStatus.normalize(cancelledAppointment.status) !=
        AppointmentStatus.cancelled) {
      return null;
    }
    final slot = _validStart(cancelledAppointment);
    if (slot == null || !slot.isAfter(now)) return null;
    return slot;
  }

  /// Collects active starts; returns null when availability is uncertain
  /// (a malformed active booking on the same clinic day blocks an offer).
  static List<DateTime>? _activeStartsOrNullIfUncertain(
    List<Appointment> appointments,
    String freedDateKey,
  ) {
    final activeStarts = <DateTime>[];
    for (final appointment in appointments) {
      if (!AppointmentStatus.isActive(appointment.status)) continue;
      final start = _validStart(appointment);
      if (start == null) {
        if (_dateKey(appointment) == freedDateKey) return null;
        continue;
      }
      activeStarts.add(start);
    }
    return activeStarts;
  }

  static bool _isEligibleCandidate({
    required Appointment appointment,
    required Appointment cancelledAppointment,
    required DateTime freedSlot,
    required Set<String> declinedOwnerUids,
  }) {
    if (AppointmentStatus.normalize(appointment.status) !=
        AppointmentStatus.confirmed) {
      return false;
    }
    if ((appointment.appointmentId ?? '').trim().isEmpty) return false;
    if (appointment.appointmentId == cancelledAppointment.appointmentId) {
      return false;
    }
    if (appointment.ownerUid.trim().isEmpty) return false;
    if (appointment.ownerUid == cancelledAppointment.ownerUid) return false;
    if (declinedOwnerUids.contains(appointment.ownerUid)) return false;
    final start = _validStart(appointment);
    if (start == null) return false;
    final sameDay = start.year == freedSlot.year &&
        start.month == freedSlot.month &&
        start.day == freedSlot.day;
    if (!sameDay) return false;
    return !start.isBefore(freedSlot.add(AppointmentScheduler.slotLength));
  }

  static Appointment? _earliest(List<Appointment> candidates) {
    candidates.sort((a, b) {
      final timeOrder = a.scheduledDateTime.compareTo(b.scheduledDateTime);
      return timeOrder != 0
          ? timeOrder
          : a.appointmentId!.compareTo(b.appointmentId!);
    });
    return candidates.isEmpty ? null : candidates.first;
  }
}
