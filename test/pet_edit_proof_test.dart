import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/views/screens/pet_management_screen.dart';

class TestAuth extends ChangeNotifier implements AuthProvider {
  @override
  UserRole? get role => UserRole.admin;
  @override
  get firebaseUser => null;
  @override
  String? get displayName => 'Admin';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestUsers extends ChangeNotifier implements FirebaseUserProvider {
  @override
  FirebaseUser? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPets extends PetProvider {
  final Pet pet;
  Pet? saved;
  TestPets(this.pet);
  @override
  List<Pet> get pets => [pet];
  @override
  Future<void> loadPets() async {}
  @override
  Future<void> updatePet(Pet pet) async {
    saved = pet;
  }
}

void main() {
  testWidgets('Edit Pet shows attachment and preserves existing proof on save',
      (tester) async {
    final pets = TestPets(Pet(
      petId: 'pet-1',
      ownerUid: 'owner-1',
      name: 'Milo',
      type: 'Dog',
      breed: 'Mixed',
      age: 2,
      gender: 'Male',
      vaccinationStatus: 'Up to date',
      healthNotes: '',
      vaccinationProofUrl: 'https://example.com/proof.pdf',
    ));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => TestAuth()),
        ChangeNotifierProvider<FirebaseUserProvider>(
            create: (_) => TestUsers()),
        ChangeNotifierProvider<PetProvider>.value(value: pets),
      ],
      child: const MaterialApp(home: PetManagementScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.text('Attach vaccination/booster proof'), findsOneWidget);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(pets.saved?.vaccinationProofUrl, 'https://example.com/proof.pdf');
    expect(pets.saved?.petId, 'pet-1');
    expect(pets.saved?.ownerUid, 'owner-1');
    expect(find.text('Edit Pet'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
