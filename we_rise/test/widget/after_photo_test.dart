import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/core/l10n/app_localizations.dart';
import 'package:we_rise/features/complaints/data/in_memory_repositories.dart';
import 'package:we_rise/features/complaints/data/location_service.dart';
import 'package:we_rise/features/complaints/data/photo_service.dart';
import 'package:we_rise/features/complaints/data/providers.dart';
import 'package:we_rise/features/complaints/data/seed_data.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/models.dart';
import 'package:we_rise/features/volunteer/presentation/task_detail_screen.dart';

class _MockCameraOnlyPhotoService implements PhotoService {
  @override
  Future<PickedPhotoResult?> pickFromCamera() async => PickedPhotoResult(
        path: '/tmp/after_cam.jpg',
        source: PhotoSource.camera,
        capturedAt: DateTime(2026, 11, 25),
        sizeBytes: 150 * 1024,
        isGalleryFlagged: false,
      );

  @override
  Future<PickedPhotoResult?> pickFromGallery() async => throw StateError(
        'Gallery must never be called for after-photos',
      );
}

class _ConfigurableLocationService implements LocationService {
  _ConfigurableLocationService(this.coords);
  final LatLng coords;

  @override
  Future<LocationResult> getCurrentLocation() async => LocationResult(
        location: coords,
        ward: SeedData.wards.first,
        isLiveGps: true,
      );

  @override
  Ward resolveWard(LatLng location) => SeedData.wards.first;
}

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('TaskDetailScreen after-photo flow', () {
    testWidgets('rejects after-photo when over 50 m away and has no gallery',
        (tester) async {
      final compRepo = InMemoryComplaintRepository();
      final taskRepo = InMemoryTaskRepository(complaintRepo: compRepo);

      // t001 is for c006 at (12.9566, 80.2452); u-volunteer-1 is already joined
      // Set GPS > 50 m away: (12.9600, 80.2500) (~640 m away)
      await tester.pumpWidget(
        _wrap(
          const TaskDetailScreen(taskId: 't001'),
          overrides: [
            complaintRepositoryProvider.overrideWithValue(compRepo),
            taskRepositoryProvider.overrideWithValue(taskRepo),
            photoServiceProvider.overrideWithValue(_MockCameraOnlyPhotoService()),
            locationServiceProvider.overrideWithValue(
              _ConfigurableLocationService(const LatLng(12.9600, 80.2500)),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify no gallery button exists
      expect(find.text('Choose from gallery'), findsNothing);
      expect(find.byKey(const Key('after_photo_camera_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('after_photo_camera_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text('You must be within 50 m of the original complaint location'),
        findsOneWidget,
      );
      final comp = await compRepo.getById('c006');
      expect(comp?.status, isNot(ComplaintStatus.AWAITING_CONFIRMATION));
    });

    testWidgets('accepts camera after-photo within 50 m and moves to awaiting confirmation',
        (tester) async {
      final compRepo = InMemoryComplaintRepository();
      final taskRepo = InMemoryTaskRepository(complaintRepo: compRepo);

      // c006 is at (12.9566, 80.2452); set GPS ~15 m away
      await tester.pumpWidget(
        _wrap(
          const TaskDetailScreen(taskId: 't001'),
          overrides: [
            complaintRepositoryProvider.overrideWithValue(compRepo),
            taskRepositoryProvider.overrideWithValue(taskRepo),
            photoServiceProvider.overrideWithValue(_MockCameraOnlyPhotoService()),
            locationServiceProvider.overrideWithValue(
              _ConfigurableLocationService(const LatLng(12.9567, 80.2453)),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('after_photo_camera_btn')));
      await tester.pumpAndSettle();

      final comp = await compRepo.getById('c006');
      expect(comp?.status, equals(ComplaintStatus.AWAITING_CONFIRMATION));
      expect(comp?.afterPhotos.length, equals(1));
    });
  });
}
