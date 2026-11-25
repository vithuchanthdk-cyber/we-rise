import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/enums.dart';
import 'package:we_rise/features/whatsapp/domain/whatsapp_parser.dart';

void main() {
  group('WhatsAppParser', () {
    test('English message creates PENDING_REVIEW report with detected category & ward',
        () {
      final c = WhatsAppParser.parseToComplaint(
        message: 'Sewage overflow near Perungudi bus stop',
        senderToken: 'WA-001',
        sequenceNumber: 101,
        now: DateTime(2026, 11, 25),
      );

      expect(c.status, equals(ComplaintStatus.PENDING_REVIEW));
      expect(c.category, equals(ComplaintCategory.sewage));
      expect(c.wardId, equals('perungudi'));
      expect(c.trackingId, equals('WR-CHE-2026-000101'));
      expect(c.timeline.first.actorRole, equals('whatsapp_intake'));
    });

    test('Tamil message creates PENDING_REVIEW report with detected category & ward',
        () {
      final c = WhatsAppParser.parseToComplaint(
        message: 'அடையாறு பகுதியில் குப்பை தேங்கியுள்ளது',
        senderToken: 'WA-002',
        sequenceNumber: 102,
        now: DateTime(2026, 11, 25),
      );

      expect(c.status, equals(ComplaintStatus.PENDING_REVIEW));
      expect(c.category, equals(ComplaintCategory.garbage));
      expect(c.wardId, equals('adyar'));
      expect(c.note, contains('குப்பை'));
    });
  });
}
