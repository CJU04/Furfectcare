class Appointment {
  String? appointmentId;
  String petId; // FK to Pet.petId
  String ownerUid; // FK to FirebaseUser.uid (customer who booked)
  String? assignedUserId; // FK to FirebaseUser.uid (staff/vet assigned)
  String date;
  String time;
  String reason;
  String status;

  Appointment({
    this.appointmentId,
    required this.petId,
    required this.ownerUid,
    this.assignedUserId,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'ownerUid': ownerUid,
      'assignedUserId': assignedUserId,
      'date': date,
      'time': time,
      'reason': reason,
      'status': status,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      appointmentId: map['appointmentId'] as String?,
      petId: map['petId'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      assignedUserId: map['assignedUserId'] as String?,
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      status: map['status'] as String? ?? '',
    );
  }

  Appointment copyWith({
    String? appointmentId,
    String? petId,
    String? ownerUid,
    String? assignedUserId,
    String? date,
    String? time,
    String? reason,
    String? status,
  }) {
    return Appointment(
      appointmentId: appointmentId ?? this.appointmentId,
      petId: petId ?? this.petId,
      ownerUid: ownerUid ?? this.ownerUid,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      date: date ?? this.date,
      time: time ?? this.time,
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  /// Parses the stored [date] (+ optional [time]) into a DateTime for
  /// sorting/searching. The `date` field is stored as a plain `yyyy-MM-dd`
  /// string (or ISO-8601 in legacy rows) so this handles both, and any
  /// failure falls back to a sortable sentinel instead of crashing.
  static DateTime _parseDateValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Combined sortable timestamp using date + time ("HH:mm").
  DateTime get scheduledDateTime {
    final d = _parseDateValue(date);
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})').firstMatch(time);
    if (match != null) {
      return DateTime(d.year, d.month, d.day, int.parse(match.group(1)!),
          int.parse(match.group(2)!));
    }
    return d;
  }

  /// True when this appointment starts sometime today (local time).
  bool get isToday {
    final d = _parseDateValue(date);
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}
