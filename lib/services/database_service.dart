import '../models/pet.dart';
import '../models/appointment.dart';
import '../models/appointment_log.dart';
import '../models/medical_history.dart';
import '../models/product.dart';
import '../models/sales.dart';
import '../models/sale_item.dart';
import '../models/inventory_log.dart';
import '../models/user.dart';

import 'firestore_database_service.dart';

/// DatabaseService wrapper — delegates to FirestoreDatabaseService using Firebase Auth UIDs.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirestoreDatabaseService _store = FirestoreDatabaseService();

  // User
  Future<void> insertUser(Map<String, dynamic> data) => _store.insertUser(data);

  // Pet
  Future<String> insertPet(Pet pet) => _store.insertPet(pet);
  Future<List<Pet>> getPets() => _store.getPets();
  Future<List<Pet>> getPetsByOwner(String ownerUid) =>
      _store.getPetsByOwner(ownerUid);
  Future<void> updatePet(Pet pet) => _store.updatePet(pet);
  Future<void> deletePet(String id) => _store.deletePet(id);

  // Appointment
  Future<String> insertAppointment(Appointment appointment) =>
      _store.insertAppointment(appointment);
  Future<List<Appointment>> getAppointments() => _store.getAppointments();
  Future<List<Appointment>> getAppointmentsByOwner(String ownerUid) =>
      _store.getAppointmentsByOwner(ownerUid);
  Future<List<Appointment>> getAppointmentsByPet(String petId) =>
      _store.getAppointmentsByPet(petId);
  Future<void> updateAppointment(Appointment appointment) =>
      _store.updateAppointment(appointment);
  Future<void> deleteAppointment(String id) => _store.deleteAppointment(id);

  // MedicalHistory
  Future<String> insertMedicalHistory(MedicalHistory history) =>
      _store.insertMedicalHistory(history);
  Future<List<MedicalHistory>> getMedicalHistories() =>
      _store.getMedicalHistories();
  Future<List<MedicalHistory>> getMedicalHistoriesByPet(String petId) =>
      _store.getMedicalHistoriesByPet(petId);
  Future<void> updateMedicalHistory(MedicalHistory history) =>
      _store.updateMedicalHistory(history);
  Future<void> deleteMedicalHistory(String id) =>
      _store.deleteMedicalHistory(id);

  // Product
  Future<String> insertProduct(Product product) =>
      _store.insertProduct(product);
  Future<List<Product>> getProducts() => _store.getProducts();
  Future<void> updateProduct(Product product) => _store.updateProduct(product);
  Future<void> deleteProduct(String id) => _store.deleteProduct(id);

  // Sales
  Future<String> insertSales(Sales sales) => _store.insertSales(sales);
  Future<List<Sales>> getSales() => _store.getSales();
  Future<List<Sales>> getSalesByOwner(String ownerUid) =>
      _store.getSalesByOwner(ownerUid);
  Future<void> updateSales(Sales sales) => _store.updateSales(sales);
  Future<void> deleteSales(String id) => _store.deleteSales(id);

  // SaleItem
  Future<String> insertSaleItem(SaleItem item) => _store.insertSaleItem(item);
  Future<List<SaleItem>> getSaleItems() => _store.getSaleItems();
  Future<List<SaleItem>> getSaleItemsBySale(String saleId) =>
      _store.getSaleItemsBySale(saleId);
  Future<void> updateSaleItem(SaleItem item) => _store.updateSaleItem(item);
  Future<void> deleteSaleItem(String id) => _store.deleteSaleItem(id);

  // InventoryLog
  Future<String> insertInventoryLog(InventoryLog log) =>
      _store.insertInventoryLog(log);
  Future<List<InventoryLog>> getInventoryLogs() => _store.getInventoryLogs();
  Future<List<InventoryLog>> getInventoryLogsByProduct(String productId) =>
      _store.getInventoryLogsByProduct(productId);
  Future<void> updateInventoryLog(InventoryLog log) =>
      _store.updateInventoryLog(log);
  Future<void> deleteInventoryLog(String id) => _store.deleteInventoryLog(id);

  // App Notifications
  Stream<List<AppNotification>> watchNotificationsForUser(String userId) =>
      _store.watchNotificationsForUser(userId);

  Future<String> insertNotification(AppNotification notification) =>
      _store.insertNotification(notification);
  Future<List<AppNotification>> getNotificationsForUser(String userId) =>
      _store.getNotificationsForUser(userId);
  Future<void> markNotificationAsRead(String notificationId) =>
      _store.markNotificationAsRead(notificationId);
  Future<void> markAllNotificationsAsRead(String userId) =>
      _store.markAllNotificationsAsRead(userId);

  // Appointment Logs (audit history for admins)
  Future<String> insertAppointmentLog(AppointmentLog log) =>
      _store.insertAppointmentLog(log);
  Future<List<AppointmentLog>> getAppointmentLogs() =>
      _store.getAppointmentLogs();
}
