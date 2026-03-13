import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/paciente.dart';

class PacienteService {
  final SupabaseClient _supabase;

  PacienteService(this._supabase);

  Future<List<Paciente>> getPacientes() async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('*')
          .order('fecha_registro', ascending: false);

      return response.map((json) => Paciente.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar pacientes: $e');
    }
  }

  Future<Paciente> getPacienteById(String id) async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('*')
          .eq('id', id)
          .single();

      return Paciente.fromJson(response);
    } catch (e) {
      throw Exception('Error al cargar paciente: $e');
    }
  }

  Future<Paciente> createPaciente({
    required String nombre,
    required String email,
    required String numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
  }) async {
    try {
      final pacienteData = {
        'nombre': nombre,
        'email': email,
        'numero_documento': numeroDocumento,
        'telefono': telefono,
        'direccion': direccion,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'historial_medico': historialMedico,
        'fecha_registro': DateTime.now().toIso8601String(),
        'activo': true,
      };

      final response = await _supabase
          .from('pacientes')
          .insert(pacienteData)
          .select()
          .single();

      return Paciente.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear paciente: $e');
    }
  }

  Future<Paciente> updatePaciente({
    required String id,
    String? nombre,
    String? email,
    String? numeroDocumento,
    String? telefono,
    String? direccion,
    DateTime? fechaNacimiento,
    String? historialMedico,
    bool? activo,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (nombre != null) updateData['nombre'] = nombre;
      if (email != null) updateData['email'] = email;
      if (numeroDocumento != null) updateData['numero_documento'] = numeroDocumento;
      if (telefono != null) updateData['telefono'] = telefono;
      if (direccion != null) updateData['direccion'] = direccion;
      if (fechaNacimiento != null) updateData['fecha_nacimiento'] = fechaNacimiento.toIso8601String();
      if (historialMedico != null) updateData['historial_medico'] = historialMedico;
      if (activo != null) updateData['activo'] = activo;

      final response = await _supabase
          .from('pacientes')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Paciente.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar paciente: $e');
    }
  }

  Future<void> deletePaciente(String id) async {
    try {
      await _supabase
          .from('pacientes')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar paciente: $e');
    }
  }

  Future<void> desactivarPaciente(String id) async {
    try {
      await _supabase
          .from('pacientes')
          .update({'activo': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al desactivar paciente: $e');
    }
  }

  Future<List<Paciente>> buscarPacientes(String query) async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('*')
          .or('nombre.ilike.%$query%,email.ilike.%$query%,telefono.ilike.%$query%')
          .order('fecha_registro', ascending: false);

      return response.map((json) => Paciente.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al buscar pacientes: $e');
    }
  }

  Future<List<Paciente>> getPacientesActivos() async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('*')
          .eq('activo', true)
          .order('fecha_registro', ascending: false);

      return response.map((json) => Paciente.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar pacientes activos: $e');
    }
  }

  Future<int> getTotalPacientes() async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('id')
          .count();

      return response.count ?? 0;
    } catch (e) {
      throw Exception('Error al obtener total de pacientes: $e');
    }
  }

  Future<int> getPacientesActivosCount() async {
    try {
      final response = await _supabase
          .from('pacientes')
          .select('id')
          .eq('activo', true)
          .count();

      return response.count ?? 0;
    } catch (e) {
      throw Exception('Error al obtener pacientes activos: $e');
    }
  }
}
