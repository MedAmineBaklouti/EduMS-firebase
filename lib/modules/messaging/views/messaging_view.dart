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

    return WillPopScope(
      onWillPop: () async {
        final activeConversation = controller.activeConversation.value;
        if (activeConversation != null) {
          controller.clearActiveConversation();
          return false;
        }
        return true;
      },
      child: Scaffold(
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
          final _ = controller.contacts.length;
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

          final titleText = controller.resolveConversationTitle(active);
          final contextText = controller.resolveConversationContext(active);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titleText,
                style: theme.textTheme.titleMedium,
              ),
              if (contextText != null && contextText.isNotEmpty)
                Text(
                  contextText,
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
        floatingActionButton: Obx(() {
          final active = controller.activeConversation.value;
          if (active != null) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            tooltip: 'Start a new conversation',
            onPressed: () => _showNewConversationSheet(context, controller),
            child: const Icon(Icons.add_comment_rounded),
          );
        }),
      ),
    );
  }

  void _showNewConversationSheet(
    BuildContext context,
    MessagingController controller,
  ) {
    final searchController = TextEditingController();
    final query = ValueNotifier<String>('');

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final mediaQuery = MediaQuery.of(context);

        Color resolveRoleColor(String role) {
          final normalized = role.toLowerCase();
          switch (normalized) {
            case 'teacher':
              return theme.colorScheme.primary;
            case 'parent':
              return theme.colorScheme.tertiary;
            case 'admin':
              return theme.colorScheme.secondary;
            default:
              return theme.colorScheme.primary;
          }
        }

        String resolveRoleLabel(String role) {
          if (role.isEmpty) {
            return 'Contact';
          }
          return role[0].toUpperCase() + role.substring(1).toLowerCase();
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: mediaQuery.viewInsets.bottom + 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a conversation',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search by name, role, or relationship to connect instantly.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: 'Search contacts…',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) => query.value = value.toLowerCase().trim(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: query,
                      builder: (context, filter, _) {
                        return Obx(() {
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
                              onAction: controller.refreshContacts,
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

                          final lowerFilter = filter.trim();
                          final filtered = lowerFilter.isEmpty
                              ? contacts.toList()
                              : contacts.where((contact) {
                                  final name = contact.name.toLowerCase();
                                  final role = contact.role.toLowerCase();
                                  final relationship =
                                      contact.relationship?.toLowerCase() ?? '';
                                  return name.contains(lowerFilter) ||
                                      role.contains(lowerFilter) ||
                                      relationship.contains(lowerFilter);
                                }).toList();

                          if (filtered.isEmpty) {
                            return ModuleEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No matches found',
                              message: 'Try searching with a different name or role.',
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final contact = filtered[index];
                              final roleLabel = resolveRoleLabel(contact.role);
                              final accentColor = resolveRoleColor(contact.role);
                              final relationship = contact.relationship;
                              final initial = contact.name.isEmpty
                                  ? '?'
                                  : contact.name.characters.first.toUpperCase();

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    controller.startConversationWithContact(contact);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant
                                          .withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: accentColor.withOpacity(0.18),
                                          foregroundColor: accentColor,
                                          radius: 26,
                                          child: Text(initial),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                contact.name,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (relationship != null &&
                                                  relationship.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    relationship,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: accentColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  roleLabel,
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      searchController.dispose();
      query.dispose();
    });
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
              final _ = controller.contacts.length;
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
                  final displayTitle =
                      controller.resolveConversationTitle(conversation);
                  final contextLabel =
                      controller.resolveConversationContext(conversation);
                  final titleInitial = displayTitle.isEmpty
                      ? '?'
                      : displayTitle.characters.first.toUpperCase();

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
                        displayTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w600,
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
    return Obx(() {
      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshMessages,
              edgeOffset: 12,
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
                      bottomLeft: isMine
                          ? const Radius.circular(20)
                          : const Radius.circular(8),
                      bottomRight: isMine
                          ? const Radius.circular(8)
                          : const Radius.circular(20),
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
    });
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
