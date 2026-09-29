import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/medical_history_provider.dart';
import 'package:vetcare_connect/providers/notification_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/views/screens/appointment_management_screen.dart';

class _MemoryDatabase extends Fake implements DatabaseService {
  final appointments = [
    Appointment(
      appointmentId: 'appt-bella',
      petId: 'pet-bella',
      ownerUid: 'owner',
      date: '2026-09-20',
      time: '09:00',
      reason: 'Bella checkup',
      status: 'confirmed',
    ),
    Appointment(
      appointmentId: 'appt-coco',
      petId: 'pet-coco',
      ownerUid: 'owner',
      date: '2026-09-21',
      time: '10:00',
      reason: 'Coco grooming',
      status: 'pending',
    ),
  ];

  @override
  Future<List<Appointment>> getAppointments() async => appointments;
}

class _NoopPetProvider extends PetProvider {
  @override
  Future<void> loadPets() async {}
}

class _NoopHistoryProvider extends MedicalHistoryProvider {
  @override
  Future<void> loadMedicalHistories() async {}
}

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'owner';
  @override
  String get email => 'owner@example.com';
  @override
  String? get photoURL => null;
}

/// Real ChangeNotifier subclasses so Provider can listen; only the getters
/// the screen reads are overridden. Fakes would throw on addListener, and
/// the real AuthProvider constructor touches FirebaseAuth.instance.
class _StubAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  User? get firebaseUser => _FakeUser();
  @override
  UserRole? get role => UserRole.customer;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubUserProvider extends ChangeNotifier implements FirebaseUserProvider {
  @override
  FirebaseUser? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Never interacted with during loadAppointments; a fake avoids the real
/// NotificationService touching FirebaseMessaging.instance.
class _StubNotificationProvider extends Fake implements NotificationProvider {}

void main() {
  testWidgets('Deep-linked appointment shows only the related record',
      (tester) async {
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
              value: _StubAuthProvider()),
          ChangeNotifierProvider<FirebaseUserProvider>.value(
              value: _StubUserProvider()),
          ChangeNotifierProvider<PetProvider>.value(value: _NoopPetProvider()),
          ChangeNotifierProvider<MedicalHistoryProvider>.value(
              value: _NoopHistoryProvider()),
          ChangeNotifierProvider(
            create: (_) => AppointmentProvider(
              database: _MemoryDatabase(),
              notificationProvider: _StubNotificationProvider(),
            ),
          ),
        ],
        child: const MaterialApp(
            home: AppointmentManagementScreen(recordId: 'appt-coco'))));

    await tester.pumpAndSettle();
    expect(find.text('Coco grooming'), findsOneWidget);
    expect(find.text('Bella checkup'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
