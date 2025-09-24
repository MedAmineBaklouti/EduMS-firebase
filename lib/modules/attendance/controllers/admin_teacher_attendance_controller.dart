import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/services/database_service.dart';
import '../../../core/services/pdf_downloader/pdf_downloader.dart';
import '../../../data/models/attendance_record_model.dart';
import '../../../data/models/teacher_model.dart';

class AdminTeacherAttendanceController extends GetxController {
  final DatabaseService _db = Get.find();

  StreamSubscription? _teachersSubscription;
  StreamSubscription? _attendanceSubscription;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isExporting = false.obs;

  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxList<TeacherAttendanceRecord> _records = <TeacherAttendanceRecord>[].obs;
  final RxList<TeacherAttendanceRecord> currentEntries = <TeacherAttendanceRecord>[].obs;

  final Rx<DateTime> selectedDate = DateTime.now().obs;

  bool _teachersLoaded = false;
  bool _attendanceLoaded = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _teachersSubscription?.cancel();
    _attendanceSubscription?.cancel();
    super.onClose();
  }

  void setDate(DateTime date) {
    selectedDate.value = DateTime(date.year, date.month, date.day);
    _rebuildEntries();
  }

  void toggleStatus(String teacherId) {
    final index = currentEntries.indexWhere((entry) => entry.teacherId == teacherId);
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

  Future<void> saveAttendance() async {
    if (currentEntries.isEmpty) {
      Get.snackbar(
        'No teachers found',
        'There are no teachers to mark on this date.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isSaving.value = true;
    try {
      final batch = _db.firestore.batch();
      final day = selectedDate.value;
      for (final entry in currentEntries) {
        final normalized = entry.copyWith(date: day);
        final docRef =
            _db.firestore.collection('teacherAttendanceRecords').doc(normalized.id);
        batch.set(docRef, normalized.toMap());
      }
      await batch.commit();
      Get.snackbar(
        'Attendance saved',
        'Teacher attendance has been recorded.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Save failed',
        'Unable to store attendance: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> exportAttendanceAsPdf() async {
    final entries = currentEntries;
    if (entries.isEmpty) {
      Get.snackbar(
        'Nothing to export',
        'Add at least one teacher attendance record before exporting.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isExporting.value = true;
    try {
      final dateLabel = DateFormat.yMMMMd().format(selectedDate.value);
      final doc = pw.Document();
      final tableData = entries
          .map(
            (entry) => [
              entry.teacherName,
              entry.status.label,
              entry.note.isEmpty ? '-' : entry.note,
            ],
          )
          .toList();

      doc.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Teacher Attendance – $dateLabel',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: const ['Teacher', 'Status', 'Note'],
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
              },
            ),
          ],
        ),
      );

      final fileName =
          'teacher-attendance-${DateFormat('yyyyMMdd').format(selectedDate.value)}.pdf';
      final bytes = await doc.save();
      final savedPath = await savePdf(bytes, fileName);
      Get.closeCurrentSnackbar();
      Get.snackbar(
        'Download complete',
        savedPath != null
            ? 'Saved to $savedPath'
            : 'The PDF download has started.',
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

  void _initialize() {
    try {
      _teachersSubscription = _db.firestore
          .collection('teachers')
          .snapshots()
          .listen((snapshot) {
        final items = snapshot.docs.map(TeacherModel.fromDoc).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        teachers.assignAll(items);
        _teachersLoaded = true;
        _rebuildEntries();
        _maybeFinishLoading();
      });

      _attendanceSubscription = _db.firestore
          .collection('teacherAttendanceRecords')
          .snapshots()
          .listen((snapshot) {
        _records.assignAll(
          snapshot.docs.map(TeacherAttendanceRecord.fromDoc).toList(),
        );
        _attendanceLoaded = true;
        _rebuildEntries();
        _maybeFinishLoading();
      });
    } catch (error) {
      isLoading.value = false;
      Get.snackbar(
        'Load failed',
        'Unable to load teacher attendance data: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _rebuildEntries() {
    if (teachers.isEmpty) {
      currentEntries.clear();
      return;
    }
    final day = selectedDate.value;
    final dayRecords = _records
        .where((record) => _isSameDay(record.date, day))
        .toList();

    final entries = teachers.map((teacher) {
      final existing =
          dayRecords.firstWhereOrNull((record) => record.teacherId == teacher.id);
      if (existing != null) {
        return existing.copyWith(
          date: DateTime(day.year, day.month, day.day),
        );
      }
      return TeacherAttendanceRecord(
        id: _composeRecordId(teacher.id, day),
        teacherId: teacher.id,
        teacherName: teacher.name,
        date: DateTime(day.year, day.month, day.day),
        status: AttendanceStatus.absent,
        note: '',
      );
    }).toList();

    currentEntries.assignAll(entries);
  }

  void _maybeFinishLoading() {
    if (_teachersLoaded && _attendanceLoaded) {
      isLoading.value = false;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _composeRecordId(String teacherId, DateTime date) {
    final safeDate = DateFormat('yyyyMMdd').format(date);
    return '$teacherId-$safeDate';
  }
}
