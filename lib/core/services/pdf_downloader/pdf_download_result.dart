class PdfDownloadResult {
  const PdfDownloadResult._({
    required this.wasSuccessful,
    this.path,
    this.wasCancelled = false,
  });

  final bool wasSuccessful;
  final String? path;
  final bool wasCancelled;

  static PdfDownloadResult saved(String path) =>
      PdfDownloadResult._(wasSuccessful: true, path: path);

  static const PdfDownloadResult triggeredDownload =
      PdfDownloadResult._(wasSuccessful: true);

  static const PdfDownloadResult cancelled =
      PdfDownloadResult._(wasSuccessful: false, wasCancelled: true);

  static const PdfDownloadResult failed =
      PdfDownloadResult._(wasSuccessful: false);
}
