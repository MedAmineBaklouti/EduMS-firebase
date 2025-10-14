import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/edu_chat_message.dart';

class EduChatMessageBubble extends StatelessWidget {
  const EduChatMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.onCopy,
  });

  final EduChatMessage message;
  final bool isCurrentUser;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = _bubbleColor(theme);
    final textColor = _textColor(theme);

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: onCopy,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
              bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
            ),
            border: message.role == 'system'
                ? Border.all(color: theme.colorScheme.outlineVariant)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.role == 'system')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'edu_chat_system_label'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontStyle:
                        message.role == 'system' ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (message.model != null || message.tokens != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.model != null)
                          Text(
                            message.model!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        if (message.model != null && message.tokens != null)
                          Text(
                            ' · ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        if (message.tokens != null)
                          Text(
                            '${message.tokens} tokens',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _bubbleColor(ThemeData theme) {
    if (message.role == 'system') {
      return theme.colorScheme.surfaceVariant;
    }
    if (isCurrentUser) {
      return theme.colorScheme.primary;
    }
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceVariant
        : theme.colorScheme.surface;
  }

  Color _textColor(ThemeData theme) {
    if (message.role == 'system') {
      return theme.colorScheme.onSurfaceVariant;
    }
    if (isCurrentUser) {
      return theme.colorScheme.onPrimary;
    }
    return theme.colorScheme.onSurface;
  }
}
