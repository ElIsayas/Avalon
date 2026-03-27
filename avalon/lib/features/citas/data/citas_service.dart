import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/cita.dart';
import '../../../../core/utils/logger.dart';

class CitasService {
  final SupabaseClient _client;
  final String _token;

  CitasService(this._client, this._token);

  Future<List<Cita>> getCitas({
    DateTime? desde,
    DateTime? hasta,
    String? psicologoId,
    String? estado,
  }) async {
    AppLogger.database('Obteniendo citas con filtros');

    try {
      final params = <String, dynamic>{
        'p_token': _token,
      };

      if (desde != null) params['p_desde'] = desde.toIso8601String();
      if (hasta != null) params['p_hasta'] = hasta.toIso8601String();
      if (psicologoId != null) params['p_psicologo_id'] = psicologoId;
      if (estado != null) params['p_estado'] = estado;

      final res = await _client.rpc('get_citas', params: params);
      final lista = (res as List? ?? [])
          .map((e) => Cita.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.database('Se obtuvieron ${lista.length} citas');
      return lista;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo citas: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Cita>> getCitasHoy() async {
    AppLogger.database('Obteniendo citas de hoy');

    try {
      final res =
          await _client.rpc('get_citas_hoy', params: {'p_token': _token});
      final lista = (res as List? ?? [])
          .map((e) => Cita.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.database('Se obtuvieron ${lista.length} citas de hoy');
      return lista;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo citas de hoy: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Cita>> getCitasSemana() async {
    AppLogger.database('Obteniendo citas de la semana');

    try {
      final res =
          await _client.rpc('get_citas_semana', params: {'p_token': _token});
      final lista = (res as List? ?? [])
          .map((e) => Cita.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.database('Se obtuvieron ${lista.length} citas de la semana');
      return lista;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo citas de la semana: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Cita> crearCita({
    required String pacienteId,
    required String psicologoId,
    required DateTime fechaHora,
    required int duracionMinutos,
    required String tipo,
    required String estado,
    required String modalidad,
    String? motivoConsulta,
    String? notas,
    bool notificarSms = false,
    bool notificarEmail = false,
    bool recordatorio24h = false,
    bool recordatorio1h = false,
  }) async {
    AppLogger.database('Creando cita para paciente $pacienteId');

    try {
      final res = await _client.rpc('crear_cita', params: {
        'p_token': _token,
        'p_paciente_id': pacienteId,
        'p_psicologo_id': psicologoId,
        'p_fecha_hora': fechaHora.toIso8601String(),
        'p_duracion_minutos': duracionMinutos,
        'p_tipo': tipo,
        'p_estado': estado,
        'p_modalidad': modalidad,
        'p_motivo_consulta': motivoConsulta,
        'p_notas': notas,
        'p_notificar_sms': notificarSms,
        'p_notificar_email': notificarEmail,
        'p_recordatorio_24h': recordatorio24h,
        'p_recordatorio_1h': recordatorio1h,
      });

      final data = res as Map<String, dynamic>;

      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      final cita = Cita.fromJson(data);
      AppLogger.database('Cita creada exitosamente: ${cita.id}');
      return cita;
    } catch (e, stackTrace) {
      AppLogger.database('Error creando cita: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarCita({
    required String citaId,
    DateTime? fechaHora,
    int? duracionMinutos,
    String? estado,
    String? modalidad,
    bool? esOnline,
    String? notas,
    String? motivoCancelacion,
  }) async {
    AppLogger.database('Actualizando cita $citaId');

    try {
      final params = <String, dynamic>{
        'p_token': _token,
        'p_cita_id': citaId,
      };

      if (fechaHora != null) {
        params['p_fecha_hora'] = fechaHora.toIso8601String();
      }
      if (duracionMinutos != null) {
        params['p_duracion_minutos'] = duracionMinutos;
      }
      if (estado != null) params['p_estado'] = estado;
      if (modalidad != null) params['p_modalidad'] = modalidad;
      if (esOnline != null && modalidad == null) {
        params['p_modalidad'] = esOnline ? 'online' : 'presencial';
      }
      if (notas != null) params['p_notas'] = notas;
      if (motivoCancelacion != null) {
        params['p_motivo_cancelacion'] = motivoCancelacion;
      }

      final res = await _client.rpc('actualizar_cita', params: params);
      final data = Map<String, dynamic>.from(res as Map);

      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      AppLogger.database('Cita actualizada exitosamente');
      return data;
    } catch (e, stackTrace) {
      AppLogger.database('Error actualizando cita: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Cita>> getProximasCitasPsicologo({int limite = 10}) async {
    AppLogger.database('Obteniendo próximas citas del psicólogo');

    try {
      final res = await _client.rpc('get_proximas_citas_psicologo', params: {
        'p_token': _token,
        'p_limite': limite,
      });
      final lista = (res as List? ?? [])
          .map((e) => Cita.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.database('Se obtuvieron ${lista.length} próximas citas');
      return lista;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo próximas citas: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<DisponibilidadPsicologo>> getDisponibilidadPsicologos() async {
    AppLogger.database('Obteniendo disponibilidad de psicólogos');

    try {
      final res = await _client
          .rpc('get_disponibilidad_psicologos', params: {'p_token': _token});
      final lista = (res as List? ?? [])
          .map((e) =>
              DisponibilidadPsicologo.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.database(
          'Se obtuvo disponibilidad de ${lista.length} psicólogos');
      return lista;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo disponibilidad: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAuditoriaCita(String citaId) async {
    AppLogger.database('Obteniendo auditoría de cita $citaId');

    try {
      final res = await _client.rpc('get_auditoria_cita', params: {
        'p_token': _token,
        'p_cita_id': citaId,
      });
      final lista = (res as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      AppLogger.database(
          'Se obtuvieron ${lista.length} registros de auditoría');
      return lista;
    } catch (e, stackTrace) {
      AppLogger.database('Error obteniendo auditoría: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
