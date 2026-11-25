import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/core/l10n/app_localizations.dart';
import 'package:we_rise/features/complaints/data/in_memory_repositories.dart';
import 'package:we_rise/features/complaints/data/providers.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/complaints/domain/models.dart';
import 'package:we_rise/features/complaints/presentation/complaint_detail_screen.dart';
import 'package:we_rise/features/moderation/presentation/review_screen.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('Moderator ReviewScreen', () {
    testWidgets('approves pending complaint and creates volunteer task',
        (tester) async {
      final compRepo = InMemoryComplaintRepository();
      final taskRepo = InMemoryTaskRepository(complaintRepo: compRepo);

      // c003 is PENDING_REVIEW garbage (low risk, volunteer-safe)
      await tester.pumpWidget(
        _wrap(
          const ReviewScreen(complaintId: 'c003'),
          overrides: [
            complaintRepositoryProvider.overrideWithValue(compRepo),
            taskRepositoryProvider.overrideWithValue(taskRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('approve_btn')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('approve_btn')));
      await tester.pumpAndSettle();

      final updated = await compRepo.getById('c003');
      expect(updated?.status, equals(ComplaintStatus.VERIFIED));
      expect(updated?.assignedOrgId, isNotNull);

      final tasks = await taskRepo.getForComplaint('c003');
      expect(tasks, isNotEmpty);
    });

    testWidgets('merges duplicate complaint and adds supporter to target',
        (tester) async {
      final compRepo = InMemoryComplaintRepository();
      final taskRepo = InMemoryTaskRepository(complaintRepo: compRepo);

      // c001 is VERIFIED sewage at (13.1234, 80.2988) on Nov 10
      // Create a nearby duplicate PENDING_REVIEW sewage complaint
      final dup = Complaint(
        id: 'c-dup-1',
        trackingId: 'WR-CHE-2026-000999',
        category: ComplaintCategory.sewage,
        severity: 5,
        status: ComplaintStatus.PENDING_REVIEW,
        location: const LatLng(13.12345, 80.29885), // ~8 m away
        wardId: 'tondiarpet',
        photos: const [],
        createdAt: DateTime(2026, 11, 15),
        lastStatusChangeAt: DateTime(2026, 11, 15),
        reporterId: 'u-dup-reporter',
        supporterIds: const [],
        riskClass: RiskClass.medium,
        priorityScore: 60,
        escalated: false,
        reopenCount: 0,
      );
      await compRepo.create(dup);

      await tester.pumpWidget(
        _wrap(
          const ReviewScreen(complaintId: 'c-dup-1'),
          overrides: [
            complaintRepositoryProvider.overrideWithValue(compRepo),
            taskRepositoryProvider.overrideWithValue(taskRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('merge_duplicate_btn')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('merge_duplicate_btn')));
      await tester.pumpAndSettle();

      final mergedIncoming = await compRepo.getById('c-dup-1');
      expect(mergedIncoming?.status, equals(ComplaintStatus.REJECTED));
      expect(mergedIncoming?.mergedIntoId, equals('c001'));

      final target = await compRepo.getById('c001');
      expect(target?.supporterIds, contains('u-dup-reporter'));
    });

    testWidgets(
        'moderator sees onBehalfOf contact details but public view never can',
        (tester) async {
      final compRepo = InMemoryComplaintRepository();
      final taskRepo = InMemoryTaskRepository(complaintRepo: compRepo);

      final onBehalfComplaint = Complaint(
        id: 'c-behalf-1',
        trackingId: 'WR-CHE-2026-000777',
        category: ComplaintCategory.garbage,
        severity: 3,
        status: ComplaintStatus.VERIFIED,
        location: const LatLng(13.0012, 80.2565),
        wardId: 'adyar',
        photos: const [],
        createdAt: DateTime(2026, 11, 19),
        lastStatusChangeAt: DateTime(2026, 11, 19),
        reporterId: 'u-volunteer-1',
        supporterIds: const [],
        riskClass: RiskClass.low,
        priorityScore: 50,
        escalated: false,
        reopenCount: 0,
        onBehalfOf: 'Elderly resident Selvam, 2nd Cross St',
      );
      await compRepo.create(onBehalfComplaint);

      // 1. Moderator ReviewScreen DOES show onBehalfOf
      await tester.pumpWidget(
        _wrap(
          const ReviewScreen(complaintId: 'c-behalf-1'),
          overrides: [
            complaintRepositoryProvider.overrideWithValue(compRepo),
            taskRepositoryProvider.overrideWithValue(taskRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Elderly resident Selvam, 2nd Cross St'),
        findsOneWidget,
      );

      // 2. Public ComplaintDetailScreen NEVER shows onBehalfOf
      await tester.pumpWidget(
        _wrap(
          const ComplaintDetailScreen(complaintId: 'c-behalf-1'),
          overrides: [
            complaintRepositoryProvider.overrideWithValue(compRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Selvam'), findsNothing);
    });
  });
}
