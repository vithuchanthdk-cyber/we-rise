import '../domain/enums.dart';

/// Deterministic offline mock AI category classifier for demo mode.
/// Suggests a category from note text (English or Tamil) or defaults to pothole.
abstract final class MockAiCategoryService {
  static ComplaintCategory suggest({String? note, int photoCount = 1}) {
    final text = (note ?? '').toLowerCase();
    if (text.contains('sewage') ||
        text.contains('gutter') ||
        text.contains('கழிவு')) {
      return ComplaintCategory.sewage;
    }
    if (text.contains('water') ||
        text.contains('flood') ||
        text.contains('rain') ||
        text.contains('நீர்')) {
      return ComplaintCategory.waterlogging;
    }
    if (text.contains('drain') ||
        text.contains('clog') ||
        text.contains('வடிகால்')) {
      return ComplaintCategory.blockedDrain;
    }
    if (text.contains('garbage') ||
        text.contains('trash') ||
        text.contains('waste') ||
        text.contains('குப்பை')) {
      return ComplaintCategory.garbage;
    }
    if (text.contains('light') ||
        text.contains('wire') ||
        text.contains('pole') ||
        text.contains('விளக்கு') ||
        text.contains('மின்')) {
      return ComplaintCategory.streetlight;
    }
    if (text.contains('pothole') ||
        text.contains('road') ||
        text.contains('குழி')) {
      return ComplaintCategory.pothole;
    }
    return photoCount > 1 ? ComplaintCategory.garbage : ComplaintCategory.pothole;
  }
}
