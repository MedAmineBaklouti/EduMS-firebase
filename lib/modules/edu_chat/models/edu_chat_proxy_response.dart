class EduChatProxyResponse {
  const EduChatProxyResponse({
    required this.text,
    this.model,
    this.tokens,
    this.refused,
  });

  final String text;
  final String? model;
  final int? tokens;
  final bool? refused;

  factory EduChatProxyResponse.fromJson(Map<String, dynamic> json) {
    final tokensValue = json['tokens'];
    int? tokens;
    if (tokensValue is int) {
      tokens = tokensValue;
    } else if (tokensValue is double) {
      tokens = tokensValue.round();
    } else if (tokensValue is Map<String, dynamic>) {
      tokens = int.tryParse(tokensValue['totalTokens']?.toString() ?? '');
    }

    return EduChatProxyResponse(
      text: (json['text'] as String?)?.trim() ?? '',
      model: json['model'] as String?,
      tokens: tokens,
      refused: json['refused'] as bool?,
    );
  }

  bool get isEmpty => text.isEmpty;
}
