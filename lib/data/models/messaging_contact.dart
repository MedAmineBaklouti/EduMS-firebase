class MessagingContact {
  MessagingContact({
    required this.id,
    required this.name,
    required this.role,
    this.classIds = const <String>[],
    this.relationship,
  });

  final String id;
  final String name;
  final String role;
  final List<String> classIds;
  final String? relationship;

  factory MessagingContact.fromJson(Map<String, dynamic> json) {
    final classes = json['classIds'] ?? json['class_ids'];
    return MessagingContact(
      id: (json['id'] ?? json['userId'] ?? '') as String,
      name: (json['name'] ?? json['displayName'] ?? json['email'] ?? 'User')
          as String,
      role: (json['role'] ?? 'user') as String,
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
    List<String>? classIds,
    String? relationship,
  }) {
    return MessagingContact(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      classIds: classIds ?? this.classIds,
      relationship: relationship ?? this.relationship,
    );
  }
}
