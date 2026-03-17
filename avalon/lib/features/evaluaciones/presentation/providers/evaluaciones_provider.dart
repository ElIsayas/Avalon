import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/evaluacion.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';

// ── SERVICE ───────────────────────────────────────────────────────────────────
class EvaluacionesService {
  final SupabaseClient _client;
  final String _token;

  EvaluacionesService(this._client, this._token);

  Future<List<Evaluacion>> getEvaluaciones({String? pacienteId}) async {
    AppLogger.database('Obteniendo evaluaciones');
    try {
      final params = <String, dynamic>{'p_token': _token};
      if (pacienteId != null) params['p_paciente_id'] = pacienteId;

      final res = await _client.rpc('get_evaluaciones', params: params);
      return (res as List? ?? [])
          .map((j) => Evaluacion.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.database('Error obteniendo evaluaciones: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Evaluacion> crear({
    required String pacienteId,
    required String escala,
    required int puntuacionTotal,
    required Map<int, int> respuestas, // ítem_num → valor
    String? citaId,
    String? interpretacion,
    String? observaciones,
  }) async {
    AppLogger.database('Creando evaluación $escala para paciente $pacienteId');
    try {
      // Convertir respuestas a JSON string-keyed para compatibilidad JSONB
      final respuestasMap = {
        for (final e in respuestas.entries) '${e.key}': e.value
      };

      final params = <String, dynamic>{
        'p_token':           _token,
        'p_paciente_id':     pacienteId,
        'p_escala':          escala,
        'p_puntuacion':      puntuacionTotal,
        'p_respuestas':      jsonEncode(respuestasMap),
      };
      if (citaId         != null) params['p_cita_id']       = citaId;
      if (interpretacion != null) params['p_interpretacion'] = interpretacion;
      if (observaciones  != null) params['p_observaciones']  = observaciones;

      final res  = await _client.rpc('crear_evaluacion', params: params);
      final data = res is List ? (res as List).first : res;
      if (data is Map && data.containsKey('error')) {
        throw Exception(data['error']);
      }
      return Evaluacion.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e, st) {
      AppLogger.database('Error creando evaluación: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> eliminar(String id) async {
    AppLogger.database('Eliminando evaluación $id');
    try {
      await _client.rpc('eliminar_evaluacion',
          params: {'p_token': _token, 'p_evaluacion_id': id});
    } catch (e, st) {
      AppLogger.database('Error eliminando evaluación: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }
}

// ── ESTADO ────────────────────────────────────────────────────────────────────
class EvaluacionesState {
  final List<Evaluacion> evaluaciones;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const EvaluacionesState({
    this.evaluaciones   = const [],
    this.isLoading      = false,
    this.isSaving       = false,
    this.error,
    this.successMessage,
  });

  EvaluacionesState copyWith({
    List<Evaluacion>? evaluaciones,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      EvaluacionesState(
        evaluaciones:   evaluaciones   ?? this.evaluaciones,
        isLoading:      isLoading      ?? this.isLoading,
        isSaving:       isSaving       ?? this.isSaving,
        error:          clearMessages ? null : error          ?? this.error,
        successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      );
}

// ── NOTIFIER ──────────────────────────────────────────────────────────────────
class EvaluacionesNotifier extends StateNotifier<EvaluacionesState> {
  final EvaluacionesService _service;

  EvaluacionesNotifier(this._service) : super(const EvaluacionesState());

  Future<void> cargar({String? pacienteId}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final lista = await _service.getEvaluaciones(pacienteId: pacienteId);
      lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      state = state.copyWith(evaluaciones: lista, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<bool> crear({
    required String pacienteId,
    required String escala,
    required int puntuacionTotal,
    required Map<int, int> respuestas,
    String? citaId,
    String? interpretacion,
    String? observaciones,
  }) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final nueva = await _service.crear(
        pacienteId:     pacienteId,
        escala:         escala,
        puntuacionTotal: puntuacionTotal,
        respuestas:     respuestas,
        citaId:         citaId,
        interpretacion: interpretacion,
        observaciones:  observaciones,
      );
      state = state.copyWith(
        evaluaciones:   [nueva, ...state.evaluaciones],
        isSaving:       false,
        successMessage: 'Evaluación registrada correctamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      await _service.eliminar(id);
      state = state.copyWith(
        evaluaciones:   state.evaluaciones.where((e) => e.id != id).toList(),
        isSaving:       false,
        successMessage: 'Evaluación eliminada',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);
  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}

// ── PROVIDERS ─────────────────────────────────────────────────────────────────
final evaluacionesServiceProvider = Provider<EvaluacionesService>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return EvaluacionesService(Supabase.instance.client, token);
});

final evaluacionesProvider =
    StateNotifierProvider<EvaluacionesNotifier, EvaluacionesState>((ref) {
  return EvaluacionesNotifier(ref.read(evaluacionesServiceProvider));
});

// Provider con scope de paciente (para usarse desde el historial)
final evaluacionesPacienteProvider =
    StateNotifierProvider.family<EvaluacionesNotifier, EvaluacionesState, String>(
  (ref, pacienteId) {
    final notifier = EvaluacionesNotifier(ref.read(evaluacionesServiceProvider));
    notifier.cargar(pacienteId: pacienteId);
    return notifier;
  },
);
