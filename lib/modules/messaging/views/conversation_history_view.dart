import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/widgets/module_empty_state.dart';
import '../controllers/messaging_controller.dart';
import 'widgets/scrollable_placeholder.dart';

class ConversationHistoryView extends StatelessWidget {
  const ConversationHistoryView({super.key, required this.controller});

  final MessagingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'messaging_search_conversations_hint'.tr,
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshConversations,
            edgeOffset: 12,
            child: Obx(() {
              final _ = controller.contacts.length;
              if (controller.isConversationsLoading.value) {
                return ScrollablePlaceholder(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('messaging_loading_conversations'.tr),
                    ],
                  ),
                );
              }

              final error = controller.conversationsError.value;
              if (error != null) {
                return ScrollablePlaceholder(
                  child: ModuleEmptyState(
                    icon: Icons.error_outline,
                    title: 'messaging_conversations_error_title'.tr,
                    message: error,
                    actionLabel: 'common_retry'.tr,
                    onAction: controller.refreshConversations,
                  ),
                );
              }

              final conversations = controller.filteredConversations;
              if (conversations.isEmpty) {
                return ScrollablePlaceholder(
                  child: ModuleEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'messaging_empty_conversations_title'.tr,
                    message: 'messaging_empty_conversations_message'.tr,
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final hasUnread = conversation.unreadCount > 0;
                  final lastMessage = conversation.lastMessagePreview.isEmpty
                      ? 'messaging_no_messages_preview'.tr
                      : conversation.lastMessagePreview;
                  final timestamp = conversation.formattedTimestamp();
                  final displayTitle =
                      controller.resolveConversationTitle(conversation);
                  final contextLabel =
                      controller.resolveConversationContext(conversation);
                  final titleInitial = displayTitle.isEmpty
                      ? '?'
                      : displayTitle.characters.first.toUpperCase();
                  final showAdministrationAvatar =
                      controller.shouldUseAdministrationAvatar(conversation);
                  return Dismissible(
                    key: ValueKey('messagingConversation-${conversation.id}'),
                    direction: DismissDirection.endToStart,
                    background: const _MessagingDismissBackground(),
                    confirmDismiss: (_) async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title:
                                Text('messaging_confirm_delete_title'.tr),
                            content:
                                Text('messaging_confirm_delete_message'.tr),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: Text('common_cancel'.tr),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
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

                      final success =
                          await controller.deleteConversation(conversation);
                      return success;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: hasUnread
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () =>
                            controller.selectConversation(conversation),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: showAdministrationAvatar
                              ? Colors.transparent
                              : theme.colorScheme.primary.withOpacity(0.12),
                          foregroundColor: showAdministrationAvatar
                              ? Colors.transparent
                              : theme.colorScheme.primary,
                          backgroundImage: showAdministrationAvatar
                              ? const AssetImage('assets/icon/icon.png')
                              : null,
                          child: showAdministrationAvatar
                              ? null
                              : Text(titleInitial),
                        ),
                        title: Text(
                          displayTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (contextLabel != null &&
                                contextLabel.isNotEmpty) ...[
                              Text(
                                contextLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timestamp,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MessagingDismissBackground extends StatelessWidget {
  const _MessagingDismissBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsetsDirectional.only(end: 20),
      child: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.onErrorContainer,
      ),
    );
  }
}
