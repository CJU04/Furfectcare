import 'package:flutter_test/flutter_test.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/models/user.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/notification_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';

class _MemoryDatabase extends Fake implements DatabaseService {
  final List<Appointment> records;
  final notifications = <AppNotification>[];
  _MemoryDatabase(this.records);

  @override
  Future<List<Appointment>> getAppointments() async => List.of(records);

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    final index = records.indexWhere(
      (record) => record.appointmentId == appointment.appointmentId,
    );
    if (index < 0) throw StateError('Appointment not found');
    records[index] = appointment;
  }

  @override
  Future<List<Pet>> getPets() async => [];

  @override
  Future<String> insertNotification(AppNotification notification) async {
    notifications.add(notification);
    return 'notification-${notifications.length}';
  }

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId) async =>
      notifications.where((n) => n.recipientUserId == userId).toList();
}

class _LocalNotifications extends Fake implements NotificationProvider {
  @override
  Future<void> showAppointmentCancelled({
    required String appointmentId,
    required String petName,
    required String cancellerName,
    required String date,
    required String time,
  }) async {}

  @override
  Future<void> cancelAppointmentReminder(String appointmentId) async {}
}

void main() {
  test('cancellation persists a recommendation for only the next customer',
      () async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final date = tomorrow.toIso8601String().split('T').first;
    Appointment booking(String id, String time) => Appointment(
          appointmentId: id,
          ownerUid: 'owner-$id',
          petId: 'pet-$id',
          date: date,
          time: time,
          reason: 'Checkup',
          status: 'confirmed',
        );
    final database = _MemoryDatabase([
      booking('cancelled', '09:00'),
      booking('later', '11:00'),
      booking('next', '09:30'),
    ]);
    final provider = AppointmentProvider(
      database: database,
      notificationProvider: _LocalNotifications(),
      loadUsers: () async => [],
    );
    addTearDown(provider.dispose);
    await provider.loadAppointments();
    await provider.cancelAppointment('cancelled', 'Customer');

    expect(database.records.first.status, 'cancelled');
    final inbox = await database.getNotificationsForUser('owner-next');
    expect(inbox, hasLength(1));
    expect(inbox.single.title, 'Earlier Appointment Slot Available');
    expect(inbox.single.type, 'appointment');
    expect(inbox.single.relatedDocumentId, 'next');
    expect(inbox.single.isRead, isFalse);
    expect(inbox.single.message, contains(date));
    expect(inbox.single.message, contains('09:00'));
    expect(inbox.single.message, contains('09:30'));
    expect(inbox.single.message, contains('not reserved'));
    expect(await database.getNotificationsForUser('owner-later'), isEmpty);
    expect(database.records.last.time, '09:30');
    expect(provider.appointments.first.status, 'cancelled');

    // Repeating cancellation on the same loaded state must not offer twice.
    await provider.cancelAppointment('cancelled', 'Customer');
    expect(await database.getNotificationsForUser('owner-next'), hasLength(1));
  });
}
