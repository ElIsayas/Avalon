import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/nota_terapia.dart';
import '../../../../core/utils/logger.dart';

class NotasService {
  final SupabaseClient _client;
  final String _token;

  NotasService(this._client, this._token);

  // ── Obtener notas de un paciente ──────────────────────────────────────────
  Future<List<NotaTerapia>> getNotasPaciente(String pacienteId) async {
    AppLogger.database('Obteniendo notas del paciente $pacienteId');
    try {
      final res = await _client.rpc('get_notas_paciente', params: {
        'p_token': _token,
        'p_paciente_id': pacienteId,
      });
      return (res as List? ?? [])
          .map((j) => NotaTerapia.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.database('Error obteniendo notas: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Obtener TODAS las notas del psicologo/org (para tab Notas) ────────────
  // Reutilizamos get_notas_paciente sin pacienteId si el RPC lo permite,
  // o usamos get_historia_clinica para un listado general
  Future<List<NotaTerapia>> getTodasLasNotas() async {
    AppLogger.database('Obteniendo todas las notas de la organización');
    try {
      // Llamada sin paciente_id — el RPC devuelve todas las de la org
      final res = await _client.rpc('get_notas_paciente', params: {
        'p_token': _token,
      });
      return (res as List? ?? [])
          .map((j) => NotaTerapia.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.database('Error obteniendo todas las notas: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Crear nota ────────────────────────────────────────────────────────────
  Future<NotaTerapia> crear({
    required String pacienteId,
    required String contenido,
    required String tipo,
    String? citaId,
  }) async {
    AppLogger.database('Creando nota para paciente $pacienteId');
    try {
      final params = <String, dynamic>{
        'p_token':       _token,
        'p_paciente_id': pacienteId,
        'p_contenido':   contenido,
        'p_tipo':        tipo,
      };
      if (citaId != null) params['p_cita_id'] = citaId;

      final res = await _client.rpc('crear_nota', params: params);
      final data = res as Map<String, dynamic>? ?? (res as List?)?.first as Map<String, dynamic>?;
      if (data == null) throw Exception('Respuesta vacía del servidor');
      if (data.containsKey('error')) throw Exception(data['error']);
      return NotaTerapia.fromJson(data);
    } catch (e, st) {
      AppLogger.database('Error creando nota: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Actualizar nota ───────────────────────────────────────────────────────
  Future<NotaTerapia> actualizar({
    required String notaId,
    String? contenido,
    String? tipo,
  }) async {
    AppLogger.database('Actualizando nota $notaId');
    try {
      final params = <String, dynamic>{
        'p_token':   _token,
        'p_nota_id': notaId,
      };
      if (contenido != null) params['p_contenido'] = contenido;
      if (tipo != null)      params['p_tipo']      = tipo;

      final res = await _client.rpc('actualizar_nota', params: params);
      final data = res as Map<String, dynamic>? ?? (res as List?)?.first as Map<String, dynamic>?;
      if (data == null) throw Exception('Respuesta vacía del servidor');
      if (data.containsKey('error')) throw Exception(data['error']);
      return NotaTerapia.fromJson(data);
    } catch (e, st) {
      AppLogger.database('Error actualizando nota: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Firmar nota ───────────────────────────────────────────────────────────
  Future<void> firmar(String notaId) async {
    AppLogger.database('Firmando nota $notaId');
    try {
      final res = await _client.rpc('firmar_nota', params: {
        'p_token':   _token,
        'p_nota_id': notaId,
      });
      final data = res as Map<String, dynamic>?;
      if (data != null && data.containsKey('error')) throw Exception(data['error']);
    } catch (e, st) {
      AppLogger.database('Error firmando nota: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Eliminar nota ─────────────────────────────────────────────────────────
  Future<void> eliminar(String notaId) async {
    AppLogger.database('Eliminando nota $notaId');
    try {
      await _client.rpc('eliminar_nota', params: {
        'p_token':   _token,
        'p_nota_id': notaId,
      });
    } catch (e, st) {
      AppLogger.database('Error eliminando nota: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
}
