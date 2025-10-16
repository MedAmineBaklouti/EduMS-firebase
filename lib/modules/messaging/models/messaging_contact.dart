class MessagingContact {
  MessagingContact({
    required this.id,
    required this.name,
    required this.role,
    String? userId,
    this.classIds = const <String>[],
    this.relationship,
  }) : userId = userId ?? id;

  final String id;
  final String name;
  final String role;
  final String userId;
  final List<String> classIds;
  final String? relationship;

  factory MessagingContact.fromJson(Map<String, dynamic> json) {
    final classes = json['classIds'] ?? json['class_ids'];
    final rawId = (json['id'] ?? json['userId'] ?? '').toString();
    final resolvedUserId =
        (json['userId'] ?? json['uid'] ?? rawId).toString();
    return MessagingContact(
      id: rawId,
      name: (json['name'] ?? json['displayName'] ?? json['email'] ?? 'User')
          as String,
      role: (json['role'] ?? 'user') as String,
      userId: resolvedUserId,
      classIds: classes is List
          ? classes.whereType<String>().toList()
          : const <String>[],
      relationship: json['relationship'] as String?,
    );
  }

  MessagingContact copyWith({
    String? id,
    String? name,
    String? role,
    String? userId,
    List<String>? classIds,
    String? relationship,
  }) {
    return MessagingContact(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      classIds: classIds ?? this.classIds,
      relationship: relationship ?? this.relationship,
    );
  }
}
