import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';

/// A full message is always readable, even for legacy notifications with no link.
class NotificationDetailsDialog extends StatelessWidget {
  final AppNotification notification;
  const NotificationDetailsDialog({super.key, required this.notification});

  static String readable(String value) => value.replaceAllMapped(
      RegExp(r'confirmed', caseSensitive: false),
      (match) => match[0]![0] == 'C' ? 'Scheduled' : 'scheduled');

  static String? destination(String type) => switch (type) {
        'appointment' => '/appointment_management',
        'order' || 'payment' => '/product_history',
        'inventory' => '/product_inventory',
        'medical_document' => '/medical_documents',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final route = destination(notification.type);
    final id = notification.relatedDocumentId?.trim();
    return AlertDialog(
      title: Text(notification.title.trim().isEmpty
          ? 'Notification details'
          : readable(notification.title)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('MMM d, yyyy • h:mm a')
                    .format(notification.createdAt)),
                const SizedBox(height: 16),
                SelectableText(notification.message.trim().isEmpty
                    ? 'This older notification has no message. Open the related section to check the latest information.'
                    : readable(notification.message)),
                const SizedBox(height: 16),
                Text(route == null
                    ? 'This is an informational update. No action is required here.'
                    : 'Open the related section to review the current record and available actions.'),
              ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        if (route != null)
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(switch (notification.type) {
              'appointment' => 'View appointment',
              'order' || 'payment' => 'View purchase',
              'inventory' => 'View inventory',
              _ => 'View documents',
            }),
            onPressed: () => Navigator.pop(context, <String, String>{
              'route': route,
              if (id != null && id.isNotEmpty) 'recordId': id,
            }),
          ),
      ],
    );
  }
}
