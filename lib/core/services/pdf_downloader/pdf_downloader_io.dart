import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'pdf_download_result.dart';

int? _cachedAndroidSdkInt;

Future<int?> _androidSdkInt() async {
  if (!Platform.isAndroid) {
    return null;
  }

  if (_cachedAndroidSdkInt != null) {
    return _cachedAndroidSdkInt;
  }

  final match = RegExp(r'SDK (\d+)').firstMatch(Platform.version);
  if (match != null) {
    _cachedAndroidSdkInt = int.tryParse(match.group(1)!);
  }

  return _cachedAndroidSdkInt;
}

class _SavePathResult {
  const _SavePathResult(
    this.path, {
    this.requiresStoragePermission = false,
    this.wasCancelled = false,
  });

  const _SavePathResult.cancelled()
      : path = null,
        requiresStoragePermission = false,
        wasCancelled = true;

  final String? path;
  final bool requiresStoragePermission;
  final bool wasCancelled;
}

Future<PdfDownloadResult> savePdf(Uint8List bytes, String fileName) async {
  final sanitizedName = fileName.trim().isEmpty ? 'document.pdf' : fileName;

  final target = await _resolveSavePath(sanitizedName);
  if (target.wasCancelled) {
    return PdfDownloadResult.cancelled;
  }

  final path = target.path;
  if (path == null) {
    return PdfDownloadResult.failed;
  }

  if (target.requiresStoragePermission &&
      Platform.isAndroid &&
      !await _ensureStoragePermission()) {
    return PdfDownloadResult.failed;
  }

  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return PdfDownloadResult.saved(file.path);
}

Future<_SavePathResult> _resolveSavePath(String sanitizedName) async {
  final resolvedName = sanitizedName.toLowerCase().endsWith('.pdf')
      ? sanitizedName
      : '$sanitizedName.pdf';

  final promptResult = await _promptSavePath(resolvedName);
  if (promptResult.path != null) {
    return _SavePathResult(promptResult.path!);
  }

  if (promptResult.result == _PromptSavePathResult.userCancelled) {
    return const _SavePathResult.cancelled();
  }

  final directory = await _resolveDownloadDirectory();
  final fallbackPath = p.join(directory.path, resolvedName);
  return _SavePathResult(
    fallbackPath,
    requiresStoragePermission: Platform.isAndroid,
  );
}

enum _PromptSavePathResult {
  userCancelled,
  pickerUnavailable,
  // When the picker succeeds this enum is not used – see the nullable `path`
  // field on `_PromptSavePathOutcome` below. This keeps the calling code easy
  // to reason about while still differentiating the error scenarios above.
}

class _PromptSavePathOutcome {
  const _PromptSavePathOutcome({this.path, this.result});

  final String? path;
  final _PromptSavePathResult? result;
}

Future<_PromptSavePathOutcome> _promptSavePath(String resolvedName) async {
  try {
    final directoryPath = await getDirectoryPath();

    if (directoryPath == null || directoryPath.trim().isEmpty) {
      return const _PromptSavePathOutcome(
        result: _PromptSavePathResult.userCancelled,
      );
    }

    final normalizedDirectory = directoryPath.trim();
    return _PromptSavePathOutcome(path: p.join(normalizedDirectory, resolvedName));
  } on PlatformException {
    // Some platforms (notably older Android versions) may throw when the
    // platform picker is not available. In that case we fall back to the
    // default download directory resolution below.
    return const _PromptSavePathOutcome(
      result: _PromptSavePathResult.pickerUnavailable,
    );
  } on UnimplementedError {
    return const _PromptSavePathOutcome(
      result: _PromptSavePathResult.pickerUnavailable,
    );
  }
}

Future<bool> _ensureStoragePermission() async {
  Future<bool> _requestPermission(Permission permission) async {
    bool _isGranted(PermissionStatus status) {
      return status.isGranted || status.isLimited;
    }

    Future<bool> _openSettingsAndCheck() async {
      final opened = await openAppSettings();
      if (!opened) {
        return false;
      }

      final updatedStatus = await permission.status;
      return _isGranted(updatedStatus);
    }

    var status = await permission.status;

    if (_isGranted(status)) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      return _openSettingsAndCheck();
    }

    status = await permission.request();

    if (_isGranted(status)) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      return _openSettingsAndCheck();
    }

    return false;
  }

  try {
    final sdkInt = await _androidSdkInt();
    final needsManageExternalStorage = sdkInt != null && sdkInt >= 30;

    if (needsManageExternalStorage) {
      // Android 11+ requires the "manage external storage" permission to write
      // to user selected locations. Fall back to the legacy storage permission
      // on older versions or when the elevated permission is not granted.
      if (await _requestPermission(Permission.manageExternalStorage)) {
        return true;
      }
    }

    return await _requestPermission(Permission.storage);
  } on PlatformException {
    // Some devices are unable to report the permission state. In that case we
    // optimistically continue with the download and rely on the filesystem
    // write to surface any issues.
    return true;
  }
}

Future<Directory> _resolveDownloadDirectory() async {
  if (Platform.isAndroid) {
    const potentialPaths = [
      '/storage/emulated/0/Download',
      '/sdcard/Download',
    ];

    for (final path in potentialPaths) {
      final directory = Directory(path);
      if (await directory.exists()) {
        return directory;
      }
    }
  } else if (Platform.isMacOS || Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final downloads = Directory('$home/Downloads');
      if (await downloads.exists()) {
        return downloads;
      }
    }
  } else if (Platform.isWindows) {
    final profile = Platform.environment['USERPROFILE'];
    if (profile != null) {
      final downloads = Directory('$profile/Downloads');
      if (await downloads.exists()) {
        return downloads;
      }
    }
  }

  final fallback = Directory('${Directory.systemTemp.path}/edums-downloads');
  if (!await fallback.exists()) {
    await fallback.create(recursive: true);
  }
  return fallback;
}
