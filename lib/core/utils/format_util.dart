class FormatUtil {
  static String formatTimestamp(DateTime dateTime) {
    return '${dateTime.toUtc().toIso8601String().split('.').first}Z';
  }
}
