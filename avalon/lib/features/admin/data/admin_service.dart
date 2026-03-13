import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/psicologo.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';

class AdminService {
  final SupabaseClient _client;
  static const int maxPsicologos = 5;

  AdminService(this._client);

  // Obtener todos los psicólogos de la clínica Yuse
  Future<List<Psicologo>> getPsicologosByClinica(String clinicaId) async {
    try {
      Logger.debug("Obteniendo psicólogos para clínica: $clinicaId", 'AdminService');
      
      final response = await _client
          .from(AppConstants.tableUsuarios)
          .select('*')
          .eq('clinica_id', clinicaId)
          .eq('rol', 'psicologo')
          .eq('activo', true)
          .order('fecha_registro', ascending: false);

      Logger.debug("Psicólogos obtenidos: ${response.length}", 'AdminService');
      
      return (response as List)
          .map((psicologo) => Psicologo.fromMap(psicologo as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Logger.error("Error al obtener psicólogos: $e", 'AdminService');
      throw Exception('Error al obtener psicólogos: $e');
    }
  }

  // Obtener cantidad de psicólogos existentes
  Future<int> getCantidadPsicologos(String clinicaId) async {
    try {
      Logger.debug("Contando psicólogos para clínica: $clinicaId", 'AdminService');
      
      final response = await _client
          .from(AppConstants.tableUsuarios)
          .select('id')
          .eq('clinica_id', clinicaId)
          .eq('rol', 'psicologo')
          .eq('activo', true);

      Logger.debug("Cantidad de psicólogos: ${response.length}", 'AdminService');
      
      return (response as List).length;
    } catch (e) {
      Logger.error("Error al contar psicólogos: $e", 'AdminService');
      throw Exception('Error al contar psicólogos: $e');
    }
  }

  // Verificar si se pueden crear más psicólogos
  Future<bool> puedeCrearPsicologo(String clinicaId) async {
    try {
      final cantidad = await getCantidadPsicologos(clinicaId);
      Logger.debug("Puede crear psicólogo? ${cantidad < maxPsicologos} (actual: $cantidad, máximo: $maxPsicologos)", 'AdminService');
      return cantidad < maxPsicologos;
    } catch (e) {
      Logger.error("Error al verificar si puede crear psicólogo: $e", 'AdminService');
      return false;
    }
  }

  // Obtener espacios disponibles
  Future<int> getEspaciosDisponibles(String clinicaId) async {
    try {
      final cantidad = await getCantidadPsicologos(clinicaId);
      final disponibles = maxPsicologos - cantidad;
      Logger.debug("Espacios disponibles: $disponibles", 'AdminService');
      return disponibles;
    } catch (e) {
      Logger.error("Error al obtener espacios disponibles: $e", 'AdminService');
      return 0;
    }
  }

  // Crear un nuevo psicólogo - VERSIÓN DEBUG
  Future<Psicologo> crearPsicologo({
    required String nombre,
    required String email,
    required String password,
    required String clinicaId,
  }) async {
    AuthResponse? authResponse;
    
    try {
      Logger.debug("===== INICIANDO CREACIÓN DE PSICÓLOGO =====", 'AdminService');
      Logger.debug("Nombre: $nombre", 'AdminService');
      Logger.debug("Email: $email", 'AdminService');
      Logger.debug("Clinica ID: $clinicaId", 'AdminService');
      Logger.debug("Contraseña: [${password.length} caracteres]", 'AdminService');

      // 1. Verificar límite de psicólogos
      Logger.debug("Verificando límite de psicólogos...", 'AdminService');
      if (!await puedeCrearPsicologo(clinicaId)) {
        throw Exception('Se ha alcanzado el límite de $maxPsicologos psicólogos');
      }

      // 2. Verificar email duplicado en la tabla usuarios
      Logger.debug("Verificando email duplicado en tabla usuarios...", 'AdminService');
      final emailExists = await _client
          .from(AppConstants.tableUsuarios)
          .select('id')
          .eq('email', email)
          .eq('activo', true);
      
      if (emailExists.isNotEmpty) {
        throw Exception('El correo electrónico ya está registrado en la tabla usuarios');
      }

      // 3. Crear usuario en Supabase Auth
      Logger.debug("Creando usuario en Supabase Auth...", 'AdminService');
      Logger.debug("URL Supabase: ${AppConstants.supabaseUrl}", 'AdminService');
      
      authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      Logger.debug("===== RESPUESTA DE SUPABASE AUTH =====", 'AdminService');
      Logger.debug("Response.user: ${authResponse.user != null ? 'NO NULL' : 'NULL'}", 'AdminService');
      Logger.debug("Response.session: ${authResponse.session != null ? 'NO NULL' : 'NULL'}", 'AdminService');
      
      if (authResponse.user != null) {
        Logger.debug("User ID: ${authResponse.user!.id}", 'AdminService');
        Logger.debug("User Email: ${authResponse.user!.email}", 'AdminService');
        Logger.debug("User Created At: ${authResponse.user!.createdAt}", 'AdminService');
        Logger.debug("User Email Confirmed: ${authResponse.user!.emailConfirmedAt}", 'AdminService');
      } else {
        Logger.error("ERROR: authResponse.user es NULL", 'AdminService');
        throw Exception('Error al crear usuario en el sistema de autenticación: usuario nulo');
      }

      // 4. Verificar que el usuario realmente existe en Auth
      Logger.debug("Verificando que el usuario existe en Auth...", 'AdminService');
      try {
        final verification = await _client.auth.admin.getUserById(authResponse.user!.id);
        Logger.debug("Verificación admin.getUserById: ${verification.user != null ? 'USUARIO EXISTE' : 'USUARIO NO EXISTE'}", 'AdminService');
      } catch (verifyError) {
        Logger.error("ERROR al verificar usuario en Auth: $verifyError", 'AdminService');
        Logger.warning("Posible problema: No se tienen permisos de admin o el usuario no se creó correctamente", 'AdminService');
      }

      // 5. Crear registro en la tabla usuarios
      Logger.debug("Creando registro en tabla usuarios...", 'AdminService');
      Logger.debug("auth_user_id: ${authResponse.user!.id}", 'AdminService');
      Logger.debug("clinica_id: $clinicaId", 'AdminService');
      Logger.debug("nombre: $nombre", 'AdminService');
      Logger.debug("email: $email", 'AdminService');
      Logger.debug("rol: psicologo", 'AdminService');

      final userData = await _client
          .from(AppConstants.tableUsuarios)
          .insert({
            'auth_user_id': authResponse.user!.id,
            'clinica_id': clinicaId,
            'nombre': nombre,
            'email': email,
            'rol': 'psicologo',
            'activo': true,
          })
          .select()
          .single();

      Logger.info("===== USUARIO CREADO CORRECTAMENTE EN TABLA USUARIOS =====", 'AdminService');
      Logger.debug("ID en tabla usuarios: ${userData['id']}", 'AdminService');
      Logger.debug("auth_user_id: ${userData['auth_user_id']}", 'AdminService');

      // 6. Verificación final
      Logger.debug("Realizando verificación final...", 'AdminService');
      
      // Verificar en Auth
      try {
        final authCheck = await _client.auth.admin.getUserById(authResponse.user!.id);
        Logger.debug("Verificación final Auth: ${authCheck.user != null ? 'OK' : 'FALLO'}", 'AdminService');
      } catch (e) {
        Logger.error("ERROR en verificación final Auth: $e", 'AdminService');
      }
      
      // Verificar en tabla usuarios
      try {
        final dbCheck = await _client
            .from(AppConstants.tableUsuarios)
            .select('*')
            .eq('auth_user_id', authResponse.user!.id)
            .single();
        Logger.debug("Verificación final BD: ${dbCheck.isNotEmpty ? 'OK' : 'FALLO'}", 'AdminService');
      } catch (e) {
        Logger.error("ERROR en verificación final BD: $e", 'AdminService');
      }

      Logger.info("===== CREACIÓN COMPLETADA CON ÉXITO =====", 'AdminService');
      
      return Psicologo.fromMap(userData);
      
    } on AuthException catch (e) {
      Logger.error("===== ERROR EN SUPABASE AUTH =====", 'AdminService');
      Logger.error("AuthException code: ${e.code}", 'AdminService');
      Logger.error("AuthException message: ${e.message}", 'AdminService');
      Logger.error("AuthException statusCode: ${e.statusCode}", 'AdminService');
      
      if (e.message.contains('already registered')) {
        throw Exception('El correo electrónico ya está registrado en Auth');
      } else if (e.message.contains('Invalid email')) {
        throw Exception('El correo electrónico no es válido');
      } else if (e.message.contains('Password should be at least 6 characters')) {
        throw Exception('La contraseña debe tener al menos 6 caracteres');
      } else {
        throw Exception('Error de autenticación: ${e.message}');
      }
    } on PostgrestException catch (e) {
      Logger.error("===== ERROR EN BASE DE DATOS =====", 'AdminService');
      Logger.error("PostgrestException code: ${e.code}", 'AdminService');
      Logger.error("PostgrestException message: ${e.message}", 'AdminService');
      Logger.error("PostgrestException details: ${e.details}", 'AdminService');
      Logger.error("PostgrestException hint: ${e.hint}", 'AdminService');
      
      if (e.code == '23505') {
        throw Exception('El correo electrónico ya está registrado (violación de constraint unique)');
      } else {
        throw Exception('Error de base de datos: ${e.message}');
      }
    } catch (e) {
      Logger.error("===== ERROR GENERAL =====", 'AdminService');
      Logger.error("Error: $e", 'AdminService');
      Logger.error("Error type: ${e.runtimeType}", 'AdminService');
      
      // Si falló la inserción en la BD, eliminar el usuario de Auth si se creó
      try {
        if (authResponse?.user != null) {
          Logger.debug("Intentando eliminar usuario de Auth debido a error...", 'AdminService');
          await _client.auth.admin.deleteUser(authResponse!.user!.id);
          Logger.debug("Usuario eliminado de Auth correctamente", 'AdminService');
        }
      } catch (deleteError) {
        Logger.error("ERROR al eliminar usuario de Auth: $deleteError", 'AdminService');
      }
      
      throw Exception('Error al crear psicólogo: $e');
    }
  }

  // Eliminar un psicólogo (desactivar)
  Future<bool> eliminarPsicologo(String psicologoId) async {
    try {
      Logger.debug("Eliminando psicólogo: $psicologoId", 'AdminService');
      
      // Obtener el auth_user_id antes de desactivar
      final psicologoData = await _client
          .from(AppConstants.tableUsuarios)
          .select('auth_user_id')
          .eq('id', psicologoId)
          .single();

      Logger.debug("auth_user_id a eliminar: ${psicologoData['auth_user_id']}", 'AdminService');

      // 1. Desactivar en la tabla usuarios
      await _client
          .from(AppConstants.tableUsuarios)
          .update({'activo': false})
          .eq('id', psicologoId);

      Logger.debug("Usuario desactivado en tabla usuarios", 'AdminService');

      // 2. Eliminar usuario de Supabase Auth
      final authUserId = psicologoData['auth_user_id'] as String;
      await _client.auth.admin.deleteUser(authUserId);

      Logger.debug("Usuario eliminado de Supabase Auth", 'AdminService');

      return true;
    } on AuthException catch (e) {
      Logger.error("Error al eliminar usuario de Auth: ${e.message}", 'AdminService');
      throw Exception('Error al eliminar usuario de autenticación: ${e.message}');
    } on PostgrestException catch (e) {
      Logger.error("Error al desactivar psicólogo: ${e.message}", 'AdminService');
      throw Exception('Error al desactivar psicólogo: ${e.message}');
    } catch (e) {
      Logger.error("Error general al eliminar psicólogo: $e", 'AdminService');
      throw Exception('Error al eliminar psicólogo: $e');
    }
  }

  // Verificar si un email ya está registrado
  Future<bool> emailExists(String email) async {
    try {
      final response = await _client
          .from(AppConstants.tableUsuarios)
          .select('id')
          .eq('email', email)
          .eq('activo', true);

      return (response as List).isNotEmpty;
    } catch (e) {
      Logger.error("Error al verificar email exists: $e", 'AdminService');
      return false;
    }
  }

  // Obtener estadísticas de psicólogos
  Future<Map<String, dynamic>> getEstadisticasPsicologos(String clinicaId) async {
    try {
      final cantidad = await getCantidadPsicologos(clinicaId);
      final disponibles = await getEspaciosDisponibles(clinicaId);
      
      return {
        'cantidad_actual': cantidad,
        'limite_maximo': maxPsicologos,
        'espacios_disponibles': disponibles,
        'puede_crear_mas': disponibles > 0,
        'porcentaje_ocupado': (cantidad / maxPsicologos) * 100,
      };
    } catch (e) {
      Logger.error("Error al obtener estadísticas: $e", 'AdminService');
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Método de diagnóstico para verificar la conexión con Supabase
  Future<Map<String, dynamic>> diagnosticarConexion() async {
    final diagnostic = <String, dynamic>{};
    
    try {
      // 1. Verificar conexión con Supabase
      diagnostic['supabase_url'] = AppConstants.supabaseUrl;
      diagnostic['conexion_activa'] = true;
      
      // 2. Verificar tabla usuarios
      try {
        await _client
            .from(AppConstants.tableUsuarios)
            .select('count')
            .limit(1);
        diagnostic['tabla_usuarios_accesible'] = true;
      } catch (e) {
        diagnostic['tabla_usuarios_accesible'] = false;
        diagnostic['error_tabla_usuarios'] = e.toString();
      }
      
      // 3. Verificar permisos de admin en Auth
      try {
        final currentUser = _client.auth.currentUser;
        diagnostic['usuario_actual_auth'] = currentUser?.id;
        diagnostic['usuario_actual_email'] = currentUser?.email;
        
        // Intentar una operación de admin (si hay usuario actual)
        if (currentUser != null) {
          try {
            final adminCheck = await _client.auth.admin.getUserById(currentUser.id);
            diagnostic['permisos_admin_auth'] = adminCheck.user != null;
          } catch (e) {
            diagnostic['permisos_admin_auth'] = false;
            diagnostic['error_permisos_admin'] = e.toString();
          }
        }
      } catch (e) {
        diagnostic['error_auth_general'] = e.toString();
      }
      
    } catch (e) {
      diagnostic['error_general'] = e.toString();
    }
    
    return diagnostic;
  }
}
