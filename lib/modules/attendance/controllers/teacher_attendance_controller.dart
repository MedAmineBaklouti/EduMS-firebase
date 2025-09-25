import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/pdf_downloader/pdf_downloader.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/parent_model.dart';
import '../../../data/models/school_class_model.dart';
import '../../../data/models/teacher_model.dart';

class TeacherAttendanceController extends GetxController {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  StreamSubscription? _teacherSubscription;
  StreamSubscription? _classesSubscription;
  StreamSubscription? _sessionsSubscription;
  final Map<String, StreamSubscription> _childrenSubscriptions =
      <String, StreamSubscription>{};

  bool _teacherLoaded = false;
  bool _classesLoaded = false;
  bool _sessionsLoaded = false;

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
  final Map<String, ParentModel?> _parentCache = <String, ParentModel?>{};

  final Rxn<TeacherModel> teacher = Rxn<TeacherModel>();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    for (final subscription in _childrenSubscriptions.values) {
      subscription.cancel();
    }
    _childrenSubscriptions.clear();
    _teacherSubscription?.cancel();
    _classesSubscription?.cancel();
    _sessionsSubscription?.cancel();
    _parentCache.clear();
    super.onClose();
  }

  void setClasses(List<SchoolClassModel> items) {
    classes.assignAll(
      List<SchoolClassModel>.from(items)
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
    if (selectedClass.value != null) {
      final id = selectedClass.value!.id;
      final match = classes.firstWhereOrNull((item) => item.id == id);
      if (match != null) {
        selectedClass.value = match;
      } else {
        returnToClassList();
      }
    } else {
      _refreshSessionList();
      currentEntries.clear();
    }
  }

  void setSessions(List<AttendanceSessionModel> items) {
    final normalized = items
        .map((session) => session.copyWith(date: _normalizeDate(session.date)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _sessions.assignAll(normalized);
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
    _refreshSessionList();
    if (!_restoreCurrentSession()) {
      final children =
          schoolClass == null ? <ChildModel>[] : _childrenByClass[schoolClass.id];
      _initializeEntriesFromChildren(children ?? <ChildModel>[]);
    }
  }

  void setDate(DateTime date) {
    final normalized = _normalizeDate(date);
    selectedDate.value = normalized;
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
    final normalizedDate = _normalizeDate(selectedDate.value);
    final session = _sessions.firstWhereOrNull((item) =>
        item.classId == classId && _isSameDay(item.date, normalizedDate));
    if (session == null) {
      currentEntries.clear();
      return false;
    }
    currentEntries.assignAll(session.records);
    if (!_isSameDay(selectedDate.value, session.date)) {
      selectedDate.value = _normalizeDate(session.date);
    }
    return true;
  }

  void _initializeEntriesFromChildren(List<ChildModel> children) {
    final sortedChildren = List<ChildModel>.from(children)
      ..sort((a, b) => a.name.compareTo(b.name));
    final entries = sortedChildren
        .map(
          (child) => ChildAttendanceEntry(
            childId: child.id,
            childName: child.name,
            status: AttendanceStatus.absent,
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
    final teacherModel = teacher.value;
    if (classModel == null) {
      Get.snackbar(
        'Select a class',
        'Choose a class before submitting attendance.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (teacherModel == null) {
      Get.snackbar(
        'Profile incomplete',
        'Unable to determine the authenticated teacher.',
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
      final normalizedDate = _normalizeDate(selectedDate.value);
      final existingSession = _sessions.firstWhereOrNull((item) =>
          item.classId == classModel.id && _isSameDay(item.date, normalizedDate));
      final sessionId = existingSession?.id ??
          _buildSessionId(classModel.id, normalizedDate);
      final session = AttendanceSessionModel(
        id: sessionId,
        classId: classModel.id,
        className: classModel.name,
        teacherId: teacherModel.id,
        teacherName: teacherModel.name,
        date: normalizedDate,
        records: List<ChildAttendanceEntry>.from(currentEntries),
        submittedAt: DateTime.now(),
      );
      await _db.firestore
          .collection('attendanceSessions')
          .doc(session.id)
          .set(session.toMap());
      if (existingSession != null) {
        final existingIndex =
            _sessions.indexWhere((item) => item.id == existingSession.id);
        if (existingIndex != -1) {
          _sessions[existingIndex] = session;
        }
      } else {
        _sessions.add(session);
      }
      await _ensurePickupTicketsForPresentChildren(
        classModel: classModel,
        sessionDate: normalizedDate,
        entries: session.records,
      );
      _refreshSessionList();
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> exportAttendanceAsPdf({AttendanceSessionModel? session}) async {
    final records = session?.records ?? currentEntries;
    if (records.isEmpty) {
      Get.snackbar(
        'Nothing to export',
        'Mark attendance before exporting a PDF.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isExporting.value = true;
    try {
      final date = session?.date ?? selectedDate.value;
      final className = session?.className ?? selectedClass.value?.name ?? '';
      final teacherName =
          session?.teacherName ?? teacher.value?.name ?? 'Unknown teacher';
      final presentCount = records
          .where((record) => record.status == AttendanceStatus.present)
          .length;

      final doc = pw.Document();
      final dateLabel = DateFormat.yMMMMd().format(date);
      doc.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Attendance – $dateLabel',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              'Class: ${className.isNotEmpty ? className : 'Class not specified'}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Teacher: ${teacherName.isNotEmpty ? teacherName : 'Unknown teacher'}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              '$presentCount of ${records.length} students marked present.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: const ['Student', 'Status'],
              data: records
                  .map((entry) => [entry.childName, entry.status.label])
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1),
              },
            ),
          ],
        ),
      );

      final sanitizedClass =
          _sanitizeFileName(className.isEmpty ? 'class' : className);
      final fileName =
          'attendance-${sanitizedClass.isEmpty ? 'class' : sanitizedClass}-${DateFormat('yyyyMMdd').format(date)}.pdf';
      final bytes = await doc.save();
      final savedPath = await savePdf(bytes, fileName);
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'Download complete',
        savedPath != null
            ? 'Saved to $savedPath'
            : 'The PDF was not saved. Please check storage permissions or try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Export failed',
        'Unable to create the PDF: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  void _refreshSessionList() {
    final classId = selectedClass.value?.id;
    final sorted = List<AttendanceSessionModel>.from(_sessions)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (classId == null) {
      sessions.assignAll(sorted);
      return;
    }
    sessions.assignAll(sorted.where((session) => session.classId == classId));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int childCountForClass(String classId) {
    return _childrenByClass[classId]?.length ?? 0;
  }

  List<ChildModel> childrenForClass(String classId) {
    return _childrenByClass[classId] ?? <ChildModel>[];
  }

  AttendanceSessionModel? sessionForClassOnDate(
      String classId, DateTime date) {
    final normalized = _normalizeDate(date);
    return _sessions.firstWhereOrNull(
      (item) => item.classId == classId && _isSameDay(item.date, normalized),
    );
  }

  void returnToClassList() {
    selectClass(null);
  }

  Future<void> _initialize() async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) {
        Get.snackbar(
          'Authentication required',
          'Unable to determine the authenticated teacher.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      selectedDate.value = _normalizeDate(selectedDate.value);
      isLoading.value = true;

      _teacherSubscription = _db.firestore
          .collection('teachers')
          .doc(teacherId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          teacher.value = TeacherModel.fromDoc(snapshot);
        }
        _teacherLoaded = true;
        _maybeFinishLoading();
      });

      _classesSubscription = _db.firestore
          .collection('classes')
          .snapshots()
          .listen((snapshot) {
        final teacherClasses = snapshot.docs
            .map(SchoolClassModel.fromDoc)
            .where((item) => item.teacherSubjects.values.contains(teacherId))
            .toList();
        setClasses(teacherClasses);
        _syncChildrenListeners(teacherClasses);
        _classesLoaded = true;
        _maybeFinishLoading();
      });

      _sessionsSubscription = _db.firestore
          .collection('attendanceSessions')
          .where('teacherId', isEqualTo: teacherId)
          .snapshots()
          .listen((snapshot) {
        setSessions(snapshot.docs.map(AttendanceSessionModel.fromDoc).toList());
        _sessionsLoaded = true;
        _maybeFinishLoading();
      });
    } catch (error) {
      isLoading.value = false;
      Get.snackbar(
        'Load failed',
        'Unable to load attendance data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _syncChildrenListeners(List<SchoolClassModel> teacherClasses) {
    final classIds = teacherClasses.map((item) => item.id).toSet();
    final existing = _childrenSubscriptions.keys.toSet();

    for (final removedId in existing.difference(classIds)) {
      _childrenSubscriptions.remove(removedId)?.cancel();
      _childrenByClass.remove(removedId);
    }

    for (final schoolClass in teacherClasses) {
      if (_childrenSubscriptions.containsKey(schoolClass.id)) {
        continue;
      }
      final subscription = _db.firestore
          .collection('children')
          .where('classId', isEqualTo: schoolClass.id)
          .snapshots()
          .listen((snapshot) {
        registerChildren(
          schoolClass.id,
          snapshot.docs.map(ChildModel.fromDoc).toList(),
        );
      });
      _childrenSubscriptions[schoolClass.id] = subscription;
    }
  }

  void _maybeFinishLoading() {
    if (_teacherLoaded && _classesLoaded && _sessionsLoaded) {
      isLoading.value = false;
    }
  }

  Future<void> _ensurePickupTicketsForPresentChildren({
    required SchoolClassModel classModel,
    required DateTime sessionDate,
    required List<ChildAttendanceEntry> entries,
  }) async {
    final presentEntries = entries
        .where((entry) => entry.status == AttendanceStatus.present)
        .toList();
    if (presentEntries.isEmpty) {
      return;
    }
    final children = _childrenByClass[classModel.id] ?? <ChildModel>[];
    final childrenById = {for (final child in children) child.id: child};
    final dateCode = DateFormat('yyyyMMdd').format(sessionDate);

    for (final entry in presentEntries) {
      ChildModel? child = childrenById[entry.childId];
      if (child == null) {
        try {
          final childSnapshot = await _db.firestore
              .collection('children')
              .doc(entry.childId)
              .get();
          if (childSnapshot.exists) {
            child = ChildModel.fromDoc(childSnapshot);
            childrenById[child.id] = child;
          }
        } catch (error) {
          Get.log('Unable to load child ${entry.childId}: $error');
        }
      }
      if (child == null || child.parentId.isEmpty) {
        continue;
      }

      final parent = await _getParent(child.parentId);
      final parentName = parent?.name ?? 'Parent';
      final ticketId = '${child.id}_$dateCode';
      final ticketRef = _db.firestore.collection('pickupTickets').doc(ticketId);
      final existingTicket = await ticketRef.get();

      if (existingTicket.exists) {
        await ticketRef.set(
          <String, dynamic>{
            'childId': child.id,
            'childName': entry.childName,
            'parentId': child.parentId,
            'parentName': parentName,
            'classId': classModel.id,
            'className': classModel.name,
          },
          SetOptions(merge: true),
        );
        continue;
      }

      await ticketRef.set(<String, dynamic>{
        'childId': child.id,
        'childName': entry.childName,
        'parentId': child.parentId,
        'parentName': parentName,
        'classId': classModel.id,
        'className': classModel.name,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'parentConfirmedAt': null,
        'teacherValidatorId': '',
        'teacherValidatorName': '',
        'teacherValidatedAt': null,
        'adminValidatorId': '',
        'adminValidatorName': '',
        'adminValidatedAt': null,
      });
    }
  }

  Future<ParentModel?> _getParent(String parentId) async {
    if (_parentCache.containsKey(parentId)) {
      return _parentCache[parentId];
    }
    try {
      final snapshot =
          await _db.firestore.collection('parents').doc(parentId).get();
      if (!snapshot.exists) {
        _parentCache[parentId] = null;
        return null;
      }
      final parent = ParentModel.fromDoc(snapshot);
      _parentCache[parentId] = parent;
      return parent;
    } catch (error) {
      Get.log('Unable to load parent $parentId: $error');
      _parentCache[parentId] = null;
      return null;
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _buildSessionId(String classId, DateTime date) {
    final normalized = _normalizeDate(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$classId-$year$month$day';
  }

  String _sanitizeFileName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized;
  }
}
