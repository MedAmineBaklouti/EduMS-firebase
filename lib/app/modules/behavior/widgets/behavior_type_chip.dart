import 'package:flutter/material.dart';

import '../../../data/models/behavior_model.dart';

class BehaviorTypeChip extends StatelessWidget {
  const BehaviorTypeChip({super.key, required this.type, this.compact = false});

  final BehaviorType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = type == BehaviorType.positive
        ? Icons.thumb_up_alt_outlined
        : Icons.report_outlined;
    final Color textColor;
    final Color background;

    if (type == BehaviorType.positive) {
      textColor = Colors.green.shade600;
      background = Colors.green.shade50;
    } else {
      textColor = Colors.red.shade600;
      background = Colors.red.shade50;
    }
    return Chip(
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      avatar: Icon(
        icon,
        size: compact ? 16 : 18,
        color: textColor,
      ),
      label: Text(type.label),
      backgroundColor: background,
      labelStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.transparent),
      ),
    );
  }
}
