import 'package:flutter/foundation.dart';

class NotificationService {
  Future<void> initialize() async {
    debugPrint('NotificationService initialized successfully.');
  }

  Future<void> scheduleShiftStartReminder({required String time}) async {
    debugPrint('Scheduled shift start reminder at $time');
  }

  Future<void> scheduleLunchReminder({required int durationMinutes}) async {
    debugPrint('Scheduled lunch end reminder after $durationMinutes minutes');
  }

  Future<void> cancelAll() async {
    debugPrint('All scheduled notifications cancelled');
  }
}
