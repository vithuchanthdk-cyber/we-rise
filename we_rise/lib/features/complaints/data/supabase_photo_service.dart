import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads compressed, EXIF-stripped photos to Supabase Storage
/// (`complaint-photos` bucket) with retry & progress callback.
class SupabasePhotoService {
  SupabasePhotoService(this._client);

  final SupabaseClient _client;
  static const String bucketName = 'complaint-photos';

  Future<String> uploadPhoto({
    required File file,
    required String complaintId,
    required String photoId,
    void Function(double progress)? onProgress,
    int maxRetries = 3,
  }) async {
    final storagePath = '$complaintId/$photoId.jpg';
    Object? lastError;

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        onProgress?.call(0.2 * attempt);
        await _client.storage.from(bucketName).upload(
              storagePath,
              file,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        onProgress?.call(1.0);
        return _client.storage.from(bucketName).getPublicUrl(storagePath);
      } catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
        }
      }
    }

    throw StateError('Photo upload failed after $maxRetries attempts: $lastError');
  }
}
