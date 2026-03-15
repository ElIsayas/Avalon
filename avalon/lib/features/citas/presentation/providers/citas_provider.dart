import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/cita.dart';
import '../../data/citas_service.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class CitasState {
  final List<Cita> citas;
  final List<Cita> citasHoy;
  final List<Cita> citasSemana;
  final List<Cita> proximasCitasPsicologo;
  final List<DisponibilidadPsicologo> disponibilidad;
  final List<Recordatorio> recordatorios;
  final Map<String, List<Cita>> citasPorDia;
  final bool cargando;
  final String? error;

  const CitasState({
    this.citas = const [],
    this.citasHoy = const [],
    this.citasSemana = const [],
    this.proximasCitasPsicologo = const [],
    this.disponibilidad = const [],
    this.recordatorios = const [],
    this.citasPorDia = const {},
    this.cargando = false,
    this.error,
  });

  CitasState copyWith({
    List<Cita>? citas,
    List<Cita>? citasHoy,
    List<Cita>? citasSemana,
    List<Cita>? proximasCitasPsicologo,
    List<DisponibilidadPsicologo>? disponibilidad,
    List<Recordatorio>? recordatorios,
    Map<String, List<Cita>>? citasPorDia,
    bool? cargando,
    String? error,
  }) {
    return CitasState(
      citas: citas ?? this.citas,
      citasHoy: citasHoy ?? this.citasHoy,
      citasSemana: citasSemana ?? this.citasSemana,
      proximasCitasPsicologo: proximasCitasPsicologo ?? this.proximasCitasPsicologo,
      disponibilidad: disponibilidad ?? this.disponibilidad,
      recordatorios: recordatorios ?? this.recordatorios,
      citasPorDia: citasPorDia ?? this.citasPorDia,
      cargando: cargando ?? this.cargando,
      error: error ?? this.error,
    );
  }
}

class CitasNotifier extends StateNotifier<CitasState> {
  final CitasService _service;

  CitasNotifier(this._service) : super(const CitasState());

