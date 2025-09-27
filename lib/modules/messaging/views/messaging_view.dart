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
        automaticallyImplyLeading: false,
        leading: Obx(() {
          final active = controller.activeConversation.value;
          if (active == null) {
            return const SizedBox.shrink();
          }
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to conversations',
            onPressed: controller.clearActiveConversation,
          );
        }),
        title: Obx(() {
          final active = controller.activeConversation.value;
          return Text(active?.title ?? 'Messaging');
        }),
        actions: [
          Obx(() {
            final active = controller.activeConversation.value;
            return IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: active == null
                  ? 'Refresh conversations'
                  : 'Refresh messages',
              onPressed: active == null
                  ? controller.refreshConversations
                  : controller.refreshMessages,
            );
          }),
        ],
      ),
      body: Obx(() {
        final active = controller.activeConversation.value;
        if (active == null) {
          return _ConversationHistory(controller: controller);
        }
        return _ConversationThread(controller: controller, theme: theme);
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversationSheet(context, controller),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  void _showNewConversationSheet(
    BuildContext context,
    MessagingController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a conversation',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (controller.isContactsLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final error = controller.contactsError.value;
                  if (error != null) {
                    return ModuleEmptyState(
                      icon: Icons.error_outline,
                      title: 'Unable to load contacts',
                      message: error,
                      actionLabel: 'Retry',
                      onAction: () {
                        controller.refreshContacts();
                      },
                    );
                  }

                  final contacts = controller.contacts;
                  if (contacts.isEmpty) {
                    return const ModuleEmptyState(
                      icon: Icons.people_outline,
                      title: 'No available contacts',
                      message:
                          'You currently do not have anyone to message based on your assignments.',
                    );
                  }

                  return ListView.separated(
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final normalizedRole = contact.role.toLowerCase();
                      final roleLabel = normalizedRole.isEmpty
                          ? 'Contact'
                          : normalizedRole[0].toUpperCase() +
                              normalizedRole.substring(1);
                      final subtitle = contact.relationship?.isNotEmpty == true
                          ? '$roleLabel • ${contact.relationship}'
                          : roleLabel;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(contact.name.isEmpty
                              ? '?'
                              : contact.name.characters.first.toUpperCase()),
                        ),
                        title: Text(contact.name),
                        subtitle: Text(subtitle),
                        onTap: () {
                          Navigator.of(context).pop();
                          controller.startConversationWithContact(contact);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConversationHistory extends StatelessWidget {
  const _ConversationHistory({required this.controller});

  final MessagingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: controller.searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search conversations',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isConversationsLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final error = controller.conversationsError.value;
            if (error != null) {
              return ModuleEmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load conversations',
                message: error,
                actionLabel: 'Retry',
                onAction: () {
                  controller.refreshConversations();
                },
              );
            }

            if (controller.filteredConversations.isEmpty) {
              return const ModuleEmptyState(
                icon: Icons.forum_outlined,
                title: 'No conversations yet',
                message:
                    'Start a new conversation with the button below to begin messaging.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              itemCount: controller.filteredConversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final conversation = controller.filteredConversations[index];
                final lastMessage = conversation.lastMessagePreview.isEmpty
                    ? 'No messages yet'
                    : conversation.lastMessagePreview;
                final timestamp = conversation.formattedTimestamp();
                final titleInitial = conversation.title.isEmpty
                    ? '?'
                    : conversation.title.characters.first.toUpperCase();
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    onTap: () => controller.selectConversation(conversation),
                    leading: CircleAvatar(
                      child: Text(titleInitial),
                    ),
                    title: Text(
                      conversation.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timestamp,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (conversation.unreadCount > 0)
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
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _ConversationThread extends StatelessWidget {
  const _ConversationThread({
    required this.controller,
    required this.theme,
  });

  final MessagingController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final active = controller.activeConversation.value;
    final participants = active?.participants
            .map((participant) => participant.name)
            .join(', ') ??
        '';
    final header = participants.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Participants: $participants',
              style: theme.textTheme.bodySmall,
            ),
          );

    return Column(
      children: [
        if (header != null) header,
        Expanded(
          child: Obx(() {
            if (controller.isMessagesLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final error = controller.messageError.value;
            if (error != null) {
              return ModuleEmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load messages',
                message: error,
                actionLabel: 'Retry',
                onAction: () {
                  controller.refreshMessages();
                },
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
                            if (!isMine) const SizedBox(height: 4),
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
          final error = controller.messageError.value;
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
