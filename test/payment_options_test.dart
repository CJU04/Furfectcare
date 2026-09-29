import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vetcare_connect/utils/payment_options.dart';
import 'package:vetcare_connect/utils/qr_checkout_sheet.dart';

void main() {
  test('Only pay at clinic is offered before gateway integration', () {
    expect(PaymentOptions.methods, [PaymentOptions.cash]);
    expect(PaymentOptions.isOnline(PaymentOptions.cash), isFalse);
    for (final method in ['GCash', 'Maya', 'Online Banking', 'unknown']) {
      expect(PaymentOptions.isOnline(method), isTrue);
      expect(PaymentOptions.methods, isNot(contains(method)));
    }
  });

  testWidgets('Unavailable checkout cannot confirm payment', (tester) async {
    String? result = 'not completed';
    bool completed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  onPressed: () async {
                    result = await QrCheckoutSheet.show(
                      context,
                      method: 'GCash',
                      total: 125,
                    );
                    completed = true;
                  },
                  child: const Text('Checkout'),
                )),
      ),
    ));
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Online payments not configured'), findsOneWidget);
    expect(find.text("I've paid"), findsNothing);
    expect(find.text('Open wallet app'), findsNothing);
    expect(find.byType(SelectableText), findsNothing);
    expect(completed, isFalse);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
