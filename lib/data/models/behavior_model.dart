import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

enum BehaviorType { positive, negative }

extension BehaviorTypeParser on BehaviorType {
  static BehaviorType fromString(String? value) {
    return BehaviorType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => BehaviorType.positive,
    );
  }

  String get label {
    switch (this) {
      case BehaviorType.positive:
        return 'behavior_type_positive'.tr;
      case BehaviorType.negative:
        return 'behavior_type_negative'.tr;
    }
  }
}

class BehaviorModel {
  final String id;
  final String childId;
  final String childName;
  final String classId;
  final String className;
  final String teacherId;
  final String teacherName;
  final BehaviorType type;
  final String description;
  final DateTime createdAt;

  const BehaviorModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory BehaviorModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return BehaviorModel(
      id: doc.id,
      childId: data['childId'] as String? ?? '',
      childName: data['childName'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      type: BehaviorTypeParser.fromString(data['type'] as String?),
      description: data['description'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'childId': childId,
      'childName': childName,
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'type': type.name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BehaviorModel copyWith({
    String? id,
    String? childId,
    String? childName,
    String? classId,
    String? className,
    String? teacherId,
    String? teacherName,
    BehaviorType? type,
    String? description,
    DateTime? createdAt,
  }) {
    return BehaviorModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
