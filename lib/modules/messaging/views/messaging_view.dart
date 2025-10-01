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

      return WillPopScope(
        onWillPop: () async {
          if (viewMode == MessagingViewMode.conversationThread) {
            controller.clearActiveConversation();
            return false;
          }
          if (viewMode == MessagingViewMode.newConversation) {
            controller.showConversationListView();
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
              if (viewMode == MessagingViewMode.newConversation) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to conversations',
                  onPressed: controller.showConversationListView,
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
                case MessagingViewMode.newConversation:
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'New message',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Choose who you want to reach out to',
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
              case MessagingViewMode.newConversation:
                return NewConversationView(controller: controller);
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
                      onPressed: controller.showNewConversationView,
                      child: const Icon(Icons.add_comment_rounded),
                    )
                  : null,
        ),
      );
    });
  }
}
