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
    final navigator = Navigator.of(context);
    final canPop = navigator.canPop();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: Obx(() {
          final active = controller.activeConversation.value;
          if (active != null) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to conversations',
              onPressed: controller.clearActiveConversation,
            );
          }
          if (canPop) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () {
                navigator.maybePop();
              },
            );
          }
          return const SizedBox.shrink();
        }),
        title: Obx(() {
          final active = controller.activeConversation.value;
          if (active == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Messaging',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'Stay connected with your school community',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            );
          }

          final participantNames = active.participants
              .map((participant) => participant.name)
              .where((name) => name.isNotEmpty)
              .join(', ');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                active.title,
                style: theme.textTheme.titleMedium,
              ),
              if (participantNames.isNotEmpty)
                Text(
                  participantNames,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          );
        }),
      ),
      body: Obx(() {
        final active = controller.activeConversation.value;
        if (active == null) {
          return _ConversationHistory(controller: controller);
        }
        return _ConversationThread(controller: controller, theme: theme);
      }),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Start a new conversation',
        onPressed: () => _showNewConversationSheet(context, controller),
        child: const Icon(Icons.add_comment_rounded),
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search conversations',
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
              if (controller.isConversationsLoading.value) {
                return _ScrollablePlaceholder(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading conversations…'),
                    ],
                  ),
                );
              }

              final error = controller.conversationsError.value;
              if (error != null) {
                return _ScrollablePlaceholder(
                  child: ModuleEmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to load conversations',
                    message: error,
                    actionLabel: 'Retry',
                    onAction: controller.refreshConversations,
                  ),
                );
              }

              final conversations = controller.filteredConversations;
              if (conversations.isEmpty) {
                return const _ScrollablePlaceholder(
                  child: ModuleEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No conversations yet',
                    message:
                        'Start a new conversation with the button below to begin messaging.',
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
                      ? 'No messages yet'
                      : conversation.lastMessagePreview;
                  final timestamp = conversation.formattedTimestamp();
                  final titleInitial = conversation.title.isEmpty
                      ? '?'
                      : conversation.title.characters.first.toUpperCase();

                  return AnimatedContainer(
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
                      onTap: () => controller.selectConversation(conversation),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.12),
                        foregroundColor: theme.colorScheme.primary,
                        child: Text(titleInitial),
                      ),
                      title: Text(
                        conversation.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

class _ScrollablePlaceholder extends StatelessWidget {
  const _ScrollablePlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: child),
            ),
          ],
        );
      },
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        participants,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

    return Column(
      children: [
        if (header != null) header,
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshMessages,
            edgeOffset: header == null ? 12 : 0,
            child: Obx(() {
              if (controller.isMessagesLoading.value) {
                return const _ScrollablePlaceholder(
                  child: CircularProgressIndicator(),
                );
              }

              final error = controller.messageError.value;
              if (error != null) {
                return _ScrollablePlaceholder(
                  child: ModuleEmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to load messages',
                    message: error,
                    actionLabel: 'Retry',
                    onAction: controller.refreshMessages,
                  ),
                );
              }

              if (controller.messages.isEmpty) {
                return const _ScrollablePlaceholder(
                  child: ModuleEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No messages yet',
                    message: 'Start the conversation with a message below.',
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: controller.messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMine = controller.isOwnMessage(message);
                  final isUnread = controller.isMessageUnread(message);
                  final timestamp = DateFormat('MMM d, h:mm a')
                      .format(message.sentAt.toLocal());
                  final isReadByOthers =
                      isMine && controller.isMessageReadByOthers(message);

                  final backgroundGradient = isMine
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null;

                  final backgroundColor = isMine
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface;

                  final borderRadius = BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft:
                        isMine ? const Radius.circular(20) : const Radius.circular(8),
                    bottomRight:
                        isMine ? const Radius.circular(8) : const Radius.circular(20),
                  );

                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: backgroundGradient == null
                              ? backgroundColor
                              : null,
                          gradient: backgroundGradient,
                          borderRadius: borderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
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
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (!isMine && isUnread) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'New',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                              else if (!isMine)
                                const SizedBox(height: 6),
                              Text(
                                message.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isMine
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: isMine
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Text(
                                    timestamp,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isMine
                                          ? theme.colorScheme.onPrimary
                                              .withOpacity(0.75)
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isMine) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      isReadByOthers
                                          ? Icons.done_all_rounded
                                          : Icons.check_rounded,
                                      size: 16,
                                      color: theme.colorScheme.onPrimary
                                          .withOpacity(isReadByOthers ? 0.9 : 0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isReadByOthers ? 'Read' : 'Unread',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimary
                                            .withOpacity(0.85),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller.composerController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Write a message…',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => controller.sendCurrentMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() {
                  final sending = controller.isSending.value;
                  return Tooltip(
                    message: sending ? 'Sending…' : 'Send message',
                    child: FilledButton(
                      onPressed: sending ? null : controller.sendCurrentMessage,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size.square(52),
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: sending
                            ? SizedBox(
                                key: const ValueKey('progress'),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                key: ValueKey('icon'),
                              ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
