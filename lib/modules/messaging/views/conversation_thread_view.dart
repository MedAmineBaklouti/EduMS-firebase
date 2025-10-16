import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../../common/widgets/module_empty_state.dart';
import '../controllers/messaging_controller.dart';
import 'widgets/scrollable_placeholder.dart';

class ConversationThreadView extends StatefulWidget {
  const ConversationThreadView({
    super.key,
    required this.controller,
    required this.theme,
  });

  final MessagingController controller;
  final ThemeData theme;

  @override
  State<ConversationThreadView> createState() => _ConversationThreadViewState();
}

class _ConversationThreadViewState extends State<ConversationThreadView>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  Worker? _messagesWorker;
  Worker? _conversationWorker;
  String? _lastScrollSignature;

  MessagingController get _controller => widget.controller;
  ThemeData get _theme => widget.theme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messagesWorker = ever<List<MessageModel>>(
      _controller.messages,
      _handleMessagesUpdated,
    );
    _conversationWorker = ever<ConversationModel?>(
      _controller.activeConversation,
      _handleActiveConversationChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToBottom(immediate: true, force: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messagesWorker?.dispose();
    _conversationWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (bottomInset > 0) {
        _scrollToBottom(force: true);
      }
    });
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) {
      return true;
    }
    final position = _scrollController.position;
    final distanceFromStart =
        (position.pixels - position.minScrollExtent).abs();
    return distanceFromStart <= 120;
  }

  void _handleMessagesUpdated(List<MessageModel> messages) {
    if (!mounted) {
      return;
    }

    if (messages.isEmpty) {
      _lastScrollSignature = null;
      return;
    }

    final latest = messages.last;
    final signature =
        '${latest.id}_${messages.length}_${latest.sentAt.millisecondsSinceEpoch}';

    if (_lastScrollSignature == signature) {
      return;
    }

    _lastScrollSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToBottom(force: true);
    });
  }

  void _handleActiveConversationChanged(ConversationModel? conversation) {
    if (!mounted) {
      return;
    }
    if (conversation == null) {
      _lastScrollSignature = null;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToBottom(immediate: true, force: true);
    });
  }

  void _scrollToBottom({bool immediate = false, bool force = false}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final target = position.minScrollExtent;

    if (!force && !_isNearBottom) {
      return;
    }

    if (immediate) {
      _scrollController.jumpTo(target);
      return;
    }

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final theme = _theme;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshMessages,
            edgeOffset: 12,
            child: Obx(() {
              if (controller.isMessagesLoading.value) {
                return const ScrollablePlaceholder(
                  child: CircularProgressIndicator(),
                );
              }

              final error = controller.messageError.value;
              if (error != null) {
                return ScrollablePlaceholder(
                  child: ModuleEmptyState(
                    icon: Icons.error_outline,
                    title: 'messaging_messages_error_title'.tr,
                    message: error,
                    actionLabel: 'common_retry'.tr,
                    onAction: controller.refreshMessages,
                  ),
                );
              }

              if (controller.messages.isEmpty) {
                return ScrollablePlaceholder(
                  child: ModuleEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'messaging_thread_empty_title'.tr,
                    message: 'messaging_thread_empty_message'.tr,
                  ),
                );
              }

              final messages = controller.messages;

              return ListView.separated(
                controller: _scrollController,
                reverse: true,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
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
                          color: backgroundGradient == null ? backgroundColor : null,
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
                                      'messaging_badge_new'.tr,
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
                                      (isReadByOthers
                                              ? 'messaging_status_read'
                                              : 'messaging_status_unread')
                                          .tr,
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
        MessageComposer(controller: controller),
      ],
    );
  }
}

class MessageComposer extends StatelessWidget {
  const MessageComposer({super.key, required this.controller});

  final MessagingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 6,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: controller.composerController,
                          minLines: 1,
                          maxLines: 6,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          cursorColor: theme.colorScheme.primary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'messaging_input_hint'.tr,
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                          ),
                          onSubmitted: (_) => controller.sendCurrentMessage(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() {
                  final sending = controller.isSending.value;
                  return Tooltip(
                    message: sending
                        ? 'messaging_sending'.tr
                        : 'messaging_send_button_tooltip'.tr,
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
