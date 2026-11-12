import 'package:asisgo/core/services/live_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

void main() {
  final now = DateTime(2026, 11, 10, 9, 41);

  Map<String, Object?> stateFor(String fase, String titulo, String detalle) => {
    'fase': fase,
    'titulo': titulo,
    'detalle': detalle,
    'hora': 'Hoy, 9:41 a. m.',
    'iniciales': 'CM',
    'refrigerioDesde': now,
  };

  final states = {
    'entrada': stateFor('entrada', 'Entrada registrada', 'Jornada laboral'),
    'refrigerio': stateFor('refrigerio', 'Refrigerio iniciado', 'Duración'),
    'finRefrigerio': stateFor(
      'finRefrigerio',
      'Refrigerio finalizado',
      'Regreso a labores',
    ),
    'salida': stateFor('salida', 'Salida registrada', 'Jornada finalizada'),
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
