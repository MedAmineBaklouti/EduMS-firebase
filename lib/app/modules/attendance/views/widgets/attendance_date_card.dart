import 'package:flutter/material.dart';

class AttendanceDateCard extends StatelessWidget {
  const AttendanceDateCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.backgroundColor,
    this.borderColor,
    this.shadowColor,
    this.overlayGradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final Gradient? overlayGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = backgroundColor ??
        Color.lerp(
          theme.colorScheme.surface,
          theme.colorScheme.primaryContainer,
          theme.brightness == Brightness.dark ? 0.35 : 0.75,
        );
    final highlight = theme.colorScheme.primary.withOpacity(
      theme.brightness == Brightness.dark ? 0.25 : 0.18,
    );
    final gradient = overlayGradient ??
        LinearGradient(
          colors: [highlight, Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    final radius = BorderRadius.circular(24);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: background,
        border: Border.all(
          color: borderColor ??
              theme.colorScheme.primary.withOpacity(
                theme.brightness == Brightness.dark ? 0.35 : 0.22,
              ),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor ??
                theme.colorScheme.primary.withOpacity(
                  theme.brightness == Brightness.dark ? 0.28 : 0.14,
                ),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: gradient,
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
