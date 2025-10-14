enum EduChatErrorType {
  unauthenticated,
  network,
  rateLimited,
  invalidResponse,
  unknown,
}

class EduChatException implements Exception {
  const EduChatException(
    this.message, {
    this.type = EduChatErrorType.unknown,
  });

  final String message;
  final EduChatErrorType type;

  @override
  String toString() => 'EduChatException(type: $type, message: $message)';
}
