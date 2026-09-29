import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pet.dart';
import '../models/appointment.dart';
import '../models/medical_history.dart';
import '../models/product.dart';
import '../models/sales.dart';
import '../models/sale_item.dart';
import '../models/inventory_log.dart';

/// Firestore-backed service using Firebase Auth UIDs as document IDs.
///
/// Collections used:
/// - pets
/// - appointments
/// - medical_histories
/// - products
/// - sales
/// - sale_items
/// - inventory_logs
class FirestoreDatabaseService {
  final FirebaseFirestore _db;

  FirestoreDatabaseService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String name) {
    return _db.collection(name);
  }

  // --------------------
  // User
  // --------------------
  Future<void> insertUser(Map<String, dynamic> data) async {
    await _col('users').doc(data['uid'] as String).set(data);
  }

  // --------------------
  // Pet
  // --------------------
  Future<String> insertPet(Pet pet) async {
    final data = pet.toMap();
    if (pet.petId != null) {
      await _col('pets').doc(pet.petId).set(data);
      return pet.petId!;
    }
    final docRef = await _col('pets').add(data);
    // Store the auto-generated ID in the document for later retrieval
    await docRef.update({'petId': docRef.id});
    return docRef.id;
  }

  Future<List<Pet>> getPets() async {
    final snap = await _col('pets').get();
    return snap.docs.map((d) {
      final pet = Pet.fromMap(d.data());
      pet.petId = d.id;
      return pet;
    }).toList();
  }

  Future<void> updatePet(Pet pet) async {
    if (pet.petId == null) {
      throw ArgumentError('updatePet requires pet.petId');
    }
    await _col('pets').doc(pet.petId).set(pet.toMap(), SetOptions(merge: true));
  }

  Future<void> deletePet(String id) async {
    await _col('pets').doc(id).delete();
  }

  Future<List<Pet>> getPetsByOwner(String ownerUid) async {
    final snap = await _col('pets').where('ownerUid', isEqualTo: ownerUid).get();
    return snap.docs.map((d) {
      final pet = Pet.fromMap(d.data());
      pet.petId = d.id;
      return pet;
    }).toList();
  }

  // --------------------
  // Appointment
  // --------------------
  Future<String> insertAppointment(Appointment appointment) async {
    final data = appointment.toMap();

    if (appointment.appointmentId != null) {
      await _col('appointments')
          .doc(appointment.appointmentId)
          .set(data, SetOptions(merge: true));
      return appointment.appointmentId!;
    }

    final docRef = await _col('appointments').add(data);

    // Ensure appointmentId is also persisted so update/edit flows that rely on it work.
    await docRef.update({'appointmentId': docRef.id});
    return docRef.id;
  }

  Future<List<Appointment>> getAppointments() async {
    final snap = await _col('appointments').get();
    return snap.docs.map((d) {
      final appt = Appointment.fromMap(d.data());
      appt.appointmentId = d.id;
      return appt;
    }).toList();
  }

  Future<List<Appointment>> getAppointmentsByOwner(String ownerUid) async {
    final snap =
        await _col('appointments').where('ownerUid', isEqualTo: ownerUid).get();
    return snap.docs.map((d) {
      final appt = Appointment.fromMap(d.data());
      appt.appointmentId = d.id;
      return appt;
    }).toList();
  }

  Future<List<Appointment>> getAppointmentsByPet(String petId) async {
    final snap =
        await _col('appointments').where('petId', isEqualTo: petId).get();
    return snap.docs.map((d) {
      final appt = Appointment.fromMap(d.data());
      appt.appointmentId = d.id;
      return appt;
    }).toList();
  }

  Future<void> updateAppointment(Appointment appointment) async {
    if (appointment.appointmentId == null) {
      throw ArgumentError('updateAppointment requires appointment.appointmentId');
    }
    await _col('appointments').doc(appointment.appointmentId).set(
          appointment.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteAppointment(String id) async {
    await _col('appointments').doc(id).delete();
  }

  // --------------------
  // MedicalHistory
  // --------------------
  Future<String> insertMedicalHistory(MedicalHistory history) async {
    final data = history.toMap();
    if (history.historyId != null) {
      await _col('medical_histories').doc(history.historyId).set(data);
      return history.historyId!;
    }
    final docRef = await _col('medical_histories').add(data);
    return docRef.id;
  }

  Future<List<MedicalHistory>> getMedicalHistories() async {
    final snap = await _col('medical_histories').get();
    return snap.docs.map((d) {
      final hist = MedicalHistory.fromMap(d.data());
      hist.historyId = d.id;
      return hist;
    }).toList();
  }

  Future<List<MedicalHistory>> getMedicalHistoriesByPet(String petId) async {
    final snap =
        await _col('medical_histories').where('petId', isEqualTo: petId).get();
    return snap.docs.map((d) {
      final hist = MedicalHistory.fromMap(d.data());
      hist.historyId = d.id;
      return hist;
    }).toList();
  }

  Future<void> updateMedicalHistory(MedicalHistory history) async {
    if (history.historyId == null) {
      throw ArgumentError('updateMedicalHistory requires history.historyId');
    }
    await _col('medical_histories').doc(history.historyId).set(
          history.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteMedicalHistory(String id) async {
    await _col('medical_histories').doc(id).delete();
  }

  // --------------------
  // Product
  // --------------------
  Future<String> insertProduct(Product product) async {
    final data = product.toMap();
    if (product.productId != null) {
      await _col('products').doc(product.productId).set(data);
      return product.productId!;
    }
    final docRef = await _col('products').add(data);
    // Store the auto-generated ID in the document for later retrieval
    await docRef.update({'productId': docRef.id});
    return docRef.id;
  }

  Future<List<Product>> getProducts() async {
    final snap = await _col('products').get();
    return snap.docs.map((d) {
      final data = d.data();
      // Ensure productId is always set - use document ID if field is missing or empty
      if (data['productId'] == null || (data['productId'] as String).isEmpty) {
        data['productId'] = d.id;
      }
      return Product.fromMap(data);
    }).toList();
  }

  Future<void> updateProduct(Product product) async {
    if (product.productId == null) {
      throw ArgumentError('updateProduct requires product.productId');
    }
    await _col('products').doc(product.productId).set(
          product.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteProduct(String id) async {
    await _col('products').doc(id).delete();
  }

  // --------------------
  // Sales
  // --------------------
  Future<String> insertSales(Sales sales) async {
    final data = sales.toMap();
    if (sales.saleId != null) {
      await _col('sales').doc(sales.saleId).set(data);
      return sales.saleId!;
    }
    final docRef = await _col('sales').add(data);
    return docRef.id;
  }

  Future<List<Sales>> getSales() async {
    final snap = await _col('sales').get();
    return snap.docs.map((d) => Sales.fromMap(d.data())).toList();
  }

  Future<List<Sales>> getSalesByOwner(String ownerUid) async {
    final snap = await _col('sales').where('ownerUid', isEqualTo: ownerUid).get();
    return snap.docs.map((d) => Sales.fromMap(d.data())).toList();
  }

  Future<void> updateSales(Sales sales) async {
    if (sales.saleId == null) {
      throw ArgumentError('updateSales requires sales.saleId');
    }
    await _col('sales').doc(sales.saleId).set(sales.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteSales(String id) async {
    await _col('sales').doc(id).delete();
  }

  // --------------------
  // SaleItem
  // --------------------
  Future<String> insertSaleItem(SaleItem item) async {
    final data = item.toMap();
    if (item.salesItemId != null) {
      await _col('sale_items').doc(item.salesItemId).set(data);
      return item.salesItemId!;
    }
    final docRef = await _col('sale_items').add(data);
    return docRef.id;
  }

  Future<List<SaleItem>> getSaleItems() async {
    final snap = await _col('sale_items').get();
    return snap.docs.map((d) => SaleItem.fromMap(d.data())).toList();
  }

  Future<List<SaleItem>> getSaleItemsBySale(String saleId) async {
    final snap = await _col('sale_items').where('saleId', isEqualTo: saleId).get();
    return snap.docs.map((d) => SaleItem.fromMap(d.data())).toList();
  }

  Future<void> updateSaleItem(SaleItem item) async {
    if (item.salesItemId == null) {
      throw ArgumentError('updateSaleItem requires item.salesItemId');
    }
    await _col('sale_items').doc(item.salesItemId).set(
          item.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteSaleItem(String id) async {
    await _col('sale_items').doc(id).delete();
  }

  // --------------------
  // InventoryLog
  // --------------------
  Future<String> insertInventoryLog(InventoryLog log) async {
    final data = log.toMap();
    if (log.logId != null) {
      await _col('inventory_logs').doc(log.logId).set(data);
      return log.logId!;
    }
    final docRef = await _col('inventory_logs').add(data);
    return docRef.id;
  }

  Future<List<InventoryLog>> getInventoryLogs() async {
    final snap = await _col('inventory_logs').get();
    return snap.docs.map((d) => InventoryLog.fromMap(d.data())).toList();
  }

  Future<List<InventoryLog>> getInventoryLogsByProduct(String productId) async {
    final snap = await _col('inventory_logs').where('productId', isEqualTo: productId).get();
    return snap.docs.map((d) => InventoryLog.fromMap(d.data())).toList();
  }

  Future<void> updateInventoryLog(InventoryLog log) async {
    if (log.logId == null) {
      throw ArgumentError('updateInventoryLog requires log.logId');
    }
    await _col('inventory_logs').doc(log.logId).set(
          log.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteInventoryLog(String id) async {
    await _col('inventory_logs').doc(id).delete();
  }
}
