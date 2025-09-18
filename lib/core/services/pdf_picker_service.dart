import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PdfPickerException implements Exception {
  const PdfPickerException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PdfPickerException($code, $message)';
}

class PickedPdfFile {
  const PickedPdfFile({required this.path, required this.name});

  final String path;
  final String name;
}

class PdfPickerService {
  static const MethodChannel _channel = MethodChannel('edu_ms/pdf_picker');

  Future<PickedPdfFile?> pickPdf() async {
    if (kIsWeb) {
      throw const PdfPickerException(
        'unsupported_platform',
        'Picking PDF files is not supported on the web.',
      );
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const PdfPickerException(
        'unsupported_platform',
        'PDF picking is only implemented on Android in this build.',
      );
    }

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('pickPdf');
      if (result == null) {
        return null;
      }
      final path = (result['path'] as String?) ?? '';
      final name = (result['name'] as String?) ?? 'selected.pdf';
      if (path.isEmpty) {
        throw const PdfPickerException(
          'invalid_result',
          'The file picker did not return a valid file path.',
        );
      }
      return PickedPdfFile(path: path, name: name);
    } on MissingPluginException {
      throw const PdfPickerException(
        'not_available',
        'The native PDF picker is not available.',
      );
    } on PlatformException catch (error) {
      throw PdfPickerException(error.code, error.message ?? 'Unknown error');
    }
  }
}
