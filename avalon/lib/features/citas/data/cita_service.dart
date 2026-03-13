import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/cita.dart';

class CitaService {
  final SupabaseClient _supabase;

  CitaService(this._supabase);

  // Obtener todas las citas
  Future<List<Cita>> getCitas({String? psicologoId}) async {
    try {
      if (psicologoId != null) {
        final response = await _supabase
            .from('citas')
            .select('*')
            .eq('psicologo_id', psicologoId)
            .order('fecha_hora', ascending: true);
        
        return response.map((json) => Cita.fromJson(json)).toList();
      } else {
        final response = await _supabase
            .from('citas')
            .select('*')
            .order('fecha_hora', ascending: true);
        
        return response.map((json) => Cita.fromJson(json)).toList();
      }
    } catch (e) {
      throw Exception('Error al cargar citas: $e');
    }
  }

  // Obtener citas por fecha específica
  Future<List<Cita>> getCitasPorFecha(DateTime fecha, {String? psicologoId}) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    try {
      if (psicologoId != null) {
        final response = await _supabase
            .from('citas')
            .select('*')
            .eq('psicologo_id', psicologoId)
            .gte('fecha_hora', inicioDia.toIso8601String())
            .lt('fecha_hora', finDia.toIso8601String())
            .order('fecha_hora', ascending: true);
        
        return response.map((json) => Cita.fromJson(json)).toList();
      } else {
        final response = await _supabase
            .from('citas')
            .select('*')
            .gte('fecha_hora', inicioDia.toIso8601String())
            .lt('fecha_hora', finDia.toIso8601String())
            .order('fecha_hora', ascending: true);
        
        return response.map((json) => Cita.fromJson(json)).toList();
      }
    } catch (e) {
      throw Exception('Error al cargar citas del día: $e');
    }
  }

  // Obtener citas de hoy
  Future<List<Cita>> getCitasHoy({String? psicologoId}) async {
    final hoy = DateTime.now();
    return getCitasPorFecha(hoy, psicologoId: psicologoId);
  }

  // Obtener cita por ID
  Future<Cita> getCitaById(String id) async {
    try {
      final response = await _supabase
          .from('citas')
          .select('*')
          .eq('id', id)
          .single();

      return Cita.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar cita: $e');
    }
  }

  // Crear nueva cita
  Future<Cita> createCita({
    required String pacienteId,
    required String psicologoId,
    required DateTime fechaHora,
    required Duration duracion,
    required TipoCita tipo,
    String? notas,
    String? motivoConsulta,
    bool esOnline = false,
    double? costo,
    String? licenciaId,
    String? deviceId,
    String? resumenSesion,
  }) async {
    try {
      final citaData = {
        'paciente_id': pacienteId,
        'psicologo_id': psicologoId,
        'fecha_hora': fechaHora.toIso8601String(),
        'duracion_minutos': duracion.inMinutes,
        'tipo': tipo.value,
        'estado': EstadoCita.agendada.value,
        'notas': notas,
        'motivo_consulta': motivoConsulta,
        'es_online': esOnline,
        'fecha_creacion': DateTime.now().toIso8601String(),
        'costo': costo,
        'pagada': false,
        'licencia_id': licenciaId,
        'device_id': deviceId,
        'resumen_sesion': resumenSesion,
      };

      final response = await _supabase
          .from('citas')
          .insert(citaData)
          .select()
          .single();

      return Cita.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear cita: $e');
    }
  }

  // Actualizar cita
  Future<Cita> updateCita({
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
    String? licenciaId,
    String? deviceId,
    String? resumenSesion,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (fechaHora != null) {
        updateData['fecha_hora'] = fechaHora.toIso8601String();
      }
      if (duracion != null) {
        updateData['duracion_minutos'] = duracion.inMinutes;
      }
      if (tipo != null) {
        updateData['tipo'] = tipo.value;
      }
      if (estado != null) {
        updateData['estado'] = estado.value;
        
        if (estado == EstadoCita.confirmada) {
          updateData['fecha_confirmacion'] = DateTime.now().toIso8601String();
        } else if (estado == EstadoCita.cancelada) {
          updateData['fecha_cancelacion'] = DateTime.now().toIso8601String();
          updateData['motivo_cancelacion'] = motivoCancelacion;
        }
      }
      if (notas != null) {
        updateData['notas'] = notas;
      }
      if (motivoConsulta != null) {
        updateData['motivo_consulta'] = motivoConsulta;
      }
      if (esOnline != null) {
        updateData['es_online'] = esOnline;
      }
      if (linkSesion != null) {
        updateData['link_sesion'] = linkSesion;
      }
      if (costo != null) {
        updateData['costo'] = costo;
      }
      if (pagada != null) {
        updateData['pagada'] = pagada;
      }
      if (licenciaId != null) {
        updateData['licencia_id'] = licenciaId;
      }
      if (deviceId != null) {
        updateData['device_id'] = deviceId;
      }
      if (resumenSesion != null) {
        updateData['resumen_sesion'] = resumenSesion;
      }

      final response = await _supabase
          .from('citas')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Cita.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar cita: $e');
    }
  }

  // Cancelar cita
  Future<Cita> cancelarCita(String id, String motivoCancelacion) async {
    return updateCita(
      id: id,
      estado: EstadoCita.cancelada,
      motivoCancelacion: motivoCancelacion,
    );
  }

  // Confirmar cita
  Future<Cita> confirmarCita(String id, {String? linkSesion}) async {
    return updateCita(
      id: id,
      estado: EstadoCita.confirmada,
      linkSesion: linkSesion,
    );
  }

  // Completar cita
  Future<Cita> completarCita(String id, {String? notas}) async {
    return updateCita(
      id: id,
      estado: EstadoCita.completada,
      notas: notas,
    );
  }

  // Eliminar cita
  Future<void> deleteCita(String id) async {
    try {
      await _supabase
          .from('citas')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar cita: $e');
    }
  }

  // Obtener estadísticas básicas
  Future<Map<String, dynamic>> getEstadisticasCitas({String? psicologoId}) async {
    try {
      final citas = await getCitas(psicologoId: psicologoId);

      final total = citas.length;
      final agendadas = citas.where((c) => c.estado == EstadoCita.agendada).length;
      final confirmadas = citas.where((c) => c.estado == EstadoCita.confirmada).length;
      final completadas = citas.where((c) => c.estado == EstadoCita.completada).length;
      final canceladas = citas.where((c) => c.estado == EstadoCita.cancelada).length;

      final ingresos = citas
          .where((c) => c.pagada && c.costo != null)
          .fold<double>(0, (sum, c) => sum + c.costo!);

      return {
        'total': total,
        'agendadas': agendadas,
        'confirmadas': confirmadas,
        'completadas': completadas,
        'canceladas': canceladas,
        'tasa_asistencia': total > 0 ? ((completadas) / total * 100).roundToDouble() : 0.0,
        'tasa_cancelacion': total > 0 ? (canceladas / total * 100).roundToDouble() : 0.0,
        'ingresos': ingresos,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Enhanced methods for better functionality
  
  // Obtener citas de la semana
  Future<List<Cita>> getCitasSemana({String? psicologoId}) async {
    final ahora = DateTime.now();
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
    final finSemana = inicioSemana.add(const Duration(days: 7));

    try {
      final response = await _supabase
          .from('citas')
          .select('*')
          .gte('fecha_hora', inicioSemana.toIso8601String())
          .lt('fecha_hora', finSemana.toIso8601String())
          .order('fecha_hora', ascending: true);

      return response.map((json) => Cita.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar citas de la semana: $e');
    }
  }

  // Obtener citas por rango de fechas
  Future<List<Cita>> getCitasPorRango(
    DateTime inicio,
    DateTime fin, {
    String? psicologoId,
  }) async {
    try {
      final response = await _supabase
          .from('citas')
          .select('*')
          .gte('fecha_hora', inicio.toIso8601String())
          .lte('fecha_hora', fin.toIso8601String())
          .order('fecha_hora', ascending: true);

      return response.map((json) => Cita.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar citas por rango: $e');
    }
  }

  // Obtener citas por paciente
  Future<List<Cita>> getCitasPorPaciente(
    String pacienteId, {
    String? psicologoId,
  }) async {
    try {
      final response = await _supabase
          .from('citas')
          .select('*')
          .eq('paciente_id', pacienteId)
          .order('fecha_hora', ascending: false);

      return response.map((json) => Cita.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar citas del paciente: $e');
    }
  }

  // Verificar disponibilidad de horario
  Future<bool> isHorarioDisponible({
    required String psicologoId,
    required DateTime fechaHora,
    required Duration duracion,
    String? excludeCitaId,
  }) async {
    try {
      final finCita = fechaHora.add(duracion);
      
      final response = await _supabase
          .from('citas')
          .select('*')
          .eq('psicologo_id', psicologoId)
          .or('fecha_hora.lt.${finCita.toIso8601String()},fecha_hora.gte.${fechaHora.toIso8601String()}');

      if (excludeCitaId != null) {
        final filteredResponse = response.where((cita) => cita['id'] != excludeCitaId).toList();
        return filteredResponse.isEmpty;
      }

      return response.isEmpty;
    } catch (e) {
      throw Exception('Error al verificar disponibilidad: $e');
    }
  }

  // Obtener próximas citas
  Future<List<Cita>> getProximasCitas({
    String? psicologoId,
    int limite = 10,
  }) async {
    try {
      final response = await _supabase
          .from('citas')
          .select('*')
          .gte('fecha_hora', DateTime.now().toIso8601String())
          .order('fecha_hora', ascending: true)
          .limit(limite);

      return response.map((json) => Cita.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar próximas citas: $e');
    }
  }

  // Obtener citas pendientes de pago
  Future<List<Cita>> getCitasPendientesPago({String? psicologoId}) async {
    try {
      final response = await _supabase
          .from('citas')
          .select('*')
          .eq('pagada', false)
          .not('costo', 'is', null)
          .order('fecha_hora', ascending: false);

      return response.map((json) => Cita.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar citas pendientes de pago: $e');
    }
  }
}
