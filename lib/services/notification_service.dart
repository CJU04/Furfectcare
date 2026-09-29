import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Function(String?, Map<String?, String?>)? onMessageReceived;
  Function(String?)? onTokenRefreshed;

  Future<void> initialize({required String role}) async {
    await _requestPermission();
    // Local notifications are still required on Android for foreground rendering.
    // But role targeting happens via FCM topics above.
    await _initializeLocalNotifications();
    await _getToken();
    await _subscribeToTopics(role: role);
    _setupMessageHandlers();
  }

  Future<void> _requestPermission() async {
    // Web relies on the browser's own notification permission prompt,
    // triggered by FCM's web integration. Local platform checks do not apply.
    if (kIsWeb) {
      final webPermission = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) {
        print('Web Permission status: ${webPermission.authorizationStatus}');
      }
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPermission = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) {
        print('IOS Permission status: ${iosPermission.authorizationStatus}');
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPermission = await _firebaseMessaging.requestPermission();
      if (kDebugMode) {
        print(
            'Android Permission status: ${androidPermission.authorizationStatus}');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Local notification channels are a mobile concept; on web the browser
    // notification surface is handled by FCM directly.
    if (kIsWeb) return;
    // Required before any `zonedSchedule` call - loads the tz database so
    // appointment reminders can be scheduled at an absolute instant.
    tz_data.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    final payload = response.payload;
    if (payload != null && onMessageReceived != null) {
      onMessageReceived!(payload, {});
    }
  }

  Future<void> _getToken() async {
    // getToken() needs a VAPID key on web and native FCM setup elsewhere;
    // treat any failure as non-fatal so the app still initializes.
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM token unavailable: $e');
      }
      return;
    }
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      if (kDebugMode) {
        print('FCM Token refreshed: $newToken');
      }
      onTokenRefreshed?.call(newToken);
    });
  }

  Future<void> _subscribeToTopics({
    required String role,
  }) async {
    // NOTE: Role-targeting is done via FCM topics.
    // Your backend/FCM sender must publish to these topics.
    // Subscribing locally ensures the device receives only notifications for its role.
    final normalizedRole = role.trim().toLowerCase();

    // Always subscribe to appointment events.
    // (You can split further later, e.g. appointments:customer vs appointments:staff)
    final topicsToSubscribe = <String>{
      'appointments',
      'general',
      normalizedRole, // e.g. admin, staff, veterinarian, customer
      'role_$normalizedRole', // e.g. role_customer (extra namespace)
    };

    try {
      for (final topic in topicsToSubscribe) {
        await _firebaseMessaging.subscribeToTopic(topic);
      }
      if (kDebugMode) {
        print('Subscribed to role topics: ${topicsToSubscribe.join(', ')}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topics: $e');
      }
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    _firebaseMessaging.getInitialMessage().then(_handleInitialMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message received: ${message.messageId}');
    }
    _showLocalNotification(message);
    onMessageReceived?.call(
        message.messageId, message.data.cast<String?, String?>());
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Message opened app: ${message.messageId}');
    }
    onMessageReceived?.call(
        message.messageId, message.data.cast<String?, String?>());
  }

  void _handleInitialMessage(RemoteMessage? message) {
    if (message != null && kDebugMode) {
      debugPrint('Initial message: ${message.messageId}');
      onMessageReceived?.call(
          message.messageId, message.data.cast<String?, String?>());
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return; // Browser surfaces FCM notifications directly.
    final androidDetails = AndroidNotificationDetails(
      'furfectcare_notifications',
      'FurfectCare Notifications',
      channelDescription: 'General notifications from FurfectCare',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'FurfectCare',
      body: message.notification?.body ?? 'You have a new notification',
      notificationDetails: details,
      payload: message.data['screen'] ?? '',
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return; // Browser surfaces FCM notifications directly.
    final androidDetails = AndroidNotificationDetails(
      'furfectcare_notifications',
      'FurfectCare Notifications',
      channelDescription: 'General notifications from FurfectCare',
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: details,
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
    if (kIsWeb) return; // Browser surfaces FCM notifications directly.
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Reminders',
      channelDescription: 'Notifications for upcoming appointments',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = reason != null && reason.isNotEmpty
        ? 'Reminder: $ownerName, your appointment for $petName on $date at $time. Reason: $reason'
        : 'Reminder: $ownerName, your appointment for $petName is on $date at $time';

    await _localNotificationsPlugin.show(
      id: appointmentId.hashCode,
      title: 'Appointment Reminder',
      body: body,
      notificationDetails: details,
      payload: 'appointment:$appointmentId',
    );
  }

  Future<void> showAppointmentCreated({
    required String appointmentId,
    required String petName,
    required String ownerName,
    required String date,
    required String time,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Notifications',
      channelDescription: 'Notifications for appointment updates',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'appointment_created_$appointmentId'.hashCode,
      title: 'New Appointment Booked',
      body: '$ownerName booked an appointment for $petName on $date at $time',
      notificationDetails: details,
      payload: 'appointment:$appointmentId',
    );
  }

  Future<void> showAppointmentCancelled({
    required String appointmentId,
    required String petName,
    required String cancellerName,
    required String date,
    required String time,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Notifications',
      channelDescription: 'Notifications for appointment updates',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'appointment_cancelled_$appointmentId'.hashCode,
      title: 'Appointment Cancelled',
      body:
          '$cancellerName cancelled the appointment for $petName on $date at $time',
      notificationDetails: details,
      payload: 'appointment:$appointmentId',
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
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Notifications',
      channelDescription: 'Notifications for appointment updates',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'appointment_changed_$appointmentId'.hashCode,
      title: 'Appointment Updated',
      body:
          '$changerName changed $petName\'s appointment from $oldDate $oldTime to $newDate at $newTime',
      notificationDetails: details,
      payload: 'appointment:$appointmentId',
    );
  }

  Future<void> showAppointmentAssigned({
    required String appointmentId,
    required String petName,
    required String vetName,
    required String date,
    required String time,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Notifications',
      channelDescription: 'Notifications for appointment updates',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'appointment_assigned_$appointmentId'.hashCode,
      title: 'New Appointment Assigned',
      body: 'You have been assigned to $petName on $date at $time',
      notificationDetails: details,
      payload: 'appointment:$appointmentId',
    );
  }

  Future<void> showAppointmentConfirmed({
    required String appointmentId,
    required String petName,
    required String date,
    required String time,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Notifications',
      channelDescription: 'Notifications for appointment updates',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'appointment_confirmed_$appointmentId'.hashCode,
      title: 'Appointment Scheduled',
      body: 'Your appointment for $petName is scheduled for $date at $time',
      notificationDetails: details,
      payload: 'appointment:$appointmentId',
    );
  }

  Future<void> showAppointmentRejected({
    required String appointmentId,
    required String petName,
    required String date,
    required String reason,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Notifications',
      channelDescription: 'Notifications for appointment updates',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final suffix = reason.trim().isEmpty ? '' : ' Reason: $reason';

    await _localNotificationsPlugin.show(
      id: 'appointment_rejected_$appointmentId'.hashCode,
      title: 'Appointment Rejected',
      body:
          'Your appointment for $petName on $date could not be accommodated.$suffix',
      notificationDetails: details,
      payload: 'appointment:$appointmentId',
    );
  }

  Future<void> showAppointmentCompleted({
    required String appointmentId,
    required String petName,
    required String vetName,
    required String date,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Notifications',
      channelDescription: 'Notifications for appointment updates',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'appointment_completed_$appointmentId'.hashCode,
      title: 'Appointment Completed',
      body:
          'The appointment for $petName with $vetName on $date has been completed',
      notificationDetails: details,
      payload: 'appointment:$appointmentId',
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
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'sales',
      'Sales Notifications',
      channelDescription: 'Notifications for orders and sales',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'order_$orderId'.hashCode,
      title: 'Order Scheduled',
      body:
          'Your order for $productName has been scheduled. Total: ₱${totalAmount.toStringAsFixed(2)}',
      notificationDetails: details,
      payload: 'order:$orderId',
    );
  }

  Future<void> showOrderShipped({
    required String orderId,
    required String productName,
    required String trackingNumber,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'sales',
      'Sales Notifications',
      channelDescription: 'Notifications for orders and sales',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'order_shipped_$orderId'.hashCode,
      title: 'Order Shipped',
      body: '$productName is on its way! Tracking #: $trackingNumber',
      notificationDetails: details,
      payload: 'order:$orderId',
    );
  }

  Future<void> showOrderDelivered({
    required String orderId,
    required String productName,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'sales',
      'Sales Notifications',
      channelDescription: 'Notifications for orders and sales',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'order_delivered_$orderId'.hashCode,
      title: 'Order Delivered',
      body: 'Your order for $productName has been delivered!',
      notificationDetails: details,
      payload: 'order:$orderId',
    );
  }

  Future<void> showOrderCancelled({
    required String orderId,
    required String productName,
    required String reason,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'sales',
      'Sales Notifications',
      channelDescription: 'Notifications for orders and sales',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'order_cancelled_$orderId'.hashCode,
      title: 'Order Cancelled',
      body: 'Your order for $productName was cancelled. Reason: $reason',
      notificationDetails: details,
      payload: 'order:$orderId',
    );
  }

  Future<void> showLowStockAlert({
    required String productId,
    required String productName,
    required int currentStock,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'inventory',
      'Inventory Alerts',
      channelDescription: 'Notifications for low stock and inventory',
      icon: '@mipmap/ic_launcher',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'low_stock_$productId'.hashCode,
      title: 'Low Stock Alert',
      body: '$productName is running low. Only $currentStock left in stock!',
      notificationDetails: details,
      payload: 'product:$productId',
    );
  }

  /// Notifies a pet owner that a new medical record was added to their pet.
  Future<void> showMedicalRecordAdded({
    required String recordId,
    required String petName,
    required String recordType,
    required String date,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'medical',
      'Medical Record Notifications',
      channelDescription: 'Notifications for medical records and prescriptions',
      icon: '@mipmap/ic_launcher',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'medical_record_$recordId'.hashCode,
      title: 'New Medical Record',
      body: '$petName has a new $recordType record dated $date',
      notificationDetails: details,
      payload: 'medical:$recordId',
    );
  }

  /// Notifies clinic staff that a customer registered a new pet.
  Future<void> showPetRegistered({
    required String petId,
    required String petName,
    required String ownerName,
    required String petType,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'pets',
      'Pet Records',
      channelDescription: 'Notifications for newly registered pets',
      icon: '@mipmap/ic_launcher',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'pet_registered_$petId'.hashCode,
      title: 'New Pet Registered',
      body: '$ownerName registered $petName ($petType)',
      notificationDetails: details,
      payload: 'pet:$petId',
    );
  }

  /// Notifies a customer that their payment was received.
  Future<void> showPaymentReceived({
    required String saleId,
    required double amount,
    required String reference,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'payments',
      'Payment Notifications',
      channelDescription: 'Notifications for payments and receipts',
      icon: '@mipmap/ic_launcher',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'payment_$saleId'.hashCode,
      title: 'Payment Received',
      body:
          'We received ₱${amount.toStringAsFixed(2)} for $reference. Thank you!',
      notificationDetails: details,
      payload: 'payment:$saleId',
    );
  }

  /// Shows a free-form announcement (used for clinic-wide broadcasts).
  Future<void> showAnnouncement({
    required String announcementId,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'announcements',
      'Announcements',
      channelDescription: 'Clinic-wide announcements and reminders',
      icon: '@mipmap/ic_launcher',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: 'announcement_$announcementId'.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'announcement:$announcementId',
    );
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _localNotificationsPlugin.cancelAll();
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
    if (kIsWeb) return;
    final androidDetails = AndroidNotificationDetails(
      'appointments',
      'Appointment Reminders',
      channelDescription: 'Notifications for upcoming appointments',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = reason != null && reason.isNotEmpty
        ? 'Reminder: $ownerName, your appointment for $petName on $date at $time. Reason: $reason'
        : 'Reminder: $ownerName, your appointment for $petName is on $date at $time';

    // `zonedSchedule` replaces the removed `schedule` API in
    // flutter_local_notifications v22. `TZDateTime.from` keeps the same
    // absolute instant as the local [scheduledTime], which is what the
    // platform alarm is built from.
    await _localNotificationsPlugin.zonedSchedule(
      id: appointmentId.hashCode,
      title: 'Appointment Reminder',
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'appointment:$appointmentId',
    );
  }

  Future<void> cancelAppointmentReminder(String appointmentId) async {
    if (kIsWeb) return;
    await _localNotificationsPlugin.cancel(id: appointmentId.hashCode);
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // This would typically use Firebase Cloud Functions
    // For now, we'll use local notifications as a demonstration
    await showNotification(
      title: title,
      body: body,
      payload: data?['screen'] ?? '',
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Background message: ${message.messageId}');
  }
}
