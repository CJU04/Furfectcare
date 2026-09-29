// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';

enum _TutorialAnchor { intro }

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.anchor,
    required this.child,
  });

  final _TutorialAnchor anchor;
  final Widget child;

  static Future<T?> show<T>({
    required BuildContext context,
    required _TutorialAnchor anchor,
    Widget? page,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final media = MediaQuery.of(context);
        final safe = media.padding.top + media.viewPadding.top;
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundMint,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(top: safe),
              child: TutorialOverlay(
                  anchor: anchor, child: page ?? const SizedBox.shrink()),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _buildForAnchor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Flexible(child: content),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildForAnchor() {
    switch (anchor) {
      case _TutorialAnchor.intro:
        return _IntroTutorial();
    }
  }
}

class _IntroTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pets, size: 40, color: AppTheme.primaryGreen),
        const SizedBox(height: 12),
        const Text(
          'Welcome to FurfectCare',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Manage pets, bookings, medical records, and store orders from one place. '
            'Use the drawer to switch between Customers, Staff, Products, Sales and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Get Started'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
