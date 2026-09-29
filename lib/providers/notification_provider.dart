import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetcare_connect/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  String? _fcmToken;

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get fcmToken => _fcmToken;

  NotificationProvider() {
    _loadNotificationPreference();
  }

  Future<void> initialize({required String role}) async {
    if (_isInitialized) return;

    try {
      await _notificationService.initialize(role: role);
      _fcmToken = _notificationService.fcmToken;

      _notificationService.onTokenRefreshed = (newToken) {
        _fcmToken = newToken;
        notifyListeners();
      };

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);

    if (!_notificationsEnabled) {
      await _notificationService.cancelAllNotifications();
    }

    // When enabling notifications, the caller must re-initialize with the proper role.
    // (We avoid role guessing here because it's required for role-targeted topics.)
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;

    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);

    if (!_notificationsEnabled) {
      await _notificationService.cancelAllNotifications();
    }

    // When enabling notifications, the caller must re-initialize with the proper role.
    notifyListeners();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> showAppointmentReminder({
    required String appointmentId,
    required String petName,
    required String date,
    required String time,
    required String ownerName,
    String? reason,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAppointmentReminder(
      appointmentId: appointmentId,
      petName: petName,
      date: date,
      time: time,
      ownerName: ownerName,
      reason: reason,
    );
  }

  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String petName,
    required String date,
    required String time,
    required String ownerName,
    String? reason,
    required DateTime scheduledTime,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.scheduleAppointmentReminder(
      appointmentId: appointmentId,
      petName: petName,
      date: date,
      time: time,
      ownerName: ownerName,
      reason: reason,
      scheduledTime: scheduledTime,
    );
  }

  Future<void> cancelAppointmentReminder(String appointmentId) async {
    if (!_notificationsEnabled) return;
    await _notificationService.cancelAppointmentReminder(appointmentId);
  }

  Future<void> showAppointmentCreated({
    required String appointmentId,
    required String petName,
    required String ownerName,
    required String date,
    required String time,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAppointmentCreated(
      appointmentId: appointmentId,
      petName: petName,
      ownerName: ownerName,
      date: date,
      time: time,
    );
  }

  Future<void> showAppointmentCancelled({
    required String appointmentId,
    required String petName,
    required String cancellerName,
    required String date,
    required String time,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAppointmentCancelled(
      appointmentId: appointmentId,
      petName: petName,
      cancellerName: cancellerName,
      date: date,
      time: time,
    );
  }

  Future<void> showAppointmentChanged({
    required String appointmentId,
    required String petName,
    required String changerName,
    required String newDate,
    required String newTime,
    required String oldDate,
    required String oldTime,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAppointmentChanged(
      appointmentId: appointmentId,
      petName: petName,
      changerName: changerName,
      newDate: newDate,
      newTime: newTime,
      oldDate: oldDate,
      oldTime: oldTime,
    );
  }

  Future<void> showAppointmentAssigned({
    required String appointmentId,
    required String petName,
    required String vetName,
    required String date,
    required String time,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAppointmentAssigned(
      appointmentId: appointmentId,
      petName: petName,
      vetName: vetName,
      date: date,
      time: time,
    );
  }

  Future<void> showAppointmentCompleted({
    required String appointmentId,
    required String petName,
    required String vetName,
    required String date,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAppointmentCompleted(
      appointmentId: appointmentId,
      petName: petName,
      vetName: vetName,
      date: date,
    );
  }

  Future<void> showAppointmentConfirmed({
    required String appointmentId,
    required String petName,
    required String date,
    required String time,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAppointmentConfirmed(
      appointmentId: appointmentId,
      petName: petName,
      date: date,
      time: time,
    );
  }

  Future<void> showAppointmentRejected({
    required String appointmentId,
    required String petName,
    required String date,
    required String reason,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAppointmentRejected(
      appointmentId: appointmentId,
      petName: petName,
      date: date,
      reason: reason,
    );
  }

  // --------------------
  // Sales / Product Notifications
  // --------------------
  Future<void> showOrderConfirmation({
    required String orderId,
    required String productName,
    required double totalAmount,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showOrderConfirmation(
      orderId: orderId,
      productName: productName,
      totalAmount: totalAmount,
    );
  }

  Future<void> showOrderShipped({
    required String orderId,
    required String productName,
    required String trackingNumber,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showOrderShipped(
      orderId: orderId,
      productName: productName,
      trackingNumber: trackingNumber,
    );
  }

  Future<void> showOrderDelivered({
    required String orderId,
    required String productName,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showOrderDelivered(
      orderId: orderId,
      productName: productName,
    );
  }

  Future<void> showOrderCancelled({
    required String orderId,
    required String productName,
    required String reason,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showOrderCancelled(
      orderId: orderId,
      productName: productName,
      reason: reason,
    );
  }

  Future<void> showLowStockAlert({
    required String productId,
    required String productName,
    required int currentStock,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showLowStockAlert(
      productId: productId,
      productName: productName,
      currentStock: currentStock,
    );
  }

  // --------------------
  // Medical / Pet Notifications
  // --------------------
  Future<void> showMedicalRecordAdded({
    required String recordId,
    required String petName,
    required String recordType,
    required String date,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showMedicalRecordAdded(
      recordId: recordId,
      petName: petName,
      recordType: recordType,
      date: date,
    );
  }

  Future<void> showPetRegistered({
    required String petId,
    required String petName,
    required String ownerName,
    required String petType,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showPetRegistered(
      petId: petId,
      petName: petName,
      ownerName: ownerName,
      petType: petType,
    );
  }

  Future<void> showPaymentReceived({
    required String saleId,
    required double amount,
    required String reference,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showPaymentReceived(
      saleId: saleId,
      amount: amount,
      reference: reference,
    );
  }

  /// Device notification for a clinic-wide announcement.
  Future<void> showAnnouncement({
    required String announcementId,
    required String title,
    required String body,
  }) async {
    if (!_notificationsEnabled) return;
    await _notificationService.showAnnouncement(
      announcementId: announcementId,
      title: title,
      body: body,
    );
  }
}
