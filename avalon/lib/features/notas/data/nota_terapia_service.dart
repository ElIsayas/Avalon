import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/nota_terapia.dart';

class NotaTerapiaService {
  final SupabaseClient _supabase;

  NotaTerapiaService(this._supabase);

  // Obtener todas las notas de terapia
  Future<List<NotaTerapia>> getNotasTerapia() async {
    try {
      final response = await _supabase
          .from('notas_terapia')
          .select('*')
          .order('fecha', ascending: false);

      return response.map((json) => NotaTerapia.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar notas de terapia: $e');
    }
  }

  // Obtener notas por paciente
  Future<List<NotaTerapia>> getNotasPorPaciente(String pacienteId) async {
    try {
      final response = await _supabase
          .from('notas_terapia')
          .select('*')
          .eq('paciente_id', pacienteId)
          .order('fecha', ascending: false);

      return response.map((json) => NotaTerapia.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar notas del paciente: $e');
    }
  }

  // Obtener nota por ID
  Future<NotaTerapia> getNotaById(String id) async {
    try {
      final response = await _supabase
          .from('notas_terapia')
          .select('*')
          .eq('id', id)
          .single();

      return NotaTerapia.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar nota de terapia: $e');
    }
  }

  // Crear nueva nota de terapia
  Future<NotaTerapia> createNotaTerapia({
    required String pacienteId,
    required String psicologoId,
    required DateTime fecha,
    required String notas,
    String? citaId,
    String? objetivos,
    String? progreso,
  }) async {
    try {
      final notaData = {
        'paciente_id': pacienteId,
        'psicologo_id': psicologoId,
        'fecha': fecha.toIso8601String(),
        'notas': notas,
        'cita_id': citaId,
        'objetivos': objetivos,
        'progreso': progreso,
      };

      final response = await _supabase
          .from('notas_terapia')
          .insert(notaData)
          .select()
          .single();

      return NotaTerapia.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear nota de terapia: $e');
    }
  }

  // Actualizar nota de terapia
  Future<NotaTerapia> updateNotaTerapia({
    required String id,
    DateTime? fecha,
    String? notas,
    String? objetivos,
    String? progreso,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (fecha != null) {
        updateData['fecha'] = fecha.toIso8601String();
      }
      if (notas != null) updateData['notas'] = notas;
      if (objetivos != null) updateData['objetivos'] = objetivos;
      if (progreso != null) updateData['progreso'] = progreso;

      final response = await _supabase
          .from('notas_terapia')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return NotaTerapia.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar nota de terapia: $e');
    }
  }

  // Eliminar nota de terapia
  Future<void> deleteNotaTerapia(String id) async {
    try {
      await _supabase
          .from('notas_terapia')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar nota de terapia: $e');
    }
  }

  // Obtener notas por rango de fechas
  Future<List<NotaTerapia>> getNotasPorRango(
    DateTime inicio,
    DateTime fin,
  ) async {
    try {
      final response = await _supabase
          .from('notas_terapia')
          .select('*')
          .gte('fecha', inicio.toIso8601String())
          .lte('fecha', fin.toIso8601String())
          .order('fecha', ascending: false);

      return response.map((json) => NotaTerapia.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar notas por rango: $e');
    }
  }

  // Obtener notas recientes
  Future<List<NotaTerapia>> getNotasRecientes({int dias = 30}) async {
    try {
      final fechaLimite = DateTime.now().subtract(Duration(days: dias));

      final response = await _supabase
          .from('notas_terapia')
          .select('*')
          .gte('fecha', fechaLimite.toIso8601String())
          .order('fecha', ascending: false);

      return response.map((json) => NotaTerapia.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar notas recientes: $e');
    }
  }

  // Obtener notas por cita
  Future<List<NotaTerapia>> getNotasPorCita(String citaId) async {
    try {
      final response = await _supabase
          .from('notas_terapia')
          .select('*')
          .eq('cita_id', citaId)
          .order('fecha', ascending: false);

      return response.map((json) => NotaTerapia.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar notas por cita: $e');
    }
  }

  // Buscar notas de terapia
  Future<List<NotaTerapia>> buscarNotasTerapia(String query) async {
    try {
      final response = await _supabase
          .from('notas_terapia')
          .select('*')
          .or('notas.ilike.%$query%,objetivos.ilike.%$query%,progreso.ilike.%$query%')
          .order('fecha', ascending: false);

      return response.map((json) => NotaTerapia.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar notas de terapia: $e');
    }
  }

  // Obtener estadísticas de notas
  Future<Map<String, dynamic>> getEstadisticasNotas() async {
    try {
      final notas = await getNotasTerapia();

      final total = notas.length;
      final conObjetivos = notas.where((n) => n.objetivos != null && n.objetivos!.isNotEmpty).length;
      final conProgreso = notas.where((n) => n.progreso != null && n.progreso!.isNotEmpty).length;

      final esteMes = DateTime.now().month;
      final notasEsteMes = notas
          .where((n) => n.fecha.month == esteMes)
          .length;

      return {
        'total': total,
        'con_objetivos': conObjetivos,
        'con_progreso': conProgreso,
        'este_mes': notasEsteMes,
        'porcentaje_con_objetivos': total > 0 ? (conObjetivos / total * 100).roundToDouble() : 0.0,
        'porcentaje_con_progreso': total > 0 ? (conProgreso / total * 100).roundToDouble() : 0.0,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Obtener resumen de progreso del paciente
  Future<Map<String, dynamic>> getResumenProgresoPaciente(String pacienteId) async {
    try {
      final notas = await getNotasPorPaciente(pacienteId);
      
      if (notas.isEmpty) {
        return {
          'total_sesiones': 0,
          'primer_sesion': null,
          'ultima_sesion': null,
          'objetivos_trabajados': <String>[],
          'progresos_registrados': <String>[],
        };
      }

      final primerSesion = notas.last.fecha;
      final ultimaSesion = notas.first.fecha;
      
      final objetivosTrabajados = notas
          .where((n) => n.objetivos != null && n.objetivos!.isNotEmpty)
          .map((n) => n.objetivos!)
          .toList();
      
      final progresosRegistrados = notas
          .where((n) => n.progreso != null && n.progreso!.isNotEmpty)
          .map((n) => n.progreso!)
          .toList();

      return {
        'total_sesiones': notas.length,
        'primer_sesion': primerSesion,
        'ultima_sesion': ultimaSesion,
        'objetivos_trabajados': objetivosTrabajados,
        'progresos_registrados': progresosRegistrados,
      };
    } catch (e) {
      throw Exception('Error al obtener resumen de progreso: $e');
    }
  }
}
