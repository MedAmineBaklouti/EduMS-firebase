import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ai_chat_controller.dart';

class AiChatView extends GetView<AiChatController> {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('drawer_ask_something'.tr),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final messages = controller.messages;

                if (messages.isEmpty) {
                  return const _AiChatEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  reverse: true,
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message =
                        messages[messages.length - 1 - index];
                    final isUser = message.isUser;
                    final alignment =
                        isUser ? Alignment.centerRight : Alignment.centerLeft;
                    final backgroundColor = isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceVariant.withOpacity(0.6);
                    final textColor = isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface;

                    return Align(
                      alignment: alignment,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(18).copyWith(
                              bottomLeft: Radius.circular(isUser ? 18 : 6),
                              bottomRight: Radius.circular(isUser ? 6 : 18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              message.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            Obx(
              () => controller.isLoading.value
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.inputController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        FocusScope.of(context).unfocus();
                        controller.sendMessage();
                      },
                      decoration: InputDecoration(
                        hintText: 'ai_chat_input_hint'.tr,
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceVariant.withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return SizedBox(
                        height: 48,
                        width: 48,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }

                    return FilledButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        controller.sendMessage();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        shape: const CircleBorder(),
                      ),
                      child: const Icon(Icons.send_rounded),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatEmptyState extends StatelessWidget {
  const _AiChatEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'ai_chat_empty_title'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ai_chat_empty_message'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
