import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asisgo/core/widgets/asis_session_expired_dialog.dart';
import 'package:asisgo/features/auth/domain/user_model.dart';
import 'package:asisgo/features/attendance_map/domain/shift_phase.dart';

void main() {
  test('User model serialization and deserialization', () {
    const user = User(
      id: 'USR-999',
      fullName: 'Test Developer',
      email: 'test@asisgo.com',
      role: 'QA Engineer',
      documentNumber: '88776655',
      assignedBranchId: 'BR-01',
      shiftStartTime: '08:30',
      shiftEndTime: '18:00',
    );

    final json = user.toJson();
    final reconstructed = User.fromJson(json);

    expect(reconstructed.id, equals(user.id));
    expect(reconstructed.fullName, equals(user.fullName));
    expect(reconstructed.email, equals(user.email));
  });

  test('ShiftPhase labels and nextExpectedAttendance mapping', () {
    expect(ShiftPhase.notStarted.nextExpectedAttendance, equals(AttendanceType.checkIn));
    expect(ShiftPhase.working.nextExpectedAttendance, equals(AttendanceType.lunchStart));
    expect(ShiftPhase.onLunch.nextExpectedAttendance, equals(AttendanceType.lunchEnd));
    expect(ShiftPhase.resumed.nextExpectedAttendance, equals(AttendanceType.checkOut));
    expect(ShiftPhase.completed.nextExpectedAttendance, isNull);
  });

  testWidgets('AsisSessionExpiredDialog renders properly and responds to buttons', (tester) async {
    bool dismissedViaX = false;
    bool dismissedViaButton = false;

    // Prueba de pulsacion sobre boton de cierre X
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsisSessionExpiredDialog(
            message: 'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
            onDismissAndLogin: () {
              dismissedViaX = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Inicio de Sesión Expirado'), findsOneWidget);
    expect(find.text('SEGURIDAD CORPORATIVA'), findsOneWidget);
    expect(find.text('Volver a Iniciar Sesión'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(dismissedViaX, isTrue);

    // Prueba de pulsacion sobre boton principal de inicio de sesion
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsisSessionExpiredDialog(
            message: 'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
            onDismissAndLogin: () {
              dismissedViaButton = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Volver a Iniciar Sesión'));
    await tester.pump();
    expect(dismissedViaButton, isTrue);
  });
}
