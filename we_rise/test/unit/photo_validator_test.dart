import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/duplicate_detector.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/models.dart';
import 'package:we_rise/features/complaints/domain/photo_validator.dart';

void main() {
  final base = DateTime(2026, 11, 20, 12, 0);

  group('PhotoValidator', () {
    test('gallery photo with EXIF older than 24h is flagged', () {
      final result = PhotoValidator.validateReportPhoto(
        source: PhotoSource.gallery,
        reportTime: base,
        exifTimestamp: base.subtract(const Duration(hours: 25)),
      );
      expect(result.isValid, isTrue);
      expect(result.isGalleryFlagged, isTrue);
    });

    test('gallery photo within 24h is NOT flagged', () {
      final result = PhotoValidator.validateReportPhoto(
        source: PhotoSource.gallery,
        reportTime: base,
        exifTimestamp: base.subtract(const Duration(hours: 23)),
      );
      expect(result.isValid, isTrue);
      expect(result.isGalleryFlagged, isFalse);
    });

    test('camera photo is never flagged', () {
      final result = PhotoValidator.validateReportPhoto(
        source: PhotoSource.camera,
        reportTime: base,
        exifTimestamp: base.subtract(const Duration(days: 10)),
      );
      expect(result.isValid, isTrue);
      expect(result.isGalleryFlagged, isFalse);
    });

    test('after-photo fails if source is gallery', () {
      final result = PhotoValidator.validateAfterPhoto(
        source: PhotoSource.gallery,
      );
      expect(result.isValid, isFalse);
    });

    test('after-photo passes if camera source', () {
      final result = PhotoValidator.validateAfterPhoto(
        source: PhotoSource.camera,
      );
      expect(result.isValid, isTrue);
    });

    test('within 50m check passes for nearby location', () {
      const origin = LatLng(13.0000, 80.0000);
      const nearby = LatLng(13.0003, 80.0003); // ~47 m
      final dist = DuplicateDetector.haversineMetres(
        origin.latitude,
        origin.longitude,
        nearby.latitude,
        nearby.longitude,
      );
      expect(dist <= 50.0, isTrue);
    });

    test('within 50m check fails for faraway location', () {
      const origin = LatLng(13.0000, 80.0000);
      const farAway = LatLng(13.0010, 80.0010); // ~160 m
      final dist = DuplicateDetector.haversineMetres(
        origin.latitude,
        origin.longitude,
        farAway.latitude,
        farAway.longitude,
      );
      expect(dist <= 50.0, isFalse);
    });
  });
}
