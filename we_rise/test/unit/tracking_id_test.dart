import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/tracking_id_service.dart';

void main() {
  group('TrackingIdService', () {
    test('generates correct format WR-CHE-YYYY-NNNNNN', () {
      final id = TrackingIdService.generate(year: 2026, sequence: 42);
      expect(id, equals('WR-CHE-2026-000042'));
    });

    test('zero-pads sequence to 6 digits', () {
      expect(
        TrackingIdService.generate(year: 2026, sequence: 1),
        'WR-CHE-2026-000001',
      );
      expect(
        TrackingIdService.generate(year: 2026, sequence: 999999),
        'WR-CHE-2026-999999',
      );
    });

    test('validates correct format', () {
      expect(TrackingIdService.isValid('WR-CHE-2026-000001'), isTrue);
      expect(TrackingIdService.isValid('WR-CHE-2025-123456'), isTrue);
    });

    test('rejects invalid formats', () {
      expect(TrackingIdService.isValid(''), isFalse);
      expect(TrackingIdService.isValid('WR-CHE-2026-1'), isFalse);
      expect(TrackingIdService.isValid('XX-CHE-2026-000001'), isFalse);
    });
  });
}
