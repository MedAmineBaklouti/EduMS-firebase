import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/messaging_controller.dart';
import 'conversation_history_view.dart';
import 'conversation_thread_view.dart';
import 'new_conversation_view.dart';
import 'widgets/scrollable_placeholder.dart';

class MessagingView extends GetView<MessagingController> {
  const MessagingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = this.controller;
    final navigator = Navigator.of(context);
    final canPop = navigator.canPop();

    return Obx(() {
      final viewMode = controller.activeView.value;
      final activeConversation = controller.activeConversation.value;

      Future<void> openNewConversationDialog() async {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            final mediaQuery = MediaQuery.of(dialogContext);
            final size = mediaQuery.size;
            final width = size.width * 0.95;
            final dialogWidth = width > 640 ? 640.0 : width;
            final heightLimit = size.height * 0.85;
            final dialogHeight = heightLimit > 720 ? 720.0 : heightLimit;
            return Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              backgroundColor: theme.colorScheme.surface,
              child: SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: NewConversationView(
                  controller: controller,
                  onClose: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            );
          },
        );
      }

      return WillPopScope(
        onWillPop: () async {
          if (viewMode == MessagingViewMode.conversationThread) {
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
            leading: () {
              if (viewMode == MessagingViewMode.conversationThread) {
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
              return null;
            }(),
            title: () {
              switch (viewMode) {
                case MessagingViewMode.conversationList:
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                case MessagingViewMode.conversationThread:
                  if (activeConversation == null) {
                    return const SizedBox.shrink();
                  }
                  var titleText =
                      controller.resolveConversationTitle(activeConversation);
                  final hasAdministrationParticipant = activeConversation
                      .participants
                      .any((participant) =>
                          participant.role.toLowerCase() == 'admin');
                  if (hasAdministrationParticipant) {
                    titleText = 'Administration';
                  }
                  final contextText =
                      controller.resolveConversationContext(activeConversation);
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
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  );
              }
            }(),
            actions: [
              if (controller.shouldShowAdministrationAction)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextButton(
                    onPressed: controller.startConversationWithAdministration,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('Administration'),
                  ),
                ),
            ],
          ),
          body: () {
            switch (viewMode) {
              case MessagingViewMode.conversationList:
                return ConversationHistoryView(controller: controller);
              case MessagingViewMode.conversationThread:
                if (activeConversation == null) {
                  return const ScrollablePlaceholder(
                    child: Text('Select a conversation to get started.'),
                  );
                }
                return ConversationThreadView(controller: controller, theme: theme);
            }
          }(),
          floatingActionButton:
              viewMode == MessagingViewMode.conversationList
                  ? FloatingActionButton(
                      tooltip: 'Start a new conversation',
                      onPressed: openNewConversationDialog,
                      child: const Icon(Icons.add_comment_rounded),
                    )
                  : null,
        ),
      );
    });
  }
}
