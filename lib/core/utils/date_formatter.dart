import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFullDate(DateTime dateTime) {
    // Ejemplo: "Lunes, 22 de Septiembre"
    return DateFormat('EEEE, d \'de\' MMMM', 'es').format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    // Ejemplo: "22/09/2026"
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    // Ejemplo: "08:30 AM"
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
