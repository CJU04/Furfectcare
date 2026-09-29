import 'package:flutter/foundation.dart';
import 'package:vetcare_connect/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  /// Shows a general notification
  static Future<void> showNotification(
    BuildContext context, {
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      await provider.showNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing notification: $e');
      }
    }
  }

  /// Shows an appointment reminder notification
  static Future<void> showAppointmentReminder(
    BuildContext context, {
    required String appointmentId,
    required String petName,
    required String date,
    required String time,
    String ownerName = 'Pet Owner',
  }) async {
    try {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      await provider.showAppointmentReminder(
        appointmentId: appointmentId,
        petName: petName,
        date: date,
        time: time,
        ownerName: ownerName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing appointment reminder: $e');
      }
    }
  }

  /// Shows a low stock alert notification (for staff/admin)
  static Future<void> showLowStockAlert(
    BuildContext context, {
    required String productName,
    required int stockQuantity,
  }) async {
    try {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      await provider.showNotification(
        title: 'Low Stock Alert',
        body: '$productName is running low ($stockQuantity remaining)',
        payload: 'product:$productName',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing low stock alert: $e');
      }
    }
  }

  /// Shows a new appointment notification (for staff/admin)
  static Future<void> showNewAppointmentNotification(
    BuildContext context, {
    required String petName,
    required String ownerName,
    required String date,
    required String time,
    required String reason,
  }) async {
    try {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      await provider.showNotification(
        title: 'New Appointment Booked',
        body: '$petName (Owner: $ownerName)\n$reason on $date at $time',
        payload: 'new_appointment',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing new appointment notification: $e');
      }
    }
  }

  /// Shows an appointment confirmed notification (for pet owner)
  static Future<void> showAppointmentConfirmedNotification(
    BuildContext context, {
    required String petName,
    required String date,
    required String time,
  }) async {
    try {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      await provider.showNotification(
        title: 'Appointment Scheduled!',
        body:
            'Your pet $petName\'s appointment is scheduled for $date at $time',
        payload: 'appointment_confirmed',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing appointment confirmed notification: $e');
      }
    }
  }

  /// Shows an appointment cancelled notification
  static Future<void> showAppointmentCancelledNotification(
    BuildContext context, {
    required String petName,
    required String date,
    required String time,
  }) async {
    try {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      await provider.showNotification(
        title: 'Appointment Cancelled',
        body:
            'Your appointment for $petName on $date at $time has been cancelled',
        payload: 'appointment_cancelled',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing appointment cancelled notification: $e');
      }
    }
  }
}
