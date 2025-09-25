import 'package:flutter/material.dart';

enum AttendanceDateCardStyle { surface, primary }

class AttendanceDateCard extends StatelessWidget {
  const AttendanceDateCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.style = AttendanceDateCardStyle.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AttendanceDateCardStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(24);

    if (style == AttendanceDateCardStyle.primary) {
      final gradient = LinearGradient(
        colors: [
          theme.colorScheme.primary.withOpacity(
            theme.brightness == Brightness.dark ? 0.95 : 0.88,
          ),
          theme.colorScheme.primary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(
                theme.brightness == Brightness.dark ? 0.35 : 0.22,
              ),
              blurRadius: 30,
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
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(
                          theme.brightness == Brightness.dark ? 0.08 : 0.16,
                        ),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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

    final background = Color.lerp(
      theme.colorScheme.surface,
      theme.colorScheme.primaryContainer,
      theme.brightness == Brightness.dark ? 0.35 : 0.75,
    );
    final highlight = theme.colorScheme.primary.withOpacity(
      theme.brightness == Brightness.dark ? 0.25 : 0.18,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: background,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(
            theme.brightness == Brightness.dark ? 0.35 : 0.22,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(
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
                  gradient: LinearGradient(
                    colors: [highlight, Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
