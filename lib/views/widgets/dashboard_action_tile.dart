import 'package:flutter/material.dart';

class DashboardActionTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const DashboardActionTile(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});
  @override
  State<DashboardActionTile> createState() => _DashboardActionTileState();
}

class _DashboardActionTileState extends State<DashboardActionTile> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        width: 136,
        height: 136,
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [colors.primaryContainer, colors.surface]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: hovered ? colors.primary : colors.outlineVariant),
          boxShadow: hovered
              ? [
                  BoxShadow(
                      color: colors.primary.withValues(alpha: .15),
                      blurRadius: 12)
                ]
              : [],
        ),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 30, color: colors.primary),
                      const SizedBox(height: 12),
                      Flexible(
                          child: Text(widget.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface))),
                    ],
                  )),
            )),
      ),
    );
  }
}
