import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/conversation_model.dart';
import '../controllers/messaging_controller.dart';
import '../widgets/message_bubble.dart';

class MessagingView extends StatelessWidget {
  MessagingView({super.key});

  final MessagingController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.06),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final conversationPanel = _ConversationPanel(
                    controller: controller,
                    isWide: isWide,
                  );
                  final chatPanel = _ChatPanel(
                    controller: controller,
                    isWide: isWide,
                  );
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: conversationPanel),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: chatPanel),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(child: conversationPanel),
                      const SizedBox(height: 16),
                      Expanded(child: chatPanel),
                    ],
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({
    required this.controller,
    required this.isWide,
  });

  final MessagingController controller;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isWide ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start a new conversation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _RecipientDropdown(controller: controller),
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'Recent conversations',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final conversations = controller.conversations;
                if (conversations.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.forum_outlined,
                    message: 'No conversations yet. Choose a contact to start chatting.',
                  );
                }
                return ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final recipient =
                        controller.recipientForConversation(conversation);
                    final isSelected =
                        controller.selectedConversation.value?.id ==
                            conversation.id;
                    return _ConversationTile(
                      conversation: conversation,
                      recipientName: recipient?.name ?? 'Conversation',
                      subtitle: recipient?.subtitle ?? recipient?.role ?? '',
                      isSelected: isSelected,
                      hasUnread: controller.hasUnreadMessages(conversation),
                      onTap: () => controller.openConversation(conversation),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientDropdown extends StatelessWidget {
  const _RecipientDropdown({required this.controller});

  final MessagingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isLoading = controller.isRecipientsLoading.value;
      final recipients = controller.recipients;
      final selected = controller.selectedRecipient.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<MessagingRecipient>(
            value: recipients.contains(selected) ? selected : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Select contact',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            ),
            items: recipients
                .map((recipient) => DropdownMenuItem<MessagingRecipient>(
                      value: recipient,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recipient.name,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (recipient.subtitle != null)
                            Text(
                              recipient.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: isLoading ? null : controller.selectRecipient,
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      );
    });
  }
}

class _ConversationTile extends StatelessWidget {
  _ConversationTile({
    required this.conversation,
    required this.recipientName,
    required this.subtitle,
    required this.isSelected,
    required this.hasUnread,
    required this.onTap,
  }) : formattedTime = _timeFormatter.format(conversation.updatedAt);

  final ConversationModel conversation;
  final String recipientName;
  final String subtitle;
  final bool isSelected;
  final bool hasUnread;
  final VoidCallback onTap;

  final String formattedTime;

  static final DateFormat _timeFormatter = DateFormat('MMM d · h:mm a');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(recipientName);
    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                child: Text(
                  initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    formattedTime,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (hasUnread)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first.substring(0, 1).toUpperCase() : '?';
    }
    final first = parts.first.isNotEmpty ? parts.first.substring(0, 1) : '';
    final last = parts.last.isNotEmpty ? parts.last.substring(0, 1) : '';
    final combined = (first + last).toUpperCase();
    return combined.isEmpty ? '?' : combined;
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.controller,
    required this.isWide,
  });

  final MessagingController controller;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isWide ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChatHeader(controller: controller),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final messages = controller.messages;
              if (messages.isEmpty) {
                return _EmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: controller.selectedRecipient.value == null
                      ? 'Pick a contact to start the conversation.'
                      : 'Say hello! This conversation is waiting for its first message.',
                );
              }
              return ListView.separated(
                controller: controller.messageScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = message.senderId == controller.currentUserId;
                  return MessageBubble(
                    message: message,
                    isMine: isMine,
                  );
                },
              );
            }),
          ),
          const Divider(height: 1),
          _MessageComposer(controller: controller),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.controller});

  final MessagingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final recipient = controller.selectedRecipient.value;
      if (recipient == null) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Select a contact to view messages',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      final initials = _initials(recipient.name);
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Text(
                initials,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  recipient.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (recipient.subtitle != null)
                  Text(
                    recipient.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                Text(
                  recipient.role.capitalizeFirst ?? recipient.role,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first.substring(0, 1).toUpperCase() : '?';
    }
    final first = parts.first.isNotEmpty ? parts.first.substring(0, 1) : '';
    final last = parts.last.isNotEmpty ? parts.last.substring(0, 1) : '';
    final combined = (first + last).toUpperCase();
    return combined.isEmpty ? '?' : combined;
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller});

  final MessagingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final isEnabled = controller.selectedRecipient.value != null;
              return TextField(
                controller: controller.messageController,
                enabled: isEnabled && !controller.isSending.value,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: isEnabled
                      ? 'Write your message...'
                      : 'Choose a contact to enable messaging',
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceVariant.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                textInputAction: TextInputAction.newline,
              );
            }),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final canSend = controller.selectedRecipient.value != null &&
                !controller.isSending.value &&
                controller.draftText.value.trim().isNotEmpty;
            return ElevatedButton.icon(
              onPressed: canSend ? controller.sendCurrentMessage : null,
              icon: controller.isSending.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
