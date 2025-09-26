import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/module_empty_state.dart';
import '../controllers/messaging_controller.dart';

class MessagingView extends GetView<MessagingController> {
  const MessagingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = this.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
            onPressed: controller.refreshMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final error = controller.error.value;
              if (error != null) {
                return ModuleEmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load messages',
                  message: error,
                  actionLabel: 'Retry',
                  onAction: controller.refreshMessages,
                );
              }

              if (controller.messages.isEmpty) {
                return const ModuleEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No messages yet',
                  message: 'Start the conversation with a message below.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMine = controller.isOwnMessage(message);
                  final timestamp = DateFormat('MMM d, h:mm a')
                      .format(message.sentAt.toLocal());

                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isMine
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMine)
                                Text(
                                  message.senderName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isMine
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (!isMine)
                                const SizedBox(height: 4),
                              Text(
                                message.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isMine
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                timestamp,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isMine
                                      ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() {
            final error = controller.error.value;
            if (error == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            );
          }),
          _MessageComposer(controller: controller),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller});

  final MessagingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller.composerController,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Write a message…',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => controller.sendCurrentMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              final sending = controller.isSending.value;
              return FilledButton(
                onPressed: sending ? null : controller.sendCurrentMessage,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.square(48),
                  padding: const EdgeInsets.all(12),
                  shape: const CircleBorder(),
                ),
                child: sending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              );
            }),
          ],
        ),
      ),
    );
  }
}
