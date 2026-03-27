import 'package:avalon/features/auth/domain/app_user.dart';
import 'package:avalon/features/auth/presentation/providers/auth_provider.dart';
import 'package:avalon/features/pacientes/data/paciente_service.dart';
import 'package:avalon/features/pacientes/domain/paciente.dart';
import 'package:avalon/features/pacientes/presentation/providers/paciente_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPacienteService extends Mock implements PacienteService {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  group('PacientesNotifier', () {
    late _MockPacienteService pacienteService;
    late ProviderContainer container;

    const user = AppUser(
      id: 'u-1',
      nombre: 'Admin Uno',
      email: 'admin@test.com',
      rol: 'admin',
      activa: true,
      sessionToken: 'token-1',
    );

    final paciente = Paciente(
      id: 'p-1',
      nombre: 'Paciente Uno',
      email: 'paciente@test.com',
      numeroDocumento: '123',
      activo: true,
      fechaRegistro: DateTime(2026, 3, 22),
      creadoPor: 'u-1',
    );

    setUp(() {
      pacienteService = _MockPacienteService();
      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          pacienteServiceProvider.overrideWithValue(pacienteService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('cargar trae pacientes al estado', () async {
      when(() => pacienteService.getAll()).thenAnswer((_) async => [paciente]);

      await container.read(pacientesProvider.notifier).cargar();
      final state = container.read(pacientesProvider);

      expect(state.pacientes, hasLength(1));
      expect(state.pacientes.first.id, 'p-1');
    });

    test('buscar aplica servicio de busqueda', () async {
      when(() => pacienteService.buscar('uno'))
          .thenAnswer((_) async => [paciente]);

      await container.read(pacientesProvider.notifier).buscar('uno');
      final state = container.read(pacientesProvider);

      expect(state.pacientes, hasLength(1));
      expect(state.pacientes.first.nombre, 'Paciente Uno');
    });

    test('crear agrega paciente nuevo y retorna true', () async {
      when(
        () => pacienteService.crear(
          nombre: any(named: 'nombre'),
          email: any(named: 'email'),
          numeroDocumento: any(named: 'numeroDocumento'),
          telefono: any(named: 'telefono'),
          direccion: any(named: 'direccion'),
          fechaNacimiento: any(named: 'fechaNacimiento'),
          historialMedico: any(named: 'historialMedico'),
          objetivosTerapeuticos: any(named: 'objetivosTerapeuticos'),
        ),
      ).thenAnswer((_) async => paciente);

      final ok = await container.read(pacientesProvider.notifier).crear(
            nombre: 'Paciente Uno',
            email: 'paciente@test.com',
            numeroDocumento: '123',
          );

      final state = container.read(pacientesProvider);
      expect(ok, isTrue);
      expect(state.pacientes.first.id, 'p-1');
    });

    test('eliminar quita paciente del estado y retorna true', () async {
      when(() => pacienteService.getAll()).thenAnswer((_) async => [paciente]);
      when(() => pacienteService.eliminar('p-1')).thenAnswer((_) async {});

      await container.read(pacientesProvider.notifier).cargar();
      final ok =
          await container.read(pacientesProvider.notifier).eliminar('p-1');
      final state = container.read(pacientesProvider);

      expect(ok, isTrue);
      expect(state.pacientes, isEmpty);
    });
  });
}
