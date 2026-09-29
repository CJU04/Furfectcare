import 'package:flutter/foundation.dart';
import 'package:vetcare_connect/models/sale_item.dart';
import 'package:vetcare_connect/models/sales.dart';
import 'package:vetcare_connect/models/user.dart' show AppNotification;
import 'package:vetcare_connect/providers/notification_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/services/firestore/user_service.dart';

class SalesProvider with ChangeNotifier {
  final NotificationProvider _notificationProvider;

  SalesProvider({
    NotificationProvider? notificationProvider,
  }) : _notificationProvider = notificationProvider ?? NotificationProvider();

  List<Sales> _sales = [];

  List<Sales> get sales => _sales;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadSales() async {
    _isLoading = true;
    notifyListeners();
    try {
      _sales = await DatabaseService().getSales();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> addSales(Sales sales,
      {List<SaleItem> items = const []}) async {
    final id = await DatabaseService().insertSales(sales);
    await loadSales();

    final summary = items.isEmpty
        ? 'Order ${sales.orderReference.isEmpty ? id : sales.orderReference}'
        : await _describeItems(items);

    // Customer receipt (in-app + device notification).
    await _persistNotification(
      recipientUid: sales.ownerUid,
      title: 'Order Placed',
      message: 'Your order $summary was placed successfully. '
          'Total: ${_peso(sales.totalAmount)}.',
      relatedDocumentId: id,
    );
    try {
      await _notificationProvider.showOrderConfirmation(
        orderId: id,
        productName: summary,
        totalAmount: sales.totalAmount,
      );
    } catch (e) {
      debugPrint('Order confirmation notification failed: $e');
    }

    // Front-desk feed.
    await _notifyStaffOfOrder(
      saleId: id,
      title: 'New Order Placed',
      message:
          '${sales.customerName.isEmpty ? 'A customer' : sales.customerName} '
          'placed an order for $summary (${_peso(sales.totalAmount)}).',
    );

    return id;
  }

  Future<void> updateSales(Sales sales) async {
    Sales? previous;
    for (final existing in _sales) {
      if (existing.saleId != null && existing.saleId == sales.saleId) {
        previous = existing;
        break;
      }
    }

    await DatabaseService().updateSales(sales);
    await loadSales();

    await _notifyOrderProgress(previous, sales);
  }

  Future<void> deleteSales(String id) async {
    Sales? removed;
    for (final existing in _sales) {
      if (existing.saleId == id) {
        removed = existing;
        break;
      }
    }

    await DatabaseService().deleteSales(id);
    await loadSales();

    if (removed == null) return;
    final reference = removed.orderReference.isEmpty
        ? 'your recent order'
        : 'order ${removed.orderReference}';
    await _persistNotification(
      recipientUid: removed.ownerUid,
      title: 'Order Cancelled',
      message: '$reference was cancelled. Please contact the clinic if you '
          'have already paid.',
      relatedDocumentId: removed.saleId,
    );
    try {
      await _notificationProvider.showOrderCancelled(
        orderId: removed.saleId ?? id,
        productName: reference,
        reason: 'Cancelled by clinic',
      );
    } catch (e) {
      debugPrint('Order cancelled notification failed: $e');
    }
  }

  List<Sales> getSalesByOwner(String ownerUid) {
    return _sales.where((s) => s.ownerUid == ownerUid).toList();
  }

  // ==========================================================
  // Order notification helpers
  // ==========================================================

  static String _peso(double amount) => '₱${amount.toStringAsFixed(2)}';

  /// Builds a short "2x Dog Food, 1x Shampoo" style label.
  Future<String> _describeItems(List<SaleItem> items) async {
    try {
      final products = await DatabaseService().getProducts();
      final names = <String>[];
      for (final item in items) {
        final matches = products.where((p) => p.productId == item.productId);
        final label = matches.isNotEmpty && matches.first.productName.isNotEmpty
            ? matches.first.productName
            : 'item';
        names.add('${item.quantity}x $label');
      }
      if (names.isEmpty) return 'your order';
      return names.join(', ');
    } catch (e) {
      debugPrint('Could not describe order items: $e');
      return 'your order';
    }
  }

  /// Writes an in-app notification record for [recipientUid].
  Future<void> _persistNotification({
    required String recipientUid,
    required String title,
    required String message,
    String? relatedDocumentId,
  }) async {
    if (recipientUid.isEmpty) return;
    try {
      await DatabaseService().insertNotification(
        AppNotification(
          recipientUserId: recipientUid,
          title: title,
          message: message,
          type: 'order',
          relatedDocumentId: relatedDocumentId,
        ),
      );
    } catch (e) {
      debugPrint('Failed to persist order notification: $e');
    }
  }

  /// Notifies every clinic-side user about an order event.
  Future<void> _notifyStaffOfOrder({
    required String saleId,
    required String title,
    required String message,
  }) async {
    try {
      final users = await UserService().getAllUsers();
      for (final user in users) {
        final role = (user['role'] as String? ?? '').toLowerCase();
        if (role != 'staff' && role != 'admin' && role != 'veterinarian') {
          continue;
        }
        final uid = user['uid'] as String?;
        if (uid == null || uid.isEmpty) continue;
        await _persistNotification(
          recipientUid: uid,
          title: title,
          message: message,
          relatedDocumentId: saleId,
        );
      }
    } catch (e) {
      debugPrint('Failed to notify staff about order: $e');
    }
  }

  /// Sends the customer a notification when their order status changes.
  Future<void> _notifyOrderProgress(Sales? previous, Sales updated) async {
    final previousStatus = (previous?.orderStatus ?? '').toLowerCase();
    final newStatus = updated.orderStatus.toLowerCase();
    final previousPayment = (previous?.paymentStatus ?? '').toLowerCase();
    final newPayment = updated.paymentStatus.toLowerCase();

    final statusChanged = previousStatus != newStatus;
    final paymentChanged = previousPayment != newPayment;
    if (!statusChanged && !paymentChanged) return;

    final reference = updated.orderReference.isEmpty
        ? 'your recent order'
        : 'order ${updated.orderReference}';

    var title = 'Order Update';
    var message = '$reference is now ${updated.orderStatus}.';

    switch (newStatus) {
      case 'reserved':
      case 'pending_confirmation':
        title = 'Order Received';
        message = '$reference was received. We will verify your payment and '
            'prepare your items shortly.';
        break;
      case 'confirmed':
      case 'processing':
        title = 'Order Scheduled';
        message = '$reference has been scheduled and is being prepared.';
        break;
      case 'ready_for_pickup':
      case 'ready':
        title = 'Order Ready for Pickup';
        message = '$reference is ready. Please visit the clinic to claim it.';
        break;
      case 'completed':
        title = 'Order Completed';
        message = 'Thank you! $reference has been completed.';
        break;
      case 'cancelled':
      case 'rejected':
        title = 'Order Cancelled';
        message = '$reference was cancelled. Please contact the clinic for '
            'assistance.';
        break;
      default:
        if (paymentChanged) {
          title = 'Payment ${updated.paymentStatus}';
          message = 'The payment status of $reference is now '
              '${updated.paymentStatus}.';
        }
        break;
    }

    await _persistNotification(
      recipientUid: updated.ownerUid,
      title: title,
      message: message,
      relatedDocumentId: updated.saleId,
    );

    final orderId = updated.saleId ?? '';
    try {
      if (newStatus == 'completed') {
        await _notificationProvider.showOrderDelivered(
          orderId: orderId,
          productName: reference,
        );
      } else if (newStatus == 'cancelled' || newStatus == 'rejected') {
        await _notificationProvider.showOrderCancelled(
          orderId: orderId,
          productName: reference,
          reason: 'Status updated by clinic',
        );
      } else if (newStatus == 'ready_for_pickup' || newStatus == 'ready') {
        await _notificationProvider.showOrderShipped(
          orderId: orderId,
          productName: reference,
          trackingNumber:
              updated.orderReference.isEmpty ? orderId : updated.orderReference,
        );
      } else {
        await _notificationProvider.showOrderConfirmation(
          orderId: orderId,
          productName: reference,
          totalAmount: updated.totalAmount,
        );
      }
    } catch (e) {
      debugPrint('Order progress notification failed: $e');
    }
  }
}
