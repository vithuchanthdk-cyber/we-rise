import 'enums.dart';

class PhotoValidationResult {
  const PhotoValidationResult({
    required this.isValid,
    required this.isGalleryFlagged,
    this.warningMessage,
  });

  final bool isValid;
  final bool isGalleryFlagged;
  final String? warningMessage;
}

/// Validates photos attached to complaints.
abstract class PhotoValidator {
  /// Validate a photo for a new report.
  /// [exifTimestamp]: extracted EXIF timestamp (null for camera photos)
  /// [source]: camera or gallery
  /// [reportTime]: time of report submission
  static PhotoValidationResult validateReportPhoto({
    required PhotoSource source,
    required DateTime reportTime,
    DateTime? exifTimestamp,
  }) {
    if (source == PhotoSource.camera) {
      // Camera photos are always trusted
      return const PhotoValidationResult(
        isValid: true,
        isGalleryFlagged: false,
      );
    }

    // Gallery photo: check EXIF age
    if (exifTimestamp != null) {
      final age = reportTime.difference(exifTimestamp);
      if (age.inHours > 24) {
        return PhotoValidationResult(
          isValid: true, // still accepted, but flagged
          isGalleryFlagged: true,
          warningMessage:
              'This photo appears to be ${age.inHours} hours old. '
              'It will be flagged for moderator review.',
        );
      }
    }

    return const PhotoValidationResult(
      isValid: true,
      isGalleryFlagged: false,
    );
  }

  /// After-photos must be from live camera only.
  static PhotoValidationResult validateAfterPhoto({
    required PhotoSource source,
  }) {
    if (source == PhotoSource.gallery) {
      return const PhotoValidationResult(
        isValid: false,
        isGalleryFlagged: false,
        warningMessage:
            'After-photos must be taken with the live camera at the location.',
      );
    }
    return const PhotoValidationResult(
      isValid: true,
      isGalleryFlagged: false,
    );
  }
}
