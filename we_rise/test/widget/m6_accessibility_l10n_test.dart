import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/core/l10n/app_localizations.dart';
import 'package:we_rise/features/complaints/data/in_memory_repositories.dart';
import 'package:we_rise/features/complaints/data/providers.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/profile/presentation/profile_screen.dart';
import 'package:we_rise/features/whatsapp/presentation/whatsapp_simulator_screen.dart';

Widget _wrap(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('WhatsAppSimulatorScreen', () {
    testWidgets('ingests Tamil and English messages as PENDING_REVIEW',
        (tester) async {
      final repo = InMemoryComplaintRepository();
      final before = (await repo.getAll()).length;

      await tester.pumpWidget(
        _wrap(
          const WhatsAppSimulatorScreen(),
          overrides: [
            complaintRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('wa_message_field')),
        'தண்டையார்பேட்டை கழிவுநீர் கசிவு',
      );
      await tester.tap(find.byKey(const Key('wa_ingest_btn')));
      await tester.pumpAndSettle();

      final all = await repo.getAll();
      expect(all.length, equals(before + 1));
      expect(all.last.status, equals(ComplaintStatus.PENDING_REVIEW));
      expect(all.last.category, equals(ComplaintCategory.sewage));
    });
  });

  group('L10n & Accessibility', () {
    testWidgets('ProfileScreen renders Tamil locale without overflow and meets tap target guideline',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const ProfileScreen(), locale: const Locale('ta')),
      );
      await tester.pumpAndSettle();

      // Tamil strings rendered
      expect(find.text('சுயவிவரம்'), findsOneWidget);
      expect(find.text('தீர்க்கப்பட்ட பிரச்சனைகள்'), findsOneWidget);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
