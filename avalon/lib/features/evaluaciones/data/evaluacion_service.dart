import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/evaluacion.dart';

class EvaluacionService {
  final SupabaseClient _supabase;

  EvaluacionService(this._supabase);

  // Obtener todas las evaluaciones
  Future<List<Evaluacion>> getEvaluaciones() async {
    try {
      final response = await _supabase
          .from('evaluaciones')
          .select('*')
          .order('fecha_realizacion', ascending: false);

      return response.map((json) => Evaluacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar evaluaciones: $e');
    }
  }

  // Obtener evaluaciones por paciente
  Future<List<Evaluacion>> getEvaluacionesPorPaciente(String pacienteId) async {
    try {
      final response = await _supabase
          .from('evaluaciones')
          .select('*')
          .eq('paciente_id', pacienteId)
          .order('fecha_realizacion', ascending: false);

      return response.map((json) => Evaluacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar evaluaciones del paciente: $e');
    }
  }

  // Obtener evaluación por ID
  Future<Evaluacion> getEvaluacionById(String id) async {
    try {
      final response = await _supabase
          .from('evaluaciones')
          .select('*')
          .eq('id', id)
          .single();

      return Evaluacion.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar evaluación: $e');
    }
  }

  // Crear nueva evaluación
  Future<Evaluacion> createEvaluacion({
    required String pacienteId,
    required String psicologoId,
    required String tipoTest,
    required DateTime fechaRealizacion,
    String? citaId,
    String? resultados,
    String? observaciones,
  }) async {
    try {
      final evaluacionData = {
        'paciente_id': pacienteId,
        'psicologo_id': psicologoId,
        'tipo_test': tipoTest,
        'fecha_realizacion': fechaRealizacion.toIso8601String(),
        'cita_id': citaId,
        'resultados': resultados,
        'observaciones': observaciones,
      };

      final response = await _supabase
          .from('evaluaciones')
          .insert(evaluacionData)
          .select()
          .single();

      return Evaluacion.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear evaluación: $e');
    }
  }

  // Actualizar evaluación
  Future<Evaluacion> updateEvaluacion({
    required String id,
    String? tipoTest,
    DateTime? fechaRealizacion,
    String? citaId,
    String? resultados,
    String? observaciones,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (tipoTest != null) updateData['tipo_test'] = tipoTest;
      if (fechaRealizacion != null) {
        updateData['fecha_realizacion'] = fechaRealizacion.toIso8601String();
      }
      if (citaId != null) updateData['cita_id'] = citaId;
      if (resultados != null) updateData['resultados'] = resultados;
      if (observaciones != null) updateData['observaciones'] = observaciones;

      final response = await _supabase
          .from('evaluaciones')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Evaluacion.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar evaluación: $e');
    }
  }

  // Eliminar evaluación
  Future<void> deleteEvaluacion(String id) async {
    try {
      await _supabase
          .from('evaluaciones')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar evaluación: $e');
    }
  }

  // Obtener evaluaciones por rango de fechas
  Future<List<Evaluacion>> getEvaluacionesPorRango(
    DateTime inicio,
    DateTime fin,
  ) async {
    try {
      final response = await _supabase
          .from('evaluaciones')
          .select('*')
          .gte('fecha_realizacion', inicio.toIso8601String())
          .lte('fecha_realizacion', fin.toIso8601String())
          .order('fecha_realizacion', ascending: false);

      return response.map((json) => Evaluacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar evaluaciones por rango: $e');
    }
  }

  // Obtener evaluaciones recientes
  Future<List<Evaluacion>> getEvaluacionesRecientes({int dias = 30}) async {
    try {
      final fechaLimite = DateTime.now().subtract(Duration(days: dias));

      final response = await _supabase
          .from('evaluaciones')
          .select('*')
          .gte('fecha_realizacion', fechaLimite.toIso8601String())
          .order('fecha_realizacion', ascending: false);

      return response.map((json) => Evaluacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar evaluaciones recientes: $e');
    }
  }

  // Obtener estadísticas de evaluaciones
  Future<Map<String, dynamic>> getEstadisticasEvaluaciones() async {
    try {
      final evaluaciones = await getEvaluaciones();

      final total = evaluaciones.length;
      final porTipo = <String, int>{};
      
      for (final evaluacion in evaluaciones) {
        final tipo = evaluacion.tipoTest;
        porTipo[tipo] = (porTipo[tipo] ?? 0) + 1;
      }

      final esteMes = DateTime.now().month;
      final evaluacionesEsteMes = evaluaciones
          .where((e) => e.fechaRealizacion.month == esteMes)
          .length;

      final entriesList = porTipo.entries.toList();
      entriesList.sort((a, b) => b.value.compareTo(a.value));
      final topEntries = entriesList.take(5).map((e) => {'tipo': e.key, 'cantidad': e.value}).toList();

      return {
        'total': total,
        'por_tipo': porTipo,
        'este_mes': evaluacionesEsteMes,
        'tipos_mas_comunes': topEntries,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Buscar evaluaciones
  Future<List<Evaluacion>> buscarEvaluaciones(String query) async {
    try {
      final response = await _supabase
          .from('evaluaciones')
          .select('*')
          .or('tipo_test.ilike.%$query%,observaciones.ilike.%$query%')
          .order('fecha_realizacion', ascending: false);

      return response.map((json) => Evaluacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar evaluaciones: $e');
    }
  }

  // Obtener evaluaciones por tipo de test
  Future<List<Evaluacion>> getEvaluacionesPorTipo(String tipoTest) async {
    try {
      final response = await _supabase
          .from('evaluaciones')
          .select('*')
          .eq('tipo_test', tipoTest)
          .order('fecha_realizacion', ascending: false);

      return response.map((json) => Evaluacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar evaluaciones por tipo: $e');
    }
  }
}
