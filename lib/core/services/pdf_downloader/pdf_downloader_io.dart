import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> savePdf(Uint8List bytes, String fileName) async {
  final sanitizedName = fileName.trim().isEmpty ? 'document.pdf' : fileName;

  if (Platform.isAndroid && !await _ensureStoragePermission()) {
    return null;
  }

  final targetPath = await _resolveSavePath(sanitizedName);
  if (targetPath == null) {
    return null;
  }

  final file = File(targetPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String?> _resolveSavePath(String sanitizedName) async {
  final resolvedName = sanitizedName.toLowerCase().endsWith('.pdf')
      ? sanitizedName
      : '$sanitizedName.pdf';

  try {
    final directoryPath = await getDirectoryPath();

    if (directoryPath != null && directoryPath.trim().isNotEmpty) {
      return p.join(directoryPath, resolvedName);
    }
  } on PlatformException {
    // Fall through to the manual resolution logic when the platform channel
    // fails to provide a directory picker (common on some Android devices).
  } on UnimplementedError {
    final directory = await _resolveDownloadDirectory();
    return p.join(directory.path, resolvedName);
  } catch (_) {
    final directory = await _resolveDownloadDirectory();
    return p.join(directory.path, resolvedName);
  }

  final directory = await _resolveDownloadDirectory();
  return p.join(directory.path, resolvedName);
}

Future<bool> _ensureStoragePermission() async {
  Future<bool> _handlePermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      final requested = await permission.request();
      return requested.isGranted || requested.isLimited;
    }

    return false;
  }

  try {
    // Android 11+ requires the "manage external storage" permission to write
    // to user selected locations. Fall back to the legacy storage permission on
    // older versions.
    if (await _handlePermission(Permission.manageExternalStorage)) {
      return true;
    }

    return await _handlePermission(Permission.storage);
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
