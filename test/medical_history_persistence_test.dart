import 'package:flutter_test/flutter_test.dart';
import 'package:vetcare_connect/models/medical_history.dart';
import 'package:vetcare_connect/providers/medical_history_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';

import 'medical_history_form_dialog_test.dart' as form;

class MemoryMedicalDatabase extends Fake implements DatabaseService {
  final records = <String, Map<String, dynamic>>{};
  int inserts = 0;
  bool readsFail = true;

  @override
  Future<String> insertMedicalHistory(MedicalHistory history) async {
    final id = 'history-${++inserts}';
    records[id] = history.copyWith(historyId: id).toMap();
    return id;
  }

  @override
  Future<List<MedicalHistory>> getMedicalHistories() async {
    if (readsFail) throw StateError('Read temporarily unavailable');
    return records.values.map(MedicalHistory.fromMap).toList();
  }

  @override
  Future<void> updateMedicalHistory(MedicalHistory history) async {
    if (!records.containsKey(history.historyId))
      throw StateError('Missing record');
    records[history.historyId!] = history.toMap();
  }
}

void main() {
  testWidgets(
      'Add record persists selected fields even when subsequent reads fail',
      (tester) async {
    final database = MemoryMedicalDatabase();
    final provider = MedicalHistoryProvider(database: database);
    addTearDown(provider.dispose);
    String? id;
    await form.open(tester, save: (record, attachment) async {
      expect(attachment, isNull);
      id = await provider.addMedicalHistory(record);
    });
    await form.selectPet(tester, 'Bella');
    await tester.ensureVisible(form.field('Diagnosis'));
    await tester.enterText(form.field('Diagnosis'), '  Clinical finding  ');
    await tester.ensureVisible(form.field('Treatment'));
    await tester.enterText(form.field('Treatment'), '  Follow-up plan  ');
    await tester.tap(find.text('Add record'));
    await tester.pumpAndSettle();

    expect(id, 'history-1');
    expect(database.inserts, 1);
    expect(find.text('Add Medical History'), findsNothing);
    expect(provider.medicalHistories.single.historyId, id);
    database.readsFail = false;
    await provider.loadMedicalHistories();
    final stored = provider.medicalHistories.single;
    expect(stored.petId, 'Bella');
    expect(stored.appointmentId, 'a1');
    expect(stored.date, '2020-01-01');
    expect(stored.diagnosis, 'Clinical finding');
    expect(stored.treatment, 'Follow-up plan');
    expect(stored.notes, 'Bella notes');

    database.readsFail = true;
    await provider
        .updateMedicalHistory(stored.copyWith(notes: 'Attachment retry'));
    expect(database.inserts, 1);
    expect(provider.medicalHistories.single.notes, 'Attachment retry');
    expect(tester.takeException(), isNull);
  });
}
