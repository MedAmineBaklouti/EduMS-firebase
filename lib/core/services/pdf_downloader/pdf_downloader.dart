import 'dart:typed_data';

import 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart'
    if (dart.library.io) 'pdf_downloader_io.dart' as downloader;

/// Saves a PDF to an appropriate download location for the current platform.
///
/// Returns the path of the saved file when it can be determined (mainly on
/// IO-based platforms). Web platforms trigger a browser download and return
/// `null` because no local file path is available.
Future<String?> savePdf(Uint8List bytes, String fileName) {
  return downloader.savePdf(bytes, fileName);
}
