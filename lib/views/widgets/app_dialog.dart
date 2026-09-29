import 'package:flutter/material.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';

/// Uniform dialog helpers used across the app.
///
/// Every confirmation, form, and information modal should render inside
/// [AppDialogShell] so all dialogs in the system share the same shape,
/// header, and action bar. New dialogs must use these helpers instead of
/// raw [AlertDialog] / [Dialog] constructors.
class AppDialog {
  AppDialog._();

  /// Shows arbitrary content inside the uniform [AppDialogShell].
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    IconData? icon,
    required Widget content,
    List<Widget>? actions,
    bool scrollable = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AppDialogShell(
        title: title,
        icon: icon,
        content: content,
        actions: actions,
        scrollable: scrollable,
      ),
    );
  }

  /// Standard confirmation dialog. Returns `true` when the user confirms.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AppDialogShell(
        title: title,
        icon: destructive ? Icons.warning_amber_rounded : Icons.help_outline,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? Colors.red : AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// The shared visual shell: rounded card, icon + title header, divider,
/// scrollable body, and a right-aligned action row.
class AppDialogShell extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget content;
  final List<Widget>? actions;
  final bool scrollable;

  const AppDialogShell({
    super.key,
    required this.title,
    this.icon,
    required this.content,
    this.actions,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final actionsList = actions ?? const <Widget>[];
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: scrollable
                    ? SingleChildScrollView(child: content)
                    : content,
              ),
            ),
            if (actionsList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actionsList.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actionsList[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
