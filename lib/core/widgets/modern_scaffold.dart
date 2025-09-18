import 'package:flutter/material.dart';

/// A convenience scaffold that applies the app's modern gradient background
/// and consistent horizontal padding to every view.
class ModernScaffold extends StatelessWidget {
  const ModernScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.padding,
    this.alignment,
    this.extendBodyBehindAppBar = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: alignment ?? Alignment.topCenter,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: body,
          ),
        ),
      ),
    );
  }
}
