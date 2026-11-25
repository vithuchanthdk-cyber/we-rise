import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/core/l10n/app_localizations.dart';
import 'package:we_rise/core/shared/widgets/offline_banner.dart';
import 'package:we_rise/features/complaints/data/in_memory_repositories.dart';
import 'package:we_rise/features/complaints/data/location_service.dart';
import 'package:we_rise/features/complaints/data/photo_service.dart';
import 'package:we_rise/features/complaints/data/providers.dart';
import 'package:we_rise/features/complaints/data/seed_data.dart';
import 'package:we_rise/features/complaints/data/voice_service.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/models.dart';
import 'package:we_rise/features/complaints/presentation/report_screen.dart';

class _MockPhotoService implements PhotoService {
  PickedPhotoResult? nextCameraResult;
  PickedPhotoResult? nextGalleryResult;

  @override
  Future<PickedPhotoResult?> pickFromCamera() async =>
      nextCameraResult ??
      PickedPhotoResult(
        path: '/tmp/cam_1.jpg',
        source: PhotoSource.camera,
        capturedAt: DateTime(2026, 11, 25),
        sizeBytes: 120 * 1024,
        isGalleryFlagged: false,
      );

  @override
  Future<PickedPhotoResult?> pickFromGallery() async =>
      nextGalleryResult ??
      PickedPhotoResult(
        path: '/tmp/gal_1.jpg',
        source: PhotoSource.gallery,
        capturedAt: DateTime(2026, 11, 20),
        sizeBytes: 180 * 1024,
        isGalleryFlagged: true,
        warningMessage: 'Older than 24h',
      );
}

class _MockLocationService implements LocationService {
  @override
  Future<LocationResult> getCurrentLocation() async => LocationResult(
        location: const LatLng(13.1234, 80.2988),
        ward: SeedData.wards.first,
        isLiveGps: true,
      );

  @override
  Ward resolveWard(LatLng location) => SeedData.wards.first;
}

class _MockVoiceService implements VoiceService {
  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required String localeId,
    required void Function(String recognizedWords) onResult,
  }) async {
    onResult('sewage overflow near gate');
  }

  @override
  Future<void> stopListening() async {}
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
  group('ReportScreen & Photo Picker', () {
    testWidgets('requires at least one photo before submitting', (tester) async {
      final mockPhoto = _MockPhotoService();
      await tester.pumpWidget(
        _wrap(
          const ReportScreen(),
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhoto),
            locationServiceProvider.overrideWithValue(_MockLocationService()),
            voiceServiceProvider.overrideWithValue(_MockVoiceService()),
            isOnlineProvider.overrideWithValue(true),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Submit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('At least one photo is required'), findsOneWidget);
    });

    testWidgets('supports camera and flagged gallery photo + max 3 limit',
        (tester) async {
      final mockPhoto = _MockPhotoService();
      await tester.pumpWidget(
        _wrap(
          const ReportScreen(),
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhoto),
            locationServiceProvider.overrideWithValue(_MockLocationService()),
            voiceServiceProvider.overrideWithValue(_MockVoiceService()),
            isOnlineProvider.overrideWithValue(true),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Pick 1 camera photo
      await tester.tap(find.byKey(const Key('take_photo_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Add photo (1/3)'), findsOneWidget);

      // Pick 1 gallery photo (flagged > 24h)
      await tester.tap(find.byKey(const Key('gallery_photo_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Add photo (2/3)'), findsOneWidget);
      expect(
        find.textContaining('more than 24 hours old'),
        findsOneWidget,
      );

      // Pick 3rd photo — reaches max 3/3
      await tester.tap(find.byKey(const Key('take_photo_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Add photo (3/3)'), findsOneWidget);

      // Buttons disabled at 3/3
      final takeBtn = tester.widget<OutlinedButton>(
        find.byKey(const Key('take_photo_btn')),
      );
      expect(takeBtn.onPressed, isNull);
    });

    testWidgets('AI suggests category from note and submits online',
        (tester) async {
      final mockPhoto = _MockPhotoService();
      final repo = InMemoryComplaintRepository();
      final initialCount = (await repo.getAll()).length;

      await tester.pumpWidget(
        _wrap(
          const ReportScreen(),
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhoto),
            locationServiceProvider.overrideWithValue(_MockLocationService()),
            voiceServiceProvider.overrideWithValue(_MockVoiceService()),
            complaintRepositoryProvider.overrideWithValue(repo),
            isOnlineProvider.overrideWithValue(true),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('take_photo_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Major sewage leak near street corner',
      );
      await tester.pumpAndSettle();

      expect(find.text('AI suggested: Sewage Leak'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Submit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Report submitted successfully'), findsOneWidget);
      final afterCount = (await repo.getAll()).length;
      expect(afterCount, equals(initialCount + 1));
    });

    testWidgets('queues report offline when disconnected', (tester) async {
      final mockPhoto = _MockPhotoService();
      final queueRepo = InMemoryOfflineQueueRepository();

      await tester.pumpWidget(
        _wrap(
          const ReportScreen(),
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhoto),
            locationServiceProvider.overrideWithValue(_MockLocationService()),
            voiceServiceProvider.overrideWithValue(_MockVoiceService()),
            offlineQueueRepositoryProvider.overrideWithValue(queueRepo),
            isOnlineProvider.overrideWithValue(false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('take_photo_btn')));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Submit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      final drafts = await queueRepo.getPendingDrafts();
      expect(drafts.length, equals(1));
      expect(
        find.text('No connection — report saved. Will sync when online.'),
        findsOneWidget,
      );
    });
  });
}
