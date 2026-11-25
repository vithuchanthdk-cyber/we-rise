import 'package:flutter_test/flutter_test.dart';
import 'package:we_rise/features/complaints/domain/models.dart';
import 'package:we_rise/features/volunteer/domain/certificate_service.dart';

void main() {
  group('CertificateService', () {
    test('calculates total hours from completed tasks only', () {
      final tasks = [
        Task(
          id: 't1',
          complaintId: 'c1',
          partnerOrgId: 'org-1',
          requirements: const [],
          createdAt: DateTime(2026, 11, 1),
          volunteerIds: const ['u-vol-1', 'u-vol-2'],
          completedAt: DateTime(2026, 11, 2),
          estimatedHours: 2.5,
        ),
        Task(
          id: 't2',
          complaintId: 'c2',
          partnerOrgId: 'org-1',
          requirements: const [],
          createdAt: DateTime(2026, 11, 3),
          volunteerIds: const ['u-vol-1'],
          completedAt: null, // not completed yet
          estimatedHours: 4.0,
        ),
        Task(
          id: 't3',
          complaintId: 'c3',
          partnerOrgId: 'org-1',
          requirements: const [],
          createdAt: DateTime(2026, 11, 4),
          volunteerIds: const ['u-vol-1'],
          completedAt: DateTime(2026, 11, 5),
          estimatedHours: 1.5,
        ),
      ];

      expect(
        CertificateService.calculateTotalHours(tasks, 'u-vol-1'),
        equals(4.0),
      );
      expect(
        CertificateService.calculateTotalHours(tasks, 'u-vol-2'),
        equals(2.5),
      );
    });

    test('generates valid 8-char verification code', () {
      final code1 = CertificateService.generateVerificationCode(
        userId: 'u-vol-1',
        issuedAt: DateTime(2026, 11, 25, 10, 0),
      );
      final code2 = CertificateService.generateVerificationCode(
        userId: 'u-vol-2',
        issuedAt: DateTime(2026, 11, 25, 10, 0),
      );

      expect(CertificateService.isValidCode(code1), isTrue);
      expect(CertificateService.isValidCode(code2), isTrue);
      expect(code1, isNot(equals(code2)));
    });
  });
}
