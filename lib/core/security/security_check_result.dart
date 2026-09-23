import 'package:equatable/equatable.dart';

enum SecurityViolationType {
  none,
  mockLocationDetected,
  suspiciousAccuracy,
  developerOptionsSpoofing,
}

class SecurityCheckResult extends Equatable {
  final bool isSecure;
  final bool isMocked;
  final SecurityViolationType violationType;
  final String title;
  final String message;
  final DateTime evaluatedAt;

  const SecurityCheckResult({
    required this.isSecure,
    required this.isMocked,
    this.violationType = SecurityViolationType.none,
    required this.title,
    required this.message,
    required this.evaluatedAt,
  });

  factory SecurityCheckResult.secure() {
    return SecurityCheckResult(
      isSecure: true,
      isMocked: false,
      violationType: SecurityViolationType.none,
      title: 'Ubicación Certificada',
      message: 'Señal GPS hardware real validada sin alteraciones.',
      evaluatedAt: DateTime.now(),
    );
  }

  factory SecurityCheckResult.violation({
    required SecurityViolationType violationType,
    required String title,
    required String message,
    bool isMocked = true,
  }) {
    return SecurityCheckResult(
      isSecure: false,
      isMocked: isMocked,
      violationType: violationType,
      title: title,
      message: message,
      evaluatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        isSecure,
        isMocked,
        violationType,
        title,
        message,
        evaluatedAt,
      ];
}
