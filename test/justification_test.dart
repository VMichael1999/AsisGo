import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asisgo/core/services/haptic_feedback_service.dart';
import 'package:asisgo/core/services/storage_service.dart';
import 'package:asisgo/features/justifications/data/justification_repository.dart';
import 'package:asisgo/features/justifications/domain/incident_justification.dart';
import 'package:asisgo/features/justifications/presentation/cubit/justification_cubit.dart';
import 'package:asisgo/features/justifications/presentation/cubit/justification_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late JustificationRepository repository;
  late JustificationCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    repository = JustificationRepository(storageService);
    await repository.init();
    cubit = JustificationCubit(
      repository: repository,
      hapticService: HapticFeedbackService(storageService),
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('IncidentJustification Entity & JSON Tests', () {
    test('Correctly serializes and deserializes IncidentJustification', () {
      final now = DateTime.now();
      final item = IncidentJustification(
        id: 'test-123',
        userId: 'USR-001',
        type: IncidentType.tardiness,
        title: 'Retraso de transporte',
        incidentDate: now,
        incidentTime: '08:45 AM',
        reason: 'Congestión en la Vía Expresa',
        attachmentPath: '/data/user/files/comprobante.jpg',
        attachmentName: 'comprobante.jpg',
        attachmentType: 'image/jpeg',
        fileSizeBytes: 102400,
        status: JustificationStatus.pending,
        submittedAt: now,
      );

      final json = item.toJson();
      final fromJson = IncidentJustification.fromJson(json);

      expect(fromJson.id, item.id);
      expect(fromJson.userId, item.userId);
      expect(fromJson.type, IncidentType.tardiness);
      expect(fromJson.title, item.title);
      expect(fromJson.reason, item.reason);
      expect(fromJson.attachmentName, 'comprobante.jpg');
      expect(fromJson.status, JustificationStatus.pending);
      expect(fromJson.hasAttachment, isTrue);
    });

    test('IncidentType default labels and titles are well formed', () {
      expect(IncidentType.medical.label, 'Descanso / Cita Médica');
      expect(IncidentType.tardiness.label, 'Tardanza al Ingreso');
      expect(IncidentType.omission.label, 'Omisión de Marcación');
      expect(JustificationStatus.approved.label, 'Aprobada');
    });
  });

  group('JustificationRepository Tests', () {
    test('Seeds initial demo justifications on empty storage', () async {
      final list = await repository.getJustifications('USR-001');
      expect(list.length, greaterThanOrEqualTo(2));
      expect(list.any((j) => j.status == JustificationStatus.approved), isTrue);
      expect(list.any((j) => j.status == JustificationStatus.pending), isTrue);
    });

    test('submitJustification prepends new justification and persists', () async {
      final now = DateTime.now();
      final created = await repository.submitJustification(
        userId: 'USR-001',
        type: IncidentType.medical,
        title: 'Cita con traumatólogo',
        incidentDate: now,
        incidentTime: '10:00 AM',
        reason: 'Evaluación de rodilla con receta médica adjunta.',
        attachmentPath: '/files/receta.pdf',
        attachmentName: 'receta.pdf',
        attachmentType: 'application/pdf',
        fileSizeBytes: 204800,
      );

      expect(created.id, isNotEmpty);
      expect(created.status, JustificationStatus.pending);
      expect(created.title, 'Cita con traumatólogo');

      final updatedList = await repository.getJustifications('USR-001');
      expect(updatedList.first.id, created.id);
      expect(updatedList.first.hasAttachment, isTrue);
    });
  });

  group('JustificationCubit Tests', () {
    test('Initial state is JustificationInitial', () {
      final standaloneCubit = JustificationCubit(repository: repository);
      expect(standaloneCubit.state, isA<JustificationInitial>());
      standaloneCubit.close();
    });

    test('loadJustifications emits loaded state with seeded records', () async {
      await cubit.loadJustifications('USR-001');

      expect(cubit.state, isA<JustificationLoaded>());
      final loaded = cubit.state as JustificationLoaded;
      expect(loaded.justifications.isNotEmpty, isTrue);
      expect(loaded.totalCount, greaterThanOrEqualTo(2));
    });

    test('submitJustification adds new record and updates state', () async {
      await cubit.loadJustifications('USR-001');
      final beforeCount = (cubit.state as JustificationLoaded).totalCount;

      final success = await cubit.submitJustification(
        type: IncidentType.earlyDeparture,
        title: 'Cita médica urgente',
        incidentDate: DateTime.now(),
        reason: 'Retiro anticipado por emergencia dental.',
      );

      expect(success, isTrue);
      final loaded = cubit.state as JustificationLoaded;
      expect(loaded.totalCount, beforeCount + 1);
      expect(loaded.justifications.first.type, IncidentType.earlyDeparture);
      expect(loaded.feedbackMessage, contains('Justificación enviada con éxito'));
    });

    test('setFilter correctly filters justifications by status', () async {
      await cubit.loadJustifications('USR-001');
      final loaded = cubit.state as JustificationLoaded;

      cubit.setFilter(JustificationStatus.pending);
      final pendingFiltered = (cubit.state as JustificationLoaded).filteredJustifications;
      expect(pendingFiltered.every((j) => j.status == JustificationStatus.pending), isTrue);

      cubit.setFilter(JustificationStatus.approved);
      final approvedFiltered = (cubit.state as JustificationLoaded).filteredJustifications;
      expect(approvedFiltered.every((j) => j.status == JustificationStatus.approved), isTrue);

      cubit.setFilter(null);
      final allFiltered = (cubit.state as JustificationLoaded).filteredJustifications;
      expect(allFiltered.length, loaded.totalCount);
    });
  });
}
