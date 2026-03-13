import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/cita_service.dart';
import '../../domain/entities/cita.dart';

final citaServiceProvider = Provider<CitaService>((ref) {
  return CitaService(Supabase.instance.client);
});

class CitasState {
  final List<Cita> citas;
  final List<Cita> citasHoy;
  final Map<String, dynamic> estadisticas;
  final bool isLoading;
  final bool isLoadingEstadisticas;
  final String? error;
  final String? successMessage;
  final DateTime? fechaSeleccionada;
  final List<Cita> citasDelDia;

  const CitasState({
    this.citas = const [],
    this.citasHoy = const [],
    this.estadisticas = const {},
    this.isLoading = false,
    this.isLoadingEstadisticas = false,
    this.error,
    this.successMessage,
    this.fechaSeleccionada,
    this.citasDelDia = const [],
  });

  CitasState copyWith({
    List<Cita>? citas,
    List<Cita>? citasHoy,
    Map<String, dynamic>? estadisticas,
    bool? isLoading,
    bool? isLoadingEstadisticas,
    String? error,
    String? successMessage,
    DateTime? fechaSeleccionada,
    List<Cita>? citasDelDia,
  }) {
    return CitasState(
      citas: citas ?? this.citas,
      citasHoy: citasHoy ?? this.citasHoy,
      estadisticas: estadisticas ?? this.estadisticas,
      isLoading: isLoading ?? this.isLoading,
      isLoadingEstadisticas: isLoadingEstadisticas ?? this.isLoadingEstadisticas,
      error: error ?? this.error,
      successMessage: successMessage,
      fechaSeleccionada: fechaSeleccionada ?? this.fechaSeleccionada,
      citasDelDia: citasDelDia ?? this.citasDelDia,
    );
  }
}

class CitasNotifier extends StateNotifier<CitasState> {
  final CitaService _service;

  CitasNotifier(this._service) : super(const CitasState());

