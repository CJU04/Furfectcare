/// Canonical appointment statuses. Scheduled and confirmed were redundant
/// ("scheduled" == "confirmed"), as were rejected and cancelled variants, so
/// the whole system now uses exactly these five values.
class AppointmentStatus {
  AppointmentStatus._();

  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String rejected = 'rejected';

  static const List<String> all = [
    pending,
    confirmed,
    completed,
    cancelled,
    rejected,
  ];

  /// Legacy rows may still contain 'scheduled' — treat it as confirmed.
  static String normalize(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'scheduled') return confirmed;
    if (v == 'cancel' || v == 'canceled') return cancelled;
    if (v == 'reject') return rejected;
    if (v == 'complete' || v == 'done') return completed;
    if (v == 'confirm' || v == 'accepted') return confirmed;
    if (all.contains(v)) return v;
    return pending;
  }

  static bool get isTerminal {
    return true; // helper kept for readability in call sites
  }

  static bool isActive(String status) {
    final s = normalize(status);
    return s == pending || s == confirmed;
  }

  static bool isFinished(String status) {
    final s = normalize(status);
    return s == completed || s == cancelled || s == rejected;
  }

  static String label(String status) {
    switch (normalize(status)) {
      case pending:
        return 'Pending';
      case confirmed:
        return 'Scheduled';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case rejected:
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}

/// Shortest-Time-First (STF / greedy) scheduler for appointment queues.
///
/// Greedy rule: at any moment, among the currently-available (active)
/// appointments pick the one with the earliest start time first. Each visit
/// is assumed to occupy a fixed 30-minute service window, so back-to-back
/// bookings never overlap. Finished records (completed/cancelled/rejected)
/// are always pushed to the bottom, grouped behind a separator, per request.
/// Active records stay on top in STF order; pending requests sit right after
/// confirmed ones because they still need staff action.
class AppointmentScheduler {
  AppointmentScheduler._();

  static const Duration slotLength = Duration(minutes: 30);

  static int _rank(String status) {
    switch (AppointmentStatus.normalize(status)) {
      case AppointmentStatus.confirmed:
        return 0;
      case AppointmentStatus.pending:
        return 1;
      case AppointmentStatus.completed:
        return 2;
      case AppointmentStatus.cancelled:
        return 3;
      case AppointmentStatus.rejected:
        return 4;
      default:
        return 1;
    }
  }

  /// Greedy STF order: active first (confirmed before pending), each group
  /// sorted by scheduledDateTime; terminal records sink to the bottom.
  static List<T> greedyOrder<T>(
    List<T> items, {
    required DateTime Function(T) startTime,
    required String Function(T) statusOf,
  }) {
    final sorted = List<T>.from(items);
    sorted.sort((a, b) {
      final ra = _rank(statusOf(a));
      final rb = _rank(statusOf(b));
      if (ra != rb) return ra.compareTo(rb);
      return startTime(a).compareTo(startTime(b));
    });
    return sorted;
  }

  /// True when [candidateStart] overlaps any active booking on the same day.
  static bool overlaps({
    required DateTime candidateStart,
    required List<DateTime> activeStarts,
  }) {
    final candidateEnd = candidateStart.add(slotLength);
    for (final s in activeStarts) {
      final e = s.add(slotLength);
      if (candidateStart.isBefore(e) && s.isBefore(candidateEnd)) return true;
    }
    return false;
  }

  /// Suggests the next free 30-min slot between 08:00-16:00 on [day].
  static DateTime? nextFreeSlot({
    required DateTime day,
    required List<DateTime> activeStarts,
    int maxPerDay = 16,
  }) {
    DateTime slot = DateTime(day.year, day.month, day.day, 8, 0);
    final end = DateTime(day.year, day.month, day.day, 16, 0);
    int checked = 0;
    while (!slot.isAfter(end) && checked < maxPerDay) {
      if (!overlaps(candidateStart: slot, activeStarts: activeStarts)) {
        return slot;
      }
      slot = slot.add(slotLength);
      checked++;
    }
    return null;
  }
}
