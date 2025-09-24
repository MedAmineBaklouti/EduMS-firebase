import 'package:flutter/material.dart';

class AttendanceDateCard extends StatelessWidget {
  const AttendanceDateCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}
