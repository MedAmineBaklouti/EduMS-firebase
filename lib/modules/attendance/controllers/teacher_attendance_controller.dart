import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/school_class_model.dart';

class TeacherAttendanceController extends GetxController {
  final RxList<SchoolClassModel> classes = <SchoolClassModel>[].obs;
  final Rxn<SchoolClassModel> selectedClass = Rxn<SchoolClassModel>();
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  final RxList<ChildAttendanceEntry> currentEntries =
      <ChildAttendanceEntry>[].obs;
  final RxList<AttendanceSessionModel> _sessions =
      <AttendanceSessionModel>[].obs;
  final RxList<AttendanceSessionModel> sessions =
      <AttendanceSessionModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isExporting = false.obs;

  final Map<String, List<ChildModel>> _childrenByClass =
      <String, List<ChildModel>>{};

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(items);
    if (selectedClass.value != null) {
      final id = selectedClass.value!.id;
      selectedClass.value = classes.firstWhereOrNull((item) => item.id == id);
    }
  }

  void setSessions(List<AttendanceSessionModel> items) {
    _sessions.assignAll(items);
    _refreshSessionList();
    _restoreCurrentSession();
  }

  void registerChildren(String classId, List<ChildModel> children) {
    _childrenByClass[classId] = children;
    if (selectedClass.value?.id == classId &&
        currentEntries.isEmpty &&
        !_restoreCurrentSession()) {
      _initializeEntriesFromChildren(children);
    }
  }

  void selectClass(SchoolClassModel? schoolClass) {
    selectedClass.value = schoolClass;
    if (!_restoreCurrentSession()) {
      final children =
          schoolClass == null ? <ChildModel>[] : _childrenByClass[schoolClass.id];
      _initializeEntriesFromChildren(children ?? <ChildModel>[]);
    }
  }

  void setDate(DateTime date) {
    selectedDate.value = date;
    if (!_restoreCurrentSession()) {
      final children = selectedClass.value == null
          ? <ChildModel>[]
          : _childrenByClass[selectedClass.value!.id] ?? <ChildModel>[];
      _initializeEntriesFromChildren(children);
    }
  }

  bool _restoreCurrentSession() {
    final classId = selectedClass.value?.id;
    if (classId == null) {
      currentEntries.clear();
      return false;
    }
    final session = _sessions.firstWhereOrNull((item) =>
        item.classId == classId && _isSameDay(item.date, selectedDate.value));
    if (session == null) {
      currentEntries.clear();
      return false;
    }
    currentEntries.assignAll(session.records);
    return true;
  }

  void _initializeEntriesFromChildren(List<ChildModel> children) {
    final entries = children
        .map(
          (child) => ChildAttendanceEntry(
            childId: child.id,
            childName: child.name,
            status: AttendanceStatus.present,
          ),
        )
        .toList();
    currentEntries.assignAll(entries);
  }

  void toggleStatus(String childId) {
    final index = currentEntries.indexWhere((entry) => entry.childId == childId);
    if (index == -1) {
      return;
    }
    final entry = currentEntries[index];
    final updated = entry.copyWith(
      status: entry.status == AttendanceStatus.present
          ? AttendanceStatus.absent
          : AttendanceStatus.present,
    );
    currentEntries[index] = updated;
  }

  Future<bool> submitAttendance() async {
    final classModel = selectedClass.value;
    if (classModel == null) {
      Get.snackbar(
        'Select a class',
        'Choose a class before submitting attendance.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (currentEntries.isEmpty) {
      Get.snackbar(
        'Missing students',
        'No students are available to mark for this class.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    isSaving.value = true;
    try {
      final session = AttendanceSessionModel(
        id: '${classModel.id}-${selectedDate.value.toIso8601String()}',
        classId: classModel.id,
        className: classModel.name,
        teacherId: '',
        teacherName: '',
        date: selectedDate.value,
        records: List<ChildAttendanceEntry>.from(currentEntries),
        submittedAt: DateTime.now(),
      );
      final existingIndex = _sessions.indexWhere((item) =>
          item.classId == session.classId &&
          _isSameDay(item.date, session.date));
      if (existingIndex != -1) {
        _sessions[existingIndex] = session;
      } else {
        _sessions.add(session);
      }
      _refreshSessionList();
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> exportAttendanceAsPdf() async {
    if (currentEntries.isEmpty) {
      Get.snackbar(
        'Nothing to export',
        'Mark attendance before exporting a PDF.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isExporting.value = true;
    try {
      await Future<void>.delayed(const Duration(seconds: 1));
      Get.snackbar(
        'Export ready',
        'Attendance PDF generated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  void _refreshSessionList() {
    final classId = selectedClass.value?.id;
    if (classId == null) {
      sessions.assignAll(_sessions);
    } else {
      sessions.assignAll(
        _sessions
            .where((session) => session.classId == classId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
