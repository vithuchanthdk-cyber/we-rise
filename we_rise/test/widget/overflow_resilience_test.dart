import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/core/l10n/app_localizations.dart';
import 'package:we_rise/features/authority/presentation/authority_screen.dart';
import 'package:we_rise/features/complaints/data/in_memory_repositories.dart';
import 'package:we_rise/features/complaints/data/providers.dart';
import 'package:we_rise/features/complaints/presentation/complaint_detail_screen.dart';
import 'package:we_rise/features/complaints/presentation/my_reports_screen.dart';
import 'package:we_rise/features/complaints/presentation/solved_gallery_screen.dart';
import 'package:we_rise/features/moderation/presentation/moderation_screen.dart';
import 'package:we_rise/features/profile/presentation/settings_screen.dart';
import 'package:we_rise/features/volunteer/presentation/tasks_screen.dart';

Widget _buildTestApp({
  required Widget child,
  required InMemoryComplaintRepository complaintRepo,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      complaintRepositoryProvider.overrideWithValue(complaintRepo),
      taskRepositoryProvider.overrideWithValue(
        InMemoryTaskRepository(complaintRepo: complaintRepo),
      ),
      confirmationRepositoryProvider.overrideWithValue(
        InMemoryConfirmationRepository(),
      ),
      userRepositoryProvider.overrideWithValue(InMemoryUserRepository()),
      orgRepositoryProvider.overrideWithValue(InMemoryOrgRepository()),
      offlineQueueRepositoryProvider.overrideWithValue(
        InMemoryOfflineQueueRepository(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ta'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(1.3),
        ),
        child: SizedBox(
          width: 360,
          height: 800,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Screens render at 360x800 with 1.3x text scale in Tamil without overflow',
      (tester) async {
    final complaintRepo = InMemoryComplaintRepository();
    final allComplaints = await complaintRepo.getAll();
    final firstId = allComplaints.first.id;

    // Fail if Flutter reports any layout overflow or exception
    FlutterErrorDetails? caughtError;
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed by')) {
        caughtError = details;
      }
      oldHandler?.call(details);
    };

    try {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. My Reports screen
      await tester.pumpWidget(
        _buildTestApp(
          child: const MyReportsScreen(),
          complaintRepo: complaintRepo,
        ),
      );
      await tester.pumpAndSettle();
      expect(caughtError, isNull, reason: 'MyReportsScreen overflowed');

      // 2. Moderation screen
      await tester.pumpWidget(
        _buildTestApp(
          child: const ModerationScreen(),
          complaintRepo: complaintRepo,
        ),
      );
      await tester.pumpAndSettle();
      expect(caughtError, isNull, reason: 'ModerationScreen overflowed');

      // 3. Tasks screen
      await tester.pumpWidget(
        _buildTestApp(
          child: const TasksScreen(),
          complaintRepo: complaintRepo,
        ),
      );
      await tester.pumpAndSettle();
      expect(caughtError, isNull, reason: 'TasksScreen overflowed');

      // 4. Authority screen
      await tester.pumpWidget(
        _buildTestApp(
          child: const AuthorityScreen(),
          complaintRepo: complaintRepo,
        ),
      );
      await tester.pumpAndSettle();
      expect(caughtError, isNull, reason: 'AuthorityScreen overflowed');

      // 5. Solved gallery screen
      await tester.pumpWidget(
        _buildTestApp(
          child: const SolvedGalleryScreen(),
          complaintRepo: complaintRepo,
        ),
      );
      await tester.pumpAndSettle();
      expect(caughtError, isNull, reason: 'SolvedGalleryScreen overflowed');

      // 6. Settings screen
      await tester.pumpWidget(
        _buildTestApp(
          child: const SettingsScreen(),
          complaintRepo: complaintRepo,
        ),
      );
      await tester.pumpAndSettle();
      expect(caughtError, isNull, reason: 'SettingsScreen overflowed');

      // 7. Complaint detail screen
      await tester.pumpWidget(
        _buildTestApp(
          child: ComplaintDetailScreen(complaintId: firstId),
          complaintRepo: complaintRepo,
        ),
      );
      await tester.pumpAndSettle();
      expect(caughtError, isNull, reason: 'ComplaintDetailScreen overflowed');
    } finally {
      FlutterError.onError = oldHandler;
    }
  });
}
