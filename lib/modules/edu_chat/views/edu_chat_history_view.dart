import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/edu_chat_controller.dart';
import '../models/edu_chat_thread.dart';
import '../routes.dart';

class EduChatHistoryView extends GetView<EduChatController> {
  const EduChatHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('edu_chat_history_title'.tr),
      ),
      body: SafeArea(
        child: Obx(() {
          final threads = controller.threads;
          final isLoadingThreads =
              controller.isLoading.value && threads.isEmpty;
          final error = controller.loadError.value;

          if (isLoadingThreads) {
            return const Center(child: CircularProgressIndicator());
          }

          if (error != null && threads.isEmpty) {
            return _EduChatHistoryError(
              message: error,
              onRetry: controller.retry,
            );
          }

          if (threads.isEmpty) {
            return _EduChatHistoryEmpty(
              onStartNew: _startNewConversation,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'edu_chat_history_subtitle'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    return _EduChatHistoryTile(
                      index: index,
                      thread: thread,
                      onTap: () => _openConversation(thread),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: Obx(() {
        final isCreating = controller.isCreatingThread.value;
        return FloatingActionButton.extended(
          onPressed: isCreating ? null : _startNewConversation,
          icon: isCreating
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.add_comment_outlined),
          label: Text('edu_chat_history_start_new'.tr),
        );
      }),
    );
  }

  Future<void> _openConversation(EduChatThread thread) async {
    await controller.selectThread(thread.id);
    Get.toNamed(EduChatRoutes.chat);
  }

  Future<void> _startNewConversation() async {
    final newId = await controller.startNewChat();
    if (newId == null) {
      return;
    }
    Get.toNamed(EduChatRoutes.chat);
  }
}

class _EduChatHistoryTile extends StatelessWidget {
  const _EduChatHistoryTile({
    required this.index,
    required this.thread,
    required this.onTap,
  });

  final int index;
  final EduChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (thread.title?.isNotEmpty ?? false)
        ? thread.title!
        : 'edu_chat_conversation_default_title'
            .trParams({'index': '${index + 1}'});

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: const Icon(Icons.chat_bubble_outline),
      ),
      title: Text(title),
      subtitle: Text('edu_chat_history_continue'.tr),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EduChatHistoryEmpty extends StatelessWidget {
  const _EduChatHistoryEmpty({required this.onStartNew});

  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'edu_chat_history_empty_title'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'edu_chat_history_empty_message'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onStartNew,
              icon: const Icon(Icons.add_comment_outlined),
              label: Text('edu_chat_history_start_new'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _EduChatHistoryError extends StatelessWidget {
  const _EduChatHistoryError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 72, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('common_retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
