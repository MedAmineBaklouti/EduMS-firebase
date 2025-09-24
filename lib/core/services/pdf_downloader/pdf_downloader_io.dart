import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
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

    if (directoryPath == null || directoryPath.trim().isEmpty) {
      return null;
    }

    return p.join(directoryPath, resolvedName);
  } on UnimplementedError {
    final directory = await _resolveDownloadDirectory();
    return p.join(directory.path, resolvedName);
  } catch (_) {
    final directory = await _resolveDownloadDirectory();
    return p.join(directory.path, resolvedName);
  }
}

Future<bool> _ensureStoragePermission() async {
  final storageStatus = await Permission.storage.status;
  if (storageStatus.isGranted) {
    return true;
  }

  if (storageStatus.isPermanentlyDenied) {
    return false;
  }

  final requested = await Permission.storage.request();
  if (requested.isGranted) {
    return true;
  }

  if (await Permission.manageExternalStorage.isGranted) {
    return true;
  }

  final manageStatus = await Permission.manageExternalStorage.request();
  return manageStatus.isGranted;
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
