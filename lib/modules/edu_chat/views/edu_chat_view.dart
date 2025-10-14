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
    final navigator = Navigator.of(context);
    final canPop = navigator.canPop();

    return Obx(() {
      final viewMode = controller.activeView.value;
      final activeThread = controller.activeThread;
      final isCreating = controller.isCreatingThread.value;

      return WillPopScope(
        onWillPop: () async {
          if (viewMode == EduChatViewMode.threadConversation) {
            controller.showThreadList();
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: () {
              if (viewMode == EduChatViewMode.threadConversation) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'common_back'.tr,
                  onPressed: controller.showThreadList,
                );
              }
              if (canPop) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'common_back'.tr,
                  onPressed: () => navigator.maybePop(),
                );
              }
              return null;
            }(),
            title: () {
              if (viewMode == EduChatViewMode.threadConversation &&
                  activeThread != null) {
                final titleText = controller.resolveThreadTitle(activeThread);
                final timestamp =
                    controller.formatThreadUpdatedAt(activeThread);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.appBarTheme.foregroundColor ??
                            theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timestamp != null)
                      Text(
                        'edu_chat_thread_updated'
                            .trParams({'timestamp': timestamp}),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: (theme.appBarTheme.foregroundColor ??
                                  theme.colorScheme.onPrimary)
                              .withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                );
              }
              return Text('edu_chat_title'.tr);
            }(),
            actions: [
              IconButton(
                tooltip: 'edu_chat_new_conversation'.tr,
                onPressed: isCreating ? null : controller.startNewChat,
                icon: isCreating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.appBarTheme.foregroundColor ??
                                theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.add_comment_outlined),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: viewMode == EduChatViewMode.threadList
                ? _ThreadHistoryList(
                    key: const ValueKey('eduChatThreadList'),
                    controller: controller,
                  )
                : activeThread == null
                    ? Center(
                        key: const ValueKey('eduChatConversationPlaceholder'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Text(
                            'edu_chat_select_thread_hint'.tr,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        key: const ValueKey('eduChatConversation'),
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
          ),
        ),
      );
    });
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

class _ThreadHistoryList extends StatelessWidget {
  const _ThreadHistoryList({super.key, required this.controller});

  final EduChatController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'edu_chat_history_label'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final threads = controller.threads;
            final error = controller.loadError.value;
            final isLoading = controller.isLoading.value && threads.isEmpty;
            final isCreating = controller.isCreatingThread.value;

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (threads.isEmpty) {
              if (error != null) {
                return _ErrorState(message: error, onRetry: controller.retry);
              }
              return _HistoryEmptyState(
                onNewConversation: controller.startNewChat,
                isCreating: isCreating,
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final thread = threads[index];
                final title = controller.resolveThreadTitle(thread);
                final timestamp = controller.formatThreadUpdatedAt(thread);
                return Dismissible(
                  key: ValueKey('eduChatThread-${thread.id}'),
                  direction: DismissDirection.endToStart,
                  background: _DismissibleDeleteBackground(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  confirmDismiss: (_) async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: Text('edu_chat_confirm_delete_title'.tr),
                          content:
                              Text('edu_chat_confirm_delete_message'.tr),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext)
                                  .pop(false),
                              child: Text('common_cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext)
                                  .pop(true),
                              child: Text(
                                'common_delete'.tr,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    if (shouldDelete != true) {
                      return false;
                    }

                    final success = await controller.deleteThread(thread);
                    return success;
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => controller.selectThread(thread.id),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.12),
                        foregroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.chat_bubble_outline),
                      ),
                      title: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: timestamp != null
                          ? Text(
                              'edu_chat_thread_updated'
                                  .trParams({'timestamp': timestamp}),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _DismissibleDeleteBackground extends StatelessWidget {
  const _DismissibleDeleteBackground({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsetsDirectional.only(end: 20),
      child: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.onErrorContainer,
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    required this.onNewConversation,
    required this.isCreating,
  });

  final VoidCallback onNewConversation;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
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
              onPressed: isCreating ? null : onNewConversation,
              icon: isCreating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.add_comment_outlined),
              label: Text('edu_chat_new_conversation'.tr),
            ),
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
