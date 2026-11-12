import 'package:asisgo/core/services/live_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

void main() {
  final now = DateTime(2026, 11, 10, 11, 14);

  Map<String, Object?> stateFor(String fase, String titulo) => {
    'fase': fase,
    'titulo': titulo,
    'horario': '9:00 a. m. – 6:00 p. m.',
    'entradaTxt': '9:00 a. m.',
    'salidaTxt': '6:00 p. m.',
    'entradaTs': DateTime(2026, 11, 10, 9, 0),
    'finTs': DateTime(2026, 11, 10, 18, 0),
    'refrigerioDesde': now,
  };

  final states = {
    'jornada': stateFor('jornada', 'En jornada'),
    'refrigerio': stateFor('refrigerio', 'En refrigerio'),
  };

  for (final entry in states.entries) {
    test('el diseño de la isla es válido en la fase ${entry.key}', () {
      final report = LiveIsland.check(
        LiveActivityService.shiftLayout,
        LiveState.normalize(entry.value),
      );
      final errors = report.items
          .where((c) => c.severity == LiveSeverity.bad)
          .map((c) => '${c.code}: ${c.message}');
      expect(errors, isEmpty);
    });
  }
}
