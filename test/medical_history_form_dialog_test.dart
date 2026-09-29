import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/models/medical_history.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';
import 'package:vetcare_connect/views/widgets/medical_history_form_dialog.dart';

final pets = [
  for (final id in ['Bella', 'Coco'])
    Pet(
      petId: id,
      ownerUid: 'owner',
      name: id,
      type: 'Dog',
      breed: 'Beagle',
      age: 3,
      gender: 'Female',
      vaccinationStatus: 'Vaccinated',
      healthNotes: '$id notes',
    )
];
final appointments = [
  Appointment(
    appointmentId: 'a1',
    petId: 'Bella',
    ownerUid: 'owner',
    date: '2020-01-01',
    time: '10:00',
    reason: 'Checkup',
    status: 'completed',
  )
];
MedicalHistory record({String date = '2020-01-01'}) => MedicalHistory(
      historyId: 'h1',
      petId: 'Bella',
      appointmentId: 'a1',
      date: date,
      diagnosis: 'Finding',
      treatment: 'Treatment plan',
      notes: 'Notes',
      fuzzyConcernLevel: 'Low',
    );
Future<void> open(
  WidgetTester tester, {
  MedicalHistory? history,
  required Future<void> Function(MedicalHistory, PickedFileData?) save,
}) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Builder(
    builder: (context) => TextButton(
        onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => MedicalHistoryFormDialog(
                pets: pets,
                appointments: appointments,
                history: history,
                onSave: save,
              ),
            ),
        child: const Text('Open')),
  ))));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);
Future<void> selectPet(WidgetTester tester, String name) async {
  final dropdown = find.byType(DropdownButtonFormField<String>).first;
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('$name (Dog)').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('blank form blocks saving with inline errors', (tester) async {
    var calls = 0;
    await open(tester, save: (record, attachment) async {
      calls++;
    });
    await tester.tap(find.text('Add record'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('This field is required.'), findsNWidgets(4));
    expect(
        find.text('Select an appointment to fill the date.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'pet selection fills context, clears stale appointment and findings',
      (tester) async {
    await open(tester, history: record(), save: (record, attachment) async {});
    await selectPet(tester, 'Coco');
    expect(
        tester.widget<TextFormField>(field('Diagnosis')).controller!.text, '');
    expect(
        tester.widget<TextFormField>(field('Treatment')).controller!.text, '');
    expect(
        tester
            .widget<TextFormField>(field('Record date (YYYY-MM-DD)'))
            .controller!
            .text,
        '');
    expect(
        find.text('No appointments for this pet. Book an appointment first.'),
        findsOneWidget);
    await selectPet(tester, 'Bella');
    expect(
        tester
            .widget<TextFormField>(field('Record date (YYYY-MM-DD)'))
            .controller!
            .text,
        '2020-01-01');
    expect(
        tester
            .widget<TextFormField>(field('Additional notes'))
            .controller!
            .text,
        'Bella notes');
    expect(
        tester.widget<TextFormField>(field('Diagnosis')).controller!.text, '');
    expect(tester.takeException(), isNull);
  });
  for (final date in ['2020-02-30', 'invalid', '2999-01-01']) {
    testWidgets('invalid date $date prevents save', (tester) async {
      var calls = 0;
      await open(tester, history: record(date: date),
          save: (record, attachment) async {
        calls++;
      });
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Edit Medical History'), findsOneWidget);
    });
  }
  testWidgets('failed save stays open, retry preserves record and closes',
      (tester) async {
    var calls = 0;
    MedicalHistory? saved;
    final completion = Completer<void>();
    await open(tester, history: record(), save: (value, _) async {
      calls++;
      if (calls == 1) throw Exception('Upload unavailable. Retry.');
      saved = value;
      await completion.future;
    });
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Upload unavailable. Retry.'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    completion.complete();
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(saved!.historyId, 'h1');
    expect(saved!.fuzzyConcernLevel, 'Low');
    expect(find.text('Edit Medical History'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
