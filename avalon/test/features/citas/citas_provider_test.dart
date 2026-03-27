import 'package:avalon/core/notifications/notifications_service.dart';
import 'package:avalon/features/citas/data/citas_service.dart';
import 'package:avalon/features/citas/domain/cita.dart';
import 'package:avalon/features/citas/presentation/providers/citas_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCitasService extends Mock implements CitasService {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  group('CitasNotifier', () {
    late _MockCitasService citasService;
    late CitasNotifier notifier;

    final citaBase = Cita(
      id: 'c-1',
      pacienteId: 'p-1',
      psicologoId: 'psi-1',
      fechaHora: DateTime(2026, 3, 23, 9, 0),
      duracionMinutos: 50,
      tipoSesion: TipoSesion.seguimiento,
      estado: EstadoCita.agendada,
      modalidad: ModalidadCita.presencial,
      fechaActualizacion: DateTime(2026, 3, 23, 8, 0),
      fechaCreacion: DateTime(2026, 3, 22, 8, 0),
      pacienteNombre: 'Paciente Uno',
      psicologoNombre: 'Psicologo Uno',
    );

    setUp(() {
      citasService = _MockCitasService();
      notifier =
          CitasNotifier(citasService, AvalonNotificationsService.instance);

      when(
        () => citasService.getCitas(
          desde: any(named: 'desde'),
          hasta: any(named: 'hasta'),
          psicologoId: any(named: 'psicologoId'),
          estado: any(named: 'estado'),
        ),
      ).thenAnswer((_) async => []);
      when(() => citasService.getCitasHoy()).thenAnswer((_) async => []);
      when(() => citasService.getCitasSemana()).thenAnswer((_) async => []);
      when(() => citasService.getProximasCitasPsicologo(
          limite: any(named: 'limite'))).thenAnswer((_) async => []);
      when(() => citasService.getDisponibilidadPsicologos())
          .thenAnswer((_) async => []);
      when(
        () => citasService.actualizarCita(
          citaId: any(named: 'citaId'),
          fechaHora: any(named: 'fechaHora'),
          duracionMinutos: any(named: 'duracionMinutos'),
          estado: any(named: 'estado'),
          modalidad: any(named: 'modalidad'),
          esOnline: any(named: 'esOnline'),
          notas: any(named: 'notas'),
          motivoCancelacion: any(named: 'motivoCancelacion'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});
    });

    test('verificarConflicto detecta choque de horario', () async {
      when(
        () => citasService.getCitas(
          desde: any(named: 'desde'),
          hasta: any(named: 'hasta'),
          psicologoId: any(named: 'psicologoId'),
          estado: any(named: 'estado'),
        ),
      ).thenAnswer((_) async => [citaBase]);

      final conflicto = await notifier.verificarConflicto(
        psicologoId: 'psi-1',
        fechaHora: DateTime(2026, 3, 23, 9, 20),
        duracionMinutos: 30,
      );

      expect(conflicto, isNotNull);
      expect(conflicto, contains('Conflicto'));
    });

    test('crearCita ejecuta servicio y recarga estado', () async {
      when(
        () => citasService.crearCita(
          pacienteId: any(named: 'pacienteId'),
          psicologoId: any(named: 'psicologoId'),
          fechaHora: any(named: 'fechaHora'),
          duracionMinutos: any(named: 'duracionMinutos'),
          tipo: any(named: 'tipo'),
          estado: any(named: 'estado'),
          modalidad: any(named: 'modalidad'),
          motivoConsulta: any(named: 'motivoConsulta'),
          notas: any(named: 'notas'),
          notificarSms: any(named: 'notificarSms'),
          notificarEmail: any(named: 'notificarEmail'),
          recordatorio24h: any(named: 'recordatorio24h'),
          recordatorio1h: any(named: 'recordatorio1h'),
        ),
      ).thenAnswer((_) async => citaBase);

      final error = await notifier.crearCita(
        pacienteId: 'p-1',
        psicologoId: 'psi-1',
        fechaHora: DateTime(2026, 3, 23, 12, 0),
        duracionMinutos: 50,
        estado: 'agendada',
        modalidad: 'presencial',
        tipoSesion: 'seguimiento',
        recordatorio24h: false,
        recordatorio1h: false,
      );

      expect(error, isNull);
      verify(
        () => citasService.crearCita(
          pacienteId: any(named: 'pacienteId'),
          psicologoId: any(named: 'psicologoId'),
          fechaHora: any(named: 'fechaHora'),
          duracionMinutos: any(named: 'duracionMinutos'),
          tipo: any(named: 'tipo'),
          estado: any(named: 'estado'),
          modalidad: any(named: 'modalidad'),
          motivoConsulta: any(named: 'motivoConsulta'),
          notas: any(named: 'notas'),
          notificarSms: any(named: 'notificarSms'),
          notificarEmail: any(named: 'notificarEmail'),
          recordatorio24h: any(named: 'recordatorio24h'),
          recordatorio1h: any(named: 'recordatorio1h'),
        ),
      ).called(1);
    });

    test('actualizarCita ejecuta servicio', () async {
      await notifier.actualizarCita(citaId: 'c-1', estado: 'cancelada');

      verify(
        () => citasService.actualizarCita(
          citaId: 'c-1',
          fechaHora: any(named: 'fechaHora'),
          duracionMinutos: any(named: 'duracionMinutos'),
          estado: 'cancelada',
          modalidad: any(named: 'modalidad'),
          esOnline: any(named: 'esOnline'),
          notas: any(named: 'notas'),
          motivoCancelacion: any(named: 'motivoCancelacion'),
        ),
      ).called(1);
    });
  });
}
