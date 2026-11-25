import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/enums.dart';
import '../domain/photo_validator.dart';

class PickedPhotoResult {
  const PickedPhotoResult({
    required this.path,
    required this.source,
    required this.capturedAt,
    required this.sizeBytes,
    required this.isGalleryFlagged,
    this.warningMessage,
  });

  final String path;
  final PhotoSource source;
  final DateTime capturedAt;
  final int sizeBytes;
  final bool isGalleryFlagged;
  final String? warningMessage;
}

abstract interface class PhotoService {
  Future<PickedPhotoResult?> pickFromCamera();
  Future<PickedPhotoResult?> pickFromGallery();
}

/// Uses [ImagePicker] (Android system Photo Picker for gallery, no
/// READ_MEDIA_IMAGES permission needed) and [FlutterImageCompress] to
/// strip EXIF metadata (`keepExif: false`), resize to max 1600 px, and
/// compress under 400 KB.
class DevicePhotoService implements PhotoService {
  DevicePhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int kMaxBytes = 400 * 1024;
  static const int kMaxDimension = 1600;

  @override
  Future<PickedPhotoResult?> pickFromCamera() => _pick(PhotoSource.camera);

  @override
  Future<PickedPhotoResult?> pickFromGallery() => _pick(PhotoSource.gallery);

  Future<PickedPhotoResult?> _pick(PhotoSource source) async {
    final xFile = await _picker.pickImage(
      source:
          source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (xFile == null) return null;

    final now = DateTime.now();
    DateTime capturedAt = now;
    if (source == PhotoSource.gallery) {
      try {
        capturedAt = File(xFile.path).lastModifiedSync();
      } catch (_) {
        capturedAt = now;
      }
    }

    final validation = PhotoValidator.validateReportPhoto(
      source: source,
      reportTime: now,
      exifTimestamp: source == PhotoSource.gallery ? capturedAt : null,
    );

    final compressed = await _compressAndStripExif(xFile.path);
    final sizeBytes = await compressed.length();

    return PickedPhotoResult(
      path: compressed.path,
      source: source,
      capturedAt: capturedAt,
      sizeBytes: sizeBytes,
      isGalleryFlagged: validation.isGalleryFlagged,
      warningMessage: validation.warningMessage,
    );
  }

  Future<File> _compressAndStripExif(String inputPath) async {
    final tempDir = await getTemporaryDirectory();
    final baseName = 'wr_${DateTime.now().millisecondsSinceEpoch}';
    final outPath = '${tempDir.path}${Platform.pathSeparator}$baseName.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outPath,
      minWidth: kMaxDimension,
      minHeight: kMaxDimension,
      quality: 80,
      keepExif: false, // Strips personal EXIF metadata
    );

    if (result == null) {
      return File(inputPath);
    }

    var file = File(result.path);
    if (await file.length() > kMaxBytes) {
      final outPath2 =
          '${tempDir.path}${Platform.pathSeparator}${baseName}_q60.jpg';
      final result2 = await FlutterImageCompress.compressAndGetFile(
        result.path,
        outPath2,
        minWidth: 1280,
        minHeight: 1280,
        quality: 60,
        keepExif: false,
      );
      if (result2 != null) {
        file = File(result2.path);
      }
    }
    return file;
  }
}
