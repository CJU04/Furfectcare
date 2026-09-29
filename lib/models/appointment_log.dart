/// Immutable audit record for every appointment lifecycle activity:
/// created, updated, cancelled, completed, rejected, deleted and rebooked.
/// Admins review these from the Appointment Management screen so every
/// re-booking / cancel-and-submit-again activity has a record history.
class AppointmentLog {
  String? logId;
  String appointmentId;
  String petId;
  String ownerUid;
  String actorUid;
  String actorName;
  String action;
  String details;
  String oldStatus;
  String newStatus;
  String appointmentDate;
  String appointmentTime;
  DateTime createdAt;

  AppointmentLog({
    this.logId,
    required this.appointmentId,
    required this.petId,
    required this.ownerUid,
    required this.actorUid,
    this.actorName = '',
    required this.action,
    this.details = '',
    this.oldStatus = '',
    this.newStatus = '',
    this.appointmentDate = '',
    this.appointmentTime = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'appointmentId': appointmentId,
      'petId': petId,
      'ownerUid': ownerUid,
      'actorUid': actorUid,
      'actorName': actorName,
      'action': action,
      'details': details,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppointmentLog.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return AppointmentLog(
      logId: docId ?? map['logId'] as String?,
      appointmentId: map['appointmentId'] as String? ?? '',
      petId: map['petId'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      actorUid: map['actorUid'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      action: map['action'] as String? ?? 'updated',
      details: map['details'] as String? ?? '',
      oldStatus: map['oldStatus'] as String? ?? '',
      newStatus: map['newStatus'] as String? ?? '',
      appointmentDate: map['appointmentDate'] as String? ?? '',
      appointmentTime: map['appointmentTime'] as String? ?? '',
      createdAt: parsedDate,
    );
  }
}
