import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/core/l10n/app_localizations.dart';
import 'package:we_rise/features/complaints/data/in_memory_repositories.dart';
import 'package:we_rise/features/complaints/data/providers.dart';
import 'package:we_rise/features/complaints/presentation/complaint_detail_screen.dart';

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
  group('ComplaintDetailScreen', () {
    testWidgets('renders timeline stepper, priority explainer, and DEMAND ACTION',
        (tester) async {
      final repo = InMemoryComplaintRepository();
      await tester.pumpWidget(
        _wrap(
          const ComplaintDetailScreen(complaintId: 'c001'),
          overrides: [
            complaintRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tracking ID
      expect(find.text('WR-CHE-2026-000001'), findsOneWidget);

      // Scroll to Timeline
      await tester.scrollUntilVisible(
        find.text('Timeline'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Verified'), findsWidgets);
      expect(find.textContaining('Role: citizen'), findsOneWidget);

      // Expand "Why this priority?"
      await tester.scrollUntilVisible(
        find.byKey(const Key('priority_explainer_tile')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(const Key('priority_explainer_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('priority_explainer_tile')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Severity (35%)'), findsOneWidget);
      expect(find.textContaining('Area Vulnerability (20%)'), findsOneWidget);

      // Tap DEMAND ACTION (one support per user)
      await tester.scrollUntilVisible(
        find.byKey(const Key('demand_action_btn')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(const Key('demand_action_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('demand_action_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('You supported this'), findsOneWidget);
    });
  });
}
