import 'dart:typed_data';

import 'pdf_download_result.dart';

Future<PdfDownloadResult> savePdf(Uint8List bytes, String fileName) async {
  throw UnsupportedError('PDF downloading is not supported on this platform');
}
