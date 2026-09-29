import 'package:flutter/material.dart';
import 'package:vetcare_connect/models/medical_history.dart';
import 'package:vetcare_connect/services/database_service.dart';

class MedicalHistoryProvider with ChangeNotifier {
  MedicalHistoryProvider({DatabaseService? database}) : _database = database;

  final DatabaseService? _database;
  DatabaseService get _store => _database ?? DatabaseService();
  List<MedicalHistory> _medicalHistories = [];

  List<MedicalHistory> get medicalHistories => _medicalHistories;

  Future<void> loadMedicalHistories() async {
    _medicalHistories = await _store.getMedicalHistories();
    notifyListeners();
  }

  Future<void> loadMedicalHistoriesForOwner(String ownerUid) async {
    final pets = await _store.getPetsByOwner(ownerUid);
    final petIds = pets.map((p) => p.petId).toSet();
    final histories = await _store.getMedicalHistories();
    _medicalHistories =
        histories.where((h) => petIds.contains(h.petId)).toList();
    notifyListeners();
  }

  Future<String> addMedicalHistory(MedicalHistory history) async {
    final id = await _store.insertMedicalHistory(history);
    // The write is complete. Do not turn a subsequent failed read into a
    // reported failed write: the caller needs this ID for attachment retries.
    _medicalHistories = [history.copyWith(historyId: id), ..._medicalHistories];
    notifyListeners();
    return id;
  }

  Future<void> updateMedicalHistory(MedicalHistory history) async {
    await _store.updateMedicalHistory(history);
    final index =
        _medicalHistories.indexWhere((h) => h.historyId == history.historyId);
    final updated = List<MedicalHistory>.of(_medicalHistories);
    if (index == -1) {
      updated.insert(0, history.copyWith());
    } else {
      updated[index] = history.copyWith();
    }
    _medicalHistories = updated;
    notifyListeners();
  }

  Future<void> deleteMedicalHistory(String id) async {
    await _store.deleteMedicalHistory(id);
    _medicalHistories =
        _medicalHistories.where((h) => h.historyId != id).toList();
    notifyListeners();
  }

  List<MedicalHistory> getMedicalHistoriesByPet(String petId) {
    return _medicalHistories.where((h) => h.petId == petId).toList();
  }
}
