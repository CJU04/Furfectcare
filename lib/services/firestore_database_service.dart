import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/pet.dart';
import '../models/appointment.dart';
import '../models/medical_history.dart';
import '../models/product.dart';
import '../models/sales.dart';
import '../models/sale_item.dart';
import '../models/inventory_log.dart';
import '../models/user.dart';

import '../models/appointment_log.dart';

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
    final snap =
        await _col('pets').where('ownerUid', isEqualTo: ownerUid).get();
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
    final result = await FirebaseFunctions.instance
        .httpsCallable('saveAppointment')
        .call<Map<String, dynamic>>({
      'operation': 'create',
      if (appointment.appointmentId?.isNotEmpty == true)
        'id': appointment.appointmentId,
      'appointment': appointment.toMap(),
    });
    return result.data['id'] as String;
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
      throw ArgumentError(
          'updateAppointment requires appointment.appointmentId');
    }
    await FirebaseFunctions.instance.httpsCallable('saveAppointment').call({
      'operation': 'update',
      'id': appointment.appointmentId,
      'appointment': appointment.toMap(),
    });
  }

  Future<void> deleteAppointment(String id) async {
    await FirebaseFunctions.instance.httpsCallable('saveAppointment').call({
      'operation': 'delete',
      'id': id,
    });
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
    if (sales.saleId != null && sales.saleId!.isNotEmpty) {
      await _col('sales').doc(sales.saleId).set(data, SetOptions(merge: true));
      return sales.saleId!;
    }
    final docRef = await _col('sales').add(data);
    await docRef.update({'saleId': docRef.id});
    return docRef.id;
  }

  Future<List<Sales>> getSales() async {
    final snap = await _col('sales').get();
    return snap.docs.map((d) {
      final s = Sales.fromMap(d.data());
      s.saleId = d.id;
      return s;
    }).toList();
  }

  Future<List<Sales>> getSalesByOwner(String ownerUid) async {
    final snap =
        await _col('sales').where('ownerUid', isEqualTo: ownerUid).get();
    return snap.docs.map((d) {
      final s = Sales.fromMap(d.data());
      s.saleId = d.id;
      return s;
    }).toList();
  }

  Future<void> updateSales(Sales sales) async {
    if (sales.saleId == null) {
      throw ArgumentError('updateSales requires sales.saleId');
    }
    await _col('sales')
        .doc(sales.saleId)
        .set(sales.toMap(), SetOptions(merge: true));
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
    final snap =
        await _col('sale_items').where('saleId', isEqualTo: saleId).get();
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
    final snap = await _col('inventory_logs')
        .where('productId', isEqualTo: productId)
        .get();
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

  // --------------------
  // App Notifications
  // --------------------
  Future<String> insertNotification(AppNotification notification) async {
    final data = notification.toMap();
    if (notification.notificationId != null &&
        notification.notificationId!.isNotEmpty) {
      await _col('notifications')
          .doc(notification.notificationId)
          .set(data, SetOptions(merge: true));
      return notification.notificationId!;
    }
    // Pre-allocate the document reference so `notificationId` can be
    // written in the same create call. A follow-up `update` would be
    // rejected by `firestore.rules` (recipients may only flip `isRead`).
    final docRef = _col('notifications').doc();
    data['notificationId'] = docRef.id;
    await docRef.set(data);
    return docRef.id;
  }

  Stream<List<AppNotification>> watchNotificationsForUser(String userId) {
    if (userId.isEmpty) return Stream.value(<AppNotification>[]);

    // Primary: real-time snapshots scoped to the caller's own documents.
    // Fallback: if the listener fails (for example a permission-denied on
    // legacy rows before rules catch up), degrade gracefully to polling the
    // one-shot reader so the bell / notification center never disconnects.
    late final StreamController<List<AppNotification>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subscription;
    Timer? pollTimer;

    Future<void> poll() async {
      try {
        final items = await getNotificationsForUser(userId);
        if (!controller.isClosed) controller.add(items);
      } catch (e) {
        debugPrint('Notification polling failed: $e');
      }
    }

    controller = StreamController<List<AppNotification>>(
      onListen: () {
        subscription = _col('notifications')
            .where('userId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snapshot) {
            final items = snapshot.docs
                .map(
                    (doc) => AppNotification.fromMap(doc.data(), docId: doc.id))
                .toList();
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (!controller.isClosed) controller.add(items);
          },
          onError: (Object error) {
            debugPrint('Notification watch failed ($error); '
                'falling back to polling.');
            pollTimer ??=
                Timer.periodic(const Duration(seconds: 10), (_) => poll());
            poll();
          },
        );
      },
      onCancel: () {
        subscription?.cancel();
        pollTimer?.cancel();
      },
    );
    return controller.stream;
  }

  Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    // Primary query uses the `userId` field because `firestore.rules`
    // validates the `list` operation against `resource.data.userId`.
    try {
      final snap =
          await _col('notifications').where('userId', isEqualTo: userId).get();
      final list = snap.docs
          .map((d) => AppNotification.fromMap(d.data(), docId: d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      // Fallback for legacy rows that only stored `recipientUserId`.
      try {
        final snap = await _col('notifications')
            .where('recipientUserId', isEqualTo: userId)
            .get();
        final list = snap.docs
            .map((d) => AppNotification.fromMap(d.data(), docId: d.id))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (e) {
        return [];
      }
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _col('notifications').doc(notificationId).set({
      'isRead': true,
      'read': true,
    }, SetOptions(merge: true));
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final snap = await _col('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      await doc.reference
          .set({'isRead': true, 'read': true}, SetOptions(merge: true));
    }
  }

  // --------------------
  // Appointment Logs (audit history)
  // --------------------
  Future<String> insertAppointmentLog(AppointmentLog log) async {
    final data = log.toMap();
    if (log.logId != null && log.logId!.isNotEmpty) {
      await _col('appointment_logs').doc(log.logId).set(data);
      return log.logId!;
    }
    // Pre-allocate the document reference so `logId` is written in the same
    // create call (updates are rejected by `firestore.rules` — history is
    // immutable).
    final docRef = _col('appointment_logs').doc();
    data['logId'] = docRef.id;
    await docRef.set(data);
    return docRef.id;
  }

  Future<List<AppointmentLog>> getAppointmentLogs() async {
    try {
      final snap = await _col('appointment_logs').get();
      final logs = snap.docs
          .map((d) => AppointmentLog.fromMap(d.data(), docId: d.id))
          .toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return logs;
    } catch (e) {
      // Non-staff callers (or a rules rollback) must never crash the UI.
      return [];
    }
  }
}