  Future<void> cargarTodo() async {
    state = state.copyWith(cargando: true, error: null);
    
    try {
      await Future.wait([
        cargarCitasHoy(),
        cargarCitasSemana(),
        cargarDisponibilidad(),
        cargarRecordatorios(),
      ]);
      
      state = state.copyWith(cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<void> cargarCitasHoy() async {
    try {
      final citas = await _service.getCitasHoy();
      state = state.copyWith(citasHoy: citas);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cargarCitasSemana() async {
    try {
      final citas = await _service.getCitasSemana();
      state = state.copyWith(citasSemana: citas);
      _organizarCitasPorDia(citas);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cargarProximasCitasPsicologo() async {
    try {
      final citas = await _service.getProximasCitasPsicologo();
      state = state.copyWith(proximasCitasPsicologo: citas);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cargarDisponibilidad() async {
    try {
      final disponibilidad = await _service.getDisponibilidadPsicologos();
      state = state.copyWith(disponibilidad: disponibilidad);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cargarRecordatorios() async {
    try {
      final recordatorios = await _service.getRecordatorios();
      state = state.copyWith(recordatorios: recordatorios);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cargarCitas({
    DateTime? desde,
    DateTime? hasta,
    String? psicologoId,
    String? estado,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    
    try {
      final citas = await _service.getCitas(
        desde: desde,
        hasta: hasta,
        psicologoId: psicologoId,
        estado: estado,
      );
      state = state.copyWith(citas: citas, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
    }
  }

  Future<String?> verificarConflicto({
    required String psicologoId,
    required DateTime fechaHora,
    required int duracionMinutos,
  }) async {
    try {
      final citas = await _service.getCitas(
        desde: fechaHora.subtract(const Duration(hours: 2)),
        hasta: fechaHora.add(const Duration(hours: 2)),
        psicologoId: psicologoId,
      );

      for (final cita in citas) {
        final inicioCita = cita.fechaHora;
        final finCita = inicioCita.add(Duration(minutes: cita.duracionMinutos));
        final inicioNueva = fechaHora;
        final finNueva = fechaHora.add(Duration(minutes: duracionMinutos));

        if (inicioNueva.isBefore(finCita) && finNueva.isAfter(inicioCita)) {
          return 'Conflicto: El psicólogo ya tiene una cita de ${DateFormat('HH:mm').format(inicioCita)} a ${DateFormat('HH:mm').format(finCita)}';
        }
      }
      
      return null;
    } catch (e) {
      return 'Error al verificar conflicto: $e';
    }
  }

  Future<String?> crearCita({
    required String pacienteId,
    required String psicologoId,
    required DateTime fechaHora,
    required int duracionMinutos,
    required String estado,
    required String modalidad,
    required String tipoSesion,
    String? notas,
    bool? notificarSms,
    bool? notificarEmail,
    bool? recordatorio24h,
    bool? recordatorio1h,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    
    try {
      await _service.crearCita(
        pacienteId: pacienteId,
        psicologoId: psicologoId,
        fechaHora: fechaHora,
        duracionMinutos: duracionMinutos,
        tipo: tipoSesion,
        estado: estado,
        modalidad: modalidad,
        notas: notas,
        notificarSms: notificarSms ?? false,
        notificarEmail: notificarEmail ?? false,
        recordatorio24h: recordatorio24h ?? false,
        recordatorio1h: recordatorio1h ?? false,
      );
      
      await cargarTodo();
      return null;
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      return e.toString();
    }
  }

  Future<void> actualizarCita({
    required String citaId,
    DateTime? fechaHora,
    int? duracionMinutos,
    String? estado,
    bool? esOnline,
    String? notas,
    String? motivoCancelacion,
  }) async {
    state = state.copyWith(cargando: true, error: null);
    
    try {
      await _service.actualizarCita(
        citaId: citaId,
        fechaHora: fechaHora,
        duracionMinutos: duracionMinutos,
        estado: estado,
        esOnline: esOnline,
        notas: notas,
        motivoCancelacion: motivoCancelacion,
      );
      
      await cargarTodo();
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> crearRecordatorio({
    required String titulo,
    String? descripcion,
    String prioridad = 'normal',
  }) async {
    state = state.copyWith(cargando: true, error: null);
    
    try {
      await _service.crearRecordatorio(
        titulo: titulo,
        descripcion: descripcion,
        prioridad: prioridad,
      );
      
      await cargarRecordatorios();
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> resolverRecordatorio(String recordatorioId) async {
    state = state.copyWith(cargando: true, error: null);
    
    try {
      await _service.resolverRecordatorio(recordatorioId);
      await cargarRecordatorios();
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> eliminarRecordatorio(String recordatorioId) async {
    state = state.copyWith(cargando: true, error: null);
    
    try {
      await _service.eliminarRecordatorio(recordatorioId);
      await cargarRecordatorios();
    } catch (e) {
      state = state.copyWith(cargando: false, error: e.toString());
      rethrow;
    }
  }

  void limpiarError() {
    state = state.copyWith(error: null);
  }

  void _organizarCitasPorDia(List<Cita> citas) {
    final Map<String, List<Cita>> citasPorDia = {};
    
    for (final cita in citas) {
      final diaKey = '${cita.fechaHora.year}-${cita.fechaHora.month.toString().padLeft(2, '0')}-${cita.fechaHora.day.toString().padLeft(2, '0')}';
      
      if (!citasPorDia.containsKey(diaKey)) {
        citasPorDia[diaKey] = [];
      }
      citasPorDia[diaKey]!.add(cita);
    }
    
    for (final dia in citasPorDia.keys) {
      citasPorDia[dia]!.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    }
    
    state = state.copyWith(citasPorDia: citasPorDia);
  }
}

final citasServiceProvider = Provider<CitasService>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Usuario no autenticado');
  
  return CitasService(
    supabase,
    user.sessionToken,
  );
});

final citasProvider = StateNotifierProvider<CitasNotifier, CitasState>((ref) {
  final service = ref.watch(citasServiceProvider);
  return CitasNotifier(service);
});

final citasPorDiaProvider = Provider<Map<String, List<Cita>>>((ref) {
  return ref.watch(citasProvider).citasPorDia;
});

final recordatoriosProvider = Provider<List<Recordatorio>>((ref) {
  return ref.watch(citasProvider).recordatorios;
});

final disponibilidadProvider = Provider<List<DisponibilidadPsicologo>>((ref) {
  return ref.watch(citasProvider).disponibilidad;
});
