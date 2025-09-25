import 'package:cloud_firestore/cloud_firestore.dart';

enum PickupStage {
  awaitingParent,
  awaitingTeacher,
  awaitingAdmin,
  completed,
}

class PickupTicketModel {
  final String id;
  final String childId;
  final String childName;
  final String parentId;
  final String parentName;
  final String classId;
  final String className;
  final DateTime createdAt;
  final DateTime? parentConfirmedAt;
  final String teacherValidatorId;
  final String teacherValidatorName;
  final DateTime? teacherValidatedAt;
  final String adminValidatorId;
  final String adminValidatorName;
  final DateTime? adminValidatedAt;
  final DateTime? archivedAt;

  const PickupTicketModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.parentId,
    required this.parentName,
    required this.classId,
    required this.className,
    required this.createdAt,
    required this.parentConfirmedAt,
    required this.teacherValidatorId,
    required this.teacherValidatorName,
    required this.teacherValidatedAt,
    required this.adminValidatorId,
    required this.adminValidatorName,
    required this.adminValidatedAt,
    required this.archivedAt,
  });

  factory PickupTicketModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return PickupTicketModel(
      id: doc.id,
      childId: data['childId'] as String? ?? '',
      childName: data['childName'] as String? ?? '',
      parentId: data['parentId'] as String? ?? '',
      parentName: data['parentName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentConfirmedAt:
          (data['parentConfirmedAt'] as Timestamp?)?.toDate(),
      teacherValidatorId: data['teacherValidatorId'] as String? ?? '',
      teacherValidatorName: data['teacherValidatorName'] as String? ?? '',
      teacherValidatedAt:
          (data['teacherValidatedAt'] as Timestamp?)?.toDate(),
      adminValidatorId: data['adminValidatorId'] as String? ?? '',
      adminValidatorName: data['adminValidatorName'] as String? ?? '',
      adminValidatedAt: (data['adminValidatedAt'] as Timestamp?)?.toDate(),
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'childId': childId,
      'childName': childName,
      'parentId': parentId,
      'parentName': parentName,
      'classId': classId,
      'className': className,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentConfirmedAt':
          parentConfirmedAt == null ? null : Timestamp.fromDate(parentConfirmedAt!),
      'teacherValidatorId': teacherValidatorId,
      'teacherValidatorName': teacherValidatorName,
      'teacherValidatedAt': teacherValidatedAt == null
          ? null
          : Timestamp.fromDate(teacherValidatedAt!),
      'adminValidatorId': adminValidatorId,
      'adminValidatorName': adminValidatorName,
      'adminValidatedAt': adminValidatedAt == null
          ? null
          : Timestamp.fromDate(adminValidatedAt!),
      'archivedAt': archivedAt == null
          ? null
          : Timestamp.fromDate(archivedAt!),
    };
  }

  bool get isAwaitingParent => parentConfirmedAt == null;

  bool get isAwaitingTeacher =>
      parentConfirmedAt != null && teacherValidatedAt == null;

  bool get isAwaitingAdmin =>
      teacherValidatedAt != null && adminValidatedAt == null;

  bool get isCompleted => adminValidatedAt != null;

  bool get isArchived => archivedAt != null;

  PickupStage get stage {
    if (isCompleted) {
      return PickupStage.completed;
    }
    if (isAwaitingAdmin) {
      return PickupStage.awaitingAdmin;
    }
    if (isAwaitingTeacher) {
      return PickupStage.awaitingTeacher;
    }
    return PickupStage.awaitingParent;
  }

  PickupTicketModel copyWith({
    String? id,
    String? childId,
    String? childName,
    String? parentId,
    String? parentName,
    String? classId,
    String? className,
    DateTime? createdAt,
    DateTime? parentConfirmedAt,
    String? teacherValidatorId,
    String? teacherValidatorName,
    DateTime? teacherValidatedAt,
    String? adminValidatorId,
    String? adminValidatorName,
    DateTime? adminValidatedAt,
    DateTime? archivedAt,
  }) {
    return PickupTicketModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      createdAt: createdAt ?? this.createdAt,
      parentConfirmedAt: parentConfirmedAt ?? this.parentConfirmedAt,
      teacherValidatorId: teacherValidatorId ?? this.teacherValidatorId,
      teacherValidatorName:
          teacherValidatorName ?? this.teacherValidatorName,
      teacherValidatedAt: teacherValidatedAt ?? this.teacherValidatedAt,
      adminValidatorId: adminValidatorId ?? this.adminValidatorId,
      adminValidatorName: adminValidatorName ?? this.adminValidatorName,
      adminValidatedAt: adminValidatedAt ?? this.adminValidatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
