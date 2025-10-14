import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/edu_chat_controller.dart';
import 'widgets/edu_chat_message_bubble.dart';

class EduChatView extends GetView<EduChatController> {
  const EduChatView({super.key});

  static const _suggestions = [
    'Explain recursion with a simple Dart example.',
    'Who is Messi?',
    'Balance Fe + O₂ → Fe₂O₃ step by step.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('edu_chat_title'.tr),
      ),
      body: Column(
        children: [
          Expanded(
            child: _MessagesList(
              controller: controller,
              emptyBuilder: _buildEmptyState,
            ),
          ),
          _buildComposer(theme: theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'edu_chat_empty_state_title'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'edu_chat_empty_state_message'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _suggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () => controller.sendSuggestion(suggestion),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer({required ThemeData theme}) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Obx(
                () => TextField(
                  controller: controller.composerController,
                  minLines: 1,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  enabled: controller.loadError.value == null,
                  decoration: InputDecoration(
                    hintText: 'edu_chat_input_hint'.tr,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              final isSending = controller.isSending.value;
              final canSend =
                  controller.inputText.value.trim().isNotEmpty &&
                      !isSending &&
                      controller.loadError.value == null;
              return SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  onPressed:
                      canSend ? () => controller.sendMessage() : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(Icons.send_rounded,
                          color: theme.colorScheme.onPrimary),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.controller,
    required this.emptyBuilder,
  });

  final EduChatController controller;
  final Widget Function(BuildContext context) emptyBuilder;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final error = controller.loadError.value;
      if (error != null) {
        return _ErrorState(message: error, onRetry: controller.retry);
      }

      final items = controller.messages;
      if (items.isEmpty) {
        return emptyBuilder(context);
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final message = items[index];
          final isUser = message.role == 'user';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EduChatMessageBubble(
              message: message,
              isCurrentUser: isUser,
              onCopy: () => controller.copyToClipboard(message.content),
            ),
          );
        },
      );
    });
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('edu_chat_try_again'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
