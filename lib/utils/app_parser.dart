import 'package:intl/intl.dart';

class AppParser {
  // Backend uses CultureInfo.InvariantCulture which results in "MM/dd/yyyy HH:mm:ss"
  static final DateFormat _backendFormat = DateFormat("MM/dd/yyyy HH:mm:ss");

  static DateTime parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    
    final str = value.toString();
    
    // 1. Try ISO-8601 first (Standard API responses usually fallback to this)
    try {
      return DateTime.parse(str);
    } catch (_) {}

    // 2. Try Backend specific format (used in Mappers/SignalR)
    try {
      // Backend typically stores/sends UTC, so we parse it as such
      return _backendFormat.parse(str, true); 
    } catch (e) {
      print("Date parsing error for '$str': $e");
      return DateTime.now();
    }
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}