  Future<void> loadCitas({String? psicologoId}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final citas = await _service.getCitas(psicologoId: psicologoId);
      final citasHoy = await _service.getCitasHoy(psicologoId: psicologoId);
      
      state = state.copyWith(
        citas: citas,
        citasHoy: citasHoy,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadCitasPorFecha(DateTime fecha, {String? psicologoId}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final citasDelDia = await _service.getCitasPorFecha(fecha, psicologoId: psicologoId);
      
      state = state.copyWith(
        fechaSeleccionada: fecha,
        citasDelDia: citasDelDia,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadEstadisticas({String? psicologoId}) async {
    state = state.copyWith(isLoadingEstadisticas: true);
    
    try {
      final estadisticas = await _service.getEstadisticasCitas(psicologoId: psicologoId);
      
      state = state.copyWith(
        estadisticas: estadisticas,
        isLoadingEstadisticas: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingEstadisticas: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createCita({
    required String pacienteId,
    required String psicologoId,
    required DateTime fechaHora,
    required Duration duracion,
    required TipoCita tipo,
    String? notas,
    String? motivoConsulta,
    bool esOnline = false,
    double? costo,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final nuevaCita = await _service.createCita(
        pacienteId: pacienteId,
        psicologoId: psicologoId,
        fechaHora: fechaHora,
        duracion: duracion,
        tipo: tipo,
        notas: notas,
        motivoConsulta: motivoConsulta,
        esOnline: esOnline,
        costo: costo,
      );
      
      final updatedCitas = [nuevaCita, ...state.citas];
      
      state = state.copyWith(
        citas: updatedCitas,
        isLoading: false,
        successMessage: 'Cita agendada exitosamente',
      );
      
      // Recargar datos
      await loadCitas(psicologoId: psicologoId);
      await loadEstadisticas(psicologoId: psicologoId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateCita({
    required String id,
    DateTime? fechaHora,
    Duration? duracion,
    TipoCita? tipo,
    EstadoCita? estado,
    String? notas,
    String? motivoConsulta,
    bool? esOnline,
    String? linkSesion,
    String? motivoCancelacion,
    double? costo,
    bool? pagada,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      final citaActualizada = await _service.updateCita(
        id: id,
        fechaHora: fechaHora,
        duracion: duracion,
        tipo: tipo,
        estado: estado,
        notas: notas,
        motivoConsulta: motivoConsulta,
        esOnline: esOnline,
        linkSesion: linkSesion,
        motivoCancelacion: motivoCancelacion,
        costo: costo,
        pagada: pagada,
      );
      
      final updatedCitas = state.citas.map((c) {
        return c.id == id ? citaActualizada : c;
      }).toList();
      
      state = state.copyWith(
        citas: updatedCitas,
        isLoading: false,
        successMessage: 'Cita actualizada exitosamente',
      );
      
      // Recargar datos
      await loadCitas();
      await loadEstadisticas();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> cancelarCita(String id, String motivoCancelacion) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _service.cancelarCita(id, motivoCancelacion);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Cita cancelada exitosamente',
      );
      
      // Recargar datos
      await loadCitas();
      await loadEstadisticas();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> confirmarCita(String id, {String? linkSesion}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _service.confirmarCita(id, linkSesion: linkSesion);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Cita confirmada exitosamente',
      );
      
      // Recargar datos
      await loadCitas();
      await loadEstadisticas();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> completarCita(String id, {String? notas}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _service.completarCita(id, notas: notas);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Cita completada exitosamente',
      );
      
      // Recargar datos
      await loadCitas();
      await loadEstadisticas();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteCita(String id) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _service.deleteCita(id);
      
      final updatedCitas = state.citas.where((c) => c.id != id).toList();
      
      state = state.copyWith(
        citas: updatedCitas,
        isLoading: false,
        successMessage: 'Cita eliminada exitosamente',
      );
      
      // Recargar datos
      await loadCitas();
      await loadEstadisticas();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshAll({String? psicologoId}) async {
    await Future.wait([
      loadCitas(psicologoId: psicologoId),
      loadEstadisticas(psicologoId: psicologoId),
    ]);
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  void seleccionarFecha(DateTime fecha) {
    state = state.copyWith(fechaSeleccionada: fecha);
    loadCitasPorFecha(fecha);
  }

  // Métodos utilitarios
  List<Cita> getCitasPorEstado(EstadoCita estado) {
    return state.citas.where((c) => c.estado == estado).toList();
  }

  List<Cita> getCitasDeHoy() {
    return state.citasHoy;
  }

  List<Cita> getCitasProximas() {
    final ahora = DateTime.now();
    return state.citas
        .where((c) => c.fechaHora.isAfter(ahora) && c.estado == EstadoCita.agendada)
        .toList();
  }

  int getTotalCitas() {
    return state.citas.length;
  }

  int getCitasHoyCount() {
    return state.citasHoy.length;
  }

  double getTasaAsistencia() {
    return (state.estadisticas['tasa_asistencia'] ?? 0.0).toDouble();
  }

  double getTasaCancelacion() {
    return (state.estadisticas['tasa_cancelacion'] ?? 0.0).toDouble();
  }

  double getTotalIngresos() {
    return (state.estadisticas['ingresos'] ?? 0.0).toDouble();
  }
}

final citasProvider = StateNotifierProvider<CitasNotifier, CitasState>((ref) {
  final service = ref.watch(citaServiceProvider);
  return CitasNotifier(service);
});

final citaByIdProvider = FutureProvider.family<Cita, String>((ref, id) async {
  final service = ref.watch(citaServiceProvider);
  return await service.getCitaById(id);
});

// Providers para datos específicos
final citasHoyProvider = Provider<List<Cita>>((ref) {
  return ref.watch(citasProvider.notifier).getCitasDeHoy();
});

final citasProximasProvider = Provider<List<Cita>>((ref) {
  return ref.watch(citasProvider.notifier).getCitasProximas();
});

final totalCitasProvider = Provider<int>((ref) {
  return ref.watch(citasProvider.notifier).getTotalCitas();
});

final tasaAsistenciaProvider = Provider<double>((ref) {
  return ref.watch(citasProvider.notifier).getTasaAsistencia();
});

final tasaCancelacionProvider = Provider<double>((ref) {
  return ref.watch(citasProvider.notifier).getTasaCancelacion();
});

final ingresosProvider = Provider<double>((ref) {
  return ref.watch(citasProvider.notifier).getTotalIngresos();
});
