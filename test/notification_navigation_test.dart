import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetcare_connect/models/user.dart';
import 'package:vetcare_connect/views/widgets/notification_details_dialog.dart';

void main() {
  testWidgets('Notification opens full details and forwards appointment ID',
      (tester) async {
    Map<String, String>? action;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
          child: const Text('Open notification'),
          onPressed: () async {
            action = await showDialog<Map<String, String>>(
                context: context,
                builder: (_) => NotificationDetailsDialog(
                        notification: AppNotification(
                      recipientUserId: 'owner',
                      title: 'Appointment Confirmed',
                      message:
                          'Bella is confirmed for September 20 at 09:00. Bring her vaccination record.',
                      type: 'appointment',
                      relatedDocumentId: 'appointment-123',
                    )));
          }),
    ))));
    await tester.tap(find.text('Open notification'));
    await tester.pumpAndSettle();
    expect(find.text('Appointment Scheduled'), findsOneWidget);
    expect(
        find.textContaining('Bring her vaccination record.'), findsOneWidget);
    await tester.tap(find.text('View appointment'));
    await tester.pumpAndSettle();
    expect(action,
        {'route': '/appointment_management', 'recordId': 'appointment-123'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty legacy notification explains missing content',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: NotificationDetailsDialog(
      notification: AppNotification(
          recipientUserId: 'owner', title: '', message: '', type: 'general'),
    )));
    expect(find.text('Notification details'), findsOneWidget);
    expect(find.textContaining('older notification'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
