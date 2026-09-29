import 'package:flutter/material.dart';
import 'package:vetcare_connect/utils/payment_options.dart';

/// Single source of UI for choosing how an order will be paid.
///
/// Driven entirely by [PaymentOptions]. Any online entry (none today) is a
/// value the checkout flow must route through the server gateway; it can
/// never be confirmed by typing a reference number here.
Future<String?> showPaymentMethodPicker(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final method in PaymentOptions.methods)
              ListTile(
                title: Text(PaymentOptions.titleOf(method)),
                subtitle: Text(PaymentOptions.subtitleOf(method)),
                leading: Icon(PaymentOptions.iconOf(method)),
                onTap: () => Navigator.pop(dialogContext, method),
              ),
          ],
        ),
      );
    },
  );
}
