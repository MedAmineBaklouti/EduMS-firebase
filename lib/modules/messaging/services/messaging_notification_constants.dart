/// Common notification channel constants shared between the messaging
/// foreground/background handlers and the FCM v1 payload builder.
const String messagingNotificationChannelId = 'messaging_channel';
const String messagingNotificationChannelName = 'Messaging notifications';
const String messagingNotificationChannelDescription =
    'Notifications for new chat messages.';

/// Name of the Android status bar icon that should be used for chat notifications.
const String messagingNotificationIcon = '@drawable/ic_stat_notification';

/// Builds a stable notification identifier for the provided [conversationId].
///
/// Using a deterministic identifier allows us to replace and dismiss
/// notifications when a conversation is opened from inside the app.
int messagingNotificationIdForConversation(String conversationId) {
  if (conversationId.isEmpty) {
    return 0;
  }
  return conversationId.hashCode & 0x7fffffff;
}

/// Generates a platform notification tag that groups messages for the same
/// conversation.
String messagingNotificationTagForConversation(String conversationId) =>
    'conversation_$conversationId';
