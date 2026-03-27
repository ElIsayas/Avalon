import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/nota_terapia.dart';
import '../../../../core/utils/logger.dart';

class NotasService {
  final SupabaseClient _client;
  final String _token;

  NotasService(this._client, this._token);

  Future<List<NotaTerapia>> getNotasPaciente(String pacienteId) async {
    AppLogger.database('Obteniendo notas del paciente $pacienteId');
    try {
      final res = await _client.rpc('get_notas_paciente', params: {
        'p_token': _token,
        'p_paciente_id': pacienteId,
      });
      return _normalizarLista(res).map(NotaTerapia.fromJson).toList();
    } catch (e, st) {
      AppLogger.database('Error obteniendo notas: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<NotaTerapia>> getTodasLasNotas() async {
    AppLogger.database('Obteniendo todas las notas de la organizacion');
    try {
      final res = await _client.rpc('get_notas_paciente', params: {
        'p_token': _token,
      });
      return _normalizarLista(res).map(NotaTerapia.fromJson).toList();
    } catch (e1, st1) {
      AppLogger.database(
        'RPC get_notas_paciente sin p_paciente_id fallo. Reintentando con null: $e1',
        error: e1,
        stackTrace: st1,
      );
      try {
        final res = await _client.rpc('get_notas_paciente', params: {
          'p_token': _token,
          'p_paciente_id': null,
        });
        return _normalizarLista(res).map(NotaTerapia.fromJson).toList();
      } catch (e2, st2) {
        AppLogger.database(
          'Error obteniendo todas las notas (incluyendo fallback): $e2',
          error: e2,
          stackTrace: st2,
        );
        throw Exception(
          'El backend no permite listar todas las notas sin paciente. Verifica RPC get_notas_paciente (p_paciente_id opcional).',
        );
      }
    }
  }

  Future<NotaTerapia> crear({
    required String pacienteId,
    required String contenido,
    required String tipo,
    String? citaId,
  }) async {
    AppLogger.database('Creando nota para paciente $pacienteId');
    try {
      final params = <String, dynamic>{
        'p_token': _token,
        'p_paciente_id': pacienteId,
        'p_contenido': contenido,
        'p_tipo': tipo,
      };
      if (citaId != null) {
        params['p_cita_id'] = citaId;
      }

      final res = await _client.rpc('crear_nota', params: params);
      final data = _normalizarItem(res);
      if (data == null) {
        throw Exception('Respuesta vacia del servidor');
      }
      return NotaTerapia.fromJson(data);
    } catch (e, st) {
      AppLogger.database('Error creando nota: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<NotaTerapia> actualizar({
    required String notaId,
    String? contenido,
    String? tipo,
  }) async {
    AppLogger.database('Actualizando nota $notaId');
    try {
      final params = <String, dynamic>{
        'p_token': _token,
        'p_nota_id': notaId,
      };
      if (contenido != null) {
        params['p_contenido'] = contenido;
      }
      if (tipo != null) {
        params['p_tipo'] = tipo;
      }

      final res = await _client.rpc('actualizar_nota', params: params);
      final data = _normalizarItem(res);
      if (data == null) {
        throw Exception('Respuesta vacia del servidor');
      }
      return NotaTerapia.fromJson(data);
    } catch (e, st) {
      AppLogger.database('Error actualizando nota: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> firmar(String notaId) async {
    AppLogger.database('Firmando nota $notaId');
    try {
      final res = await _client.rpc('firmar_nota', params: {
        'p_token': _token,
        'p_nota_id': notaId,
      });
      _normalizarLista(res, permitirVacia: true);
    } catch (e, st) {
      AppLogger.database('Error firmando nota: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> eliminar(String notaId) async {
    AppLogger.database('Eliminando nota $notaId');
    try {
      await _client.rpc('eliminar_nota', params: {
        'p_token': _token,
        'p_nota_id': notaId,
      });
    } catch (e, st) {
      AppLogger.database('Error eliminando nota: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  List<Map<String, dynamic>> _normalizarLista(dynamic res,
      {bool permitirVacia = false}) {
    if (res == null) {
      return [];
    }
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (res is Map) {
      final data = Map<String, dynamic>.from(res);
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }
      for (final key in const ['data', 'items', 'notas', 'result']) {
        final value = data[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      if (data.containsKey('id')) {
        return [data];
      }
      return permitirVacia ? [] : [];
    }
    throw Exception(
        'Contrato RPC no soportado para notas (${res.runtimeType})');
  }

  Map<String, dynamic>? _normalizarItem(dynamic res) {
    final lista = _normalizarLista(res);
    if (lista.isNotEmpty) {
      return lista.first;
    }
    return null;
  }
}
