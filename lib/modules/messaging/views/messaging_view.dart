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
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            centerTitle: false,
            leading: () {
              if (viewMode == MessagingViewMode.conversationThread) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'messaging_back_to_conversations'.tr,
                  onPressed: controller.clearActiveConversation,
                );
              }
              if (canPop) {
                return IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'common_back'.tr,
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
                        'messaging_title'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'messaging_subtitle'.tr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  );
                case MessagingViewMode.conversationThread:
                  if (activeConversation == null) {
                    return const SizedBox.shrink();
                  }
                  final showAdministrationAvatar = controller
                      .shouldUseAdministrationAvatar(activeConversation);
                  final titleText =
                      controller.resolveConversationTitle(activeConversation);
                  final contextText =
                      controller.resolveConversationContext(activeConversation);
                  final titleInitial = titleText.isEmpty
                      ? '?'
                      : titleText.characters.first.toUpperCase();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: showAdministrationAvatar
                            ? Colors.transparent
                            : theme.colorScheme.primary.withOpacity(0.12),
                        foregroundColor: showAdministrationAvatar
                            ? Colors.transparent
                            : theme.colorScheme.primary,
                        backgroundImage: showAdministrationAvatar
                            ? const AssetImage('assets/icon/icon.png')
                            : null,
                        child:
                            showAdministrationAvatar ? null : Text(titleInitial),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              titleText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (contextText != null && contextText.isNotEmpty)
                              Text(
                                contextText,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      theme.colorScheme.onPrimary.withOpacity(0.85),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
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
                    child: Text('messaging_action_administration'.tr),
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
                  return ScrollablePlaceholder(
                    child: Text('messaging_select_conversation_hint'.tr),
                  );
                }
                return ConversationThreadView(controller: controller, theme: theme);
            }
          }(),
          floatingActionButton:
              viewMode == MessagingViewMode.conversationList
                  ? FloatingActionButton(
                      tooltip: 'messaging_fab_tooltip'.tr,
                      onPressed: openNewConversationDialog,
                      child: const Icon(Icons.add_comment_rounded),
                    )
                  : null,
        ),
      );
    });
  }
}
