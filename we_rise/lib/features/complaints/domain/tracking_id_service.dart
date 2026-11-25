/// Generates complaint tracking IDs in the format WR-CHE-YYYY-NNNNNN.
class TrackingIdService {
  /// Generate a tracking ID.
  ///
  /// [year] defaults to the current year.
  /// [sequence] is a 1-based integer, zero-padded to 6 digits.
  static String generate({required int sequence, int? year}) {
    final y = year ?? DateTime.now().year;
    final seq = sequence.toString().padLeft(6, '0');
    return 'WR-CHE-$y-$seq';
  }

  /// Parse the sequence number from an existing tracking ID.
  static int parseSequence(String trackingId) {
    final parts = trackingId.split('-');
    if (parts.length != 4) throw FormatException('Invalid tracking ID: $trackingId');
    return int.parse(parts[3]);
  }

  /// Validate tracking ID format.
  static bool isValid(String trackingId) {
    final regex = RegExp(r'^WR-CHE-\d{4}-\d{6}$');
    return regex.hasMatch(trackingId);
  }
}
