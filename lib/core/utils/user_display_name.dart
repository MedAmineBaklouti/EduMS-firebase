String formatUserDisplayName({
  String? explicitName,
  String? displayName,
  String? email,
  required String fallback,
}) {
  final cleanedExplicit = _cleanName(explicitName);
  if (cleanedExplicit != null) {
    return cleanedExplicit;
  }

  final cleanedDisplay = _cleanName(displayName);
  if (cleanedDisplay != null) {
    return cleanedDisplay;
  }

  final fromEmail = _nameFromEmail(email);
  if (fromEmail != null && fromEmail.isNotEmpty) {
    return fromEmail;
  }

  return fallback;
}

String? _cleanName(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  if (_looksLikeEmail(trimmed)) {
    return null;
  }

  return trimmed;
}

String? _nameFromEmail(String? email) {
  final trimmed = email?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  if (!_looksLikeEmail(trimmed)) {
    return null;
  }

  final localPart = trimmed.split('@').first.trim();
  if (localPart.isEmpty) {
    return null;
  }

  final sanitized = localPart.replaceAll(RegExp(r'[._-]+'), ' ');
  final segments = sanitized
      .split(RegExp(r'\s+'))
      .where((segment) => segment.isNotEmpty)
      .map((segment) => segment.length == 1
          ? segment.toUpperCase()
          : segment[0].toUpperCase() + segment.substring(1))
      .toList();

  return segments.isEmpty ? null : segments.join(' ');
}

bool _looksLikeEmail(String value) {
  return value.contains('@');
}
