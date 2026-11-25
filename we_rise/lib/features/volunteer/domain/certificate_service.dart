import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';
import '../../complaints/domain/models.dart';

/// Handles NSS/volunteer hours calculation, unique verification code
/// generation, and verified PDF certificate creation.
class CertificateService {
  static const _uuid = Uuid();

  /// Calculates total verified volunteer hours from completed [tasks]
  /// where [userId] participated.
  static double calculateTotalHours(List<Task> tasks, String userId) {
    return tasks
        .where((t) => t.isCompleted && t.volunteerIds.contains(userId))
        .fold<double>(0.0, (sum, t) => sum + t.estimatedHours);
  }

  /// Generates a deterministic-format 8-character uppercase alphanumeric
  /// verification code (e.g., `WR8A4F1C`).
  static String generateVerificationCode({
    required String userId,
    required DateTime issuedAt,
  }) {
    final digest = sha256
        .convert(utf8.encode('$userId:${issuedAt.millisecondsSinceEpoch}'))
        .toString()
        .toUpperCase();
    return 'WR${digest.substring(0, 6)}';
  }

  static bool isValidCode(String code) =>
      RegExp(r'^WR[A-Z0-9]{6}$').hasMatch(code);

  static Certificate buildCertificate({
    required AppUser user,
    required Organisation org,
    required double hours,
    DateTime? issuedAt,
  }) {
    final ts = issuedAt ?? DateTime.now();
    return Certificate(
      id: _uuid.v4(),
      userId: user.id,
      anonymousHandle: user.anonymousHandle,
      orgId: org.id,
      hours: hours,
      issuedAt: ts,
      verificationCode: generateVerificationCode(userId: user.id, issuedAt: ts),
    );
  }

  static Future<File> generatePdf({
    required Certificate certificate,
    required Organisation org,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WE RISE — VERIFIED VOLUNTEER CERTIFICATE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Awarded to: ${certificate.anonymousHandle}'),
              pw.Text('Supervising Organisation: ${org.name}'),
              pw.Text(
                'Verified Hours: ${certificate.hours.toStringAsFixed(1)} hours',
              ),
              pw.Text(
                'Issued on: ${certificate.issuedAt.toIso8601String().split('T').first}',
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Verification Code: ${certificate.verificationCode}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}werise_cert_${certificate.verificationCode}.pdf',
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
