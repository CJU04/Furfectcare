import 'package:flutter/material.dart';

/// One reusable, well-spaced modal form shell. All add/edit dialogs across
/// pets, medical history, products and appointments should use this so
/// spacing, scrolling, overflow and error-message placement are uniform
/// and text never clips or overlaps.
class ModalFormShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isBusy;

  const ModalFormShell({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, softWrap: true),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            8 + MediaQuery.of(context).viewInsets.bottom * 0.2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isBusy ? null : onSubmit,
          child: isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(submitLabel),
        ),
      ],
    );
  }
}

/// Uniform tappable card: title + subtitle only (name-first per request).
/// Full details open on tap so lists stay scannable.
class NameFirstCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final VoidCallback onTap;
  final List<Widget>? actions;

  const NameFirstCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false),
                  ],
                ),
              ),
              if (actions != null) ...actions!,
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
