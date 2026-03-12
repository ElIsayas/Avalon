import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/psicologo.dart';
import '../../../../core/constants/app_constants.dart';

class AdminService {
  final SupabaseClient _client;
  static const int maxPsicologos = 5;

  AdminService(this._client);

  // Obtener todos los psicólogos de la clínica Yuse
  Future<List<Psicologo>> getPsicologosByClinica(String clinicaId) async {
    try {
      print("DEBUG: Obteniendo psicólogos para clínica: $clinicaId");
      
      final response = await _client
          .from(AppConstants.tableUsuarios)
          .select('*')
          .eq('clinica_id', clinicaId)
          .eq('rol', 'psicologo')
          .eq('activo', true)
          .order('fecha_registro', ascending: false);

      print("DEBUG: Psicólogos obtenidos: ${response.length}");
      
      return (response as List)
          .map((psicologo) => Psicologo.fromMap(psicologo as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("DEBUG: Error al obtener psicólogos: $e");
      throw Exception('Error al obtener psicólogos: $e');
    }
  }

  // Obtener cantidad de psicólogos existentes
  Future<int> getCantidadPsicologos(String clinicaId) async {
    try {
      print("DEBUG: Contando psicólogos para clínica: $clinicaId");
      
      final response = await _client
          .from(AppConstants.tableUsuarios)
          .select('id')
          .eq('clinica_id', clinicaId)
          .eq('rol', 'psicologo')
          .eq('activo', true);

      print("DEBUG: Cantidad de psicólogos: ${response.length}");
      
      return (response as List).length;
    } catch (e) {
      print("DEBUG: Error al contar psicólogos: $e");
      throw Exception('Error al contar psicólogos: $e');
    }
  }

  // Verificar si se pueden crear más psicólogos
  Future<bool> puedeCrearPsicologo(String clinicaId) async {
    try {
      final cantidad = await getCantidadPsicologos(clinicaId);
      print("DEBUG: Puede crear psicólogo? ${cantidad < maxPsicologos} (actual: $cantidad, máximo: $maxPsicologos)");
      return cantidad < maxPsicologos;
    } catch (e) {
      print("DEBUG: Error al verificar si puede crear psicólogo: $e");
      return false;
    }
  }

  // Obtener espacios disponibles
  Future<int> getEspaciosDisponibles(String clinicaId) async {
    try {
      final cantidad = await getCantidadPsicologos(clinicaId);
      final disponibles = maxPsicologos - cantidad;
      print("DEBUG: Espacios disponibles: $disponibles");
      return disponibles;
    } catch (e) {
      print("DEBUG: Error al obtener espacios disponibles: $e");
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
      print("DEBUG: ===== INICIANDO CREACIÓN DE PSICÓLOGO =====");
      print("DEBUG: Nombre: $nombre");
      print("DEBUG: Email: $email");
      print("DEBUG: Clinica ID: $clinicaId");
      print("DEBUG: Contraseña: [${password.length} caracteres]");

      // 1. Verificar límite de psicólogos
      print("DEBUG: Verificando límite de psicólogos...");
      if (!await puedeCrearPsicologo(clinicaId)) {
        throw Exception('Se ha alcanzado el límite de $maxPsicologos psicólogos');
      }

      // 2. Verificar email duplicado en la tabla usuarios
      print("DEBUG: Verificando email duplicado en tabla usuarios...");
      final emailExists = await _client
          .from(AppConstants.tableUsuarios)
          .select('id')
          .eq('email', email)
          .eq('activo', true);
      
      if (emailExists.isNotEmpty) {
        throw Exception('El correo electrónico ya está registrado en la tabla usuarios');
      }

      // 3. Crear usuario en Supabase Auth
      print("DEBUG: Creando usuario en Supabase Auth...");
      print("DEBUG: URL Supabase: ${AppConstants.supabaseUrl}");
      
      authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      print("DEBUG: ===== RESPUESTA DE SUPABASE AUTH =====");
      print("DEBUG: Response.user: ${authResponse.user != null ? 'NO NULL' : 'NULL'}");
      print("DEBUG: Response.session: ${authResponse.session != null ? 'NO NULL' : 'NULL'}");
      
      if (authResponse.user != null) {
        print("DEBUG: User ID: ${authResponse.user!.id}");
        print("DEBUG: User Email: ${authResponse.user!.email}");
        print("DEBUG: User Created At: ${authResponse.user!.createdAt}");
        print("DEBUG: User Email Confirmed: ${authResponse.user!.emailConfirmedAt}");
      } else {
        print("DEBUG: ERROR: authResponse.user es NULL");
        throw Exception('Error al crear usuario en el sistema de autenticación: usuario nulo');
      }

      // 4. Verificar que el usuario realmente existe en Auth
      print("DEBUG: Verificando que el usuario existe en Auth...");
      try {
        final verification = await _client.auth.admin.getUserById(authResponse.user!.id);
        print("DEBUG: Verificación admin.getUserById: ${verification.user != null ? 'USUARIO EXISTE' : 'USUARIO NO EXISTE'}");
      } catch (verifyError) {
        print("DEBUG: ERROR al verificar usuario en Auth: $verifyError");
        print("DEBUG: Posible problema: No se tienen permisos de admin o el usuario no se creó correctamente");
      }

      // 5. Crear registro en la tabla usuarios
      print("DEBUG: Creando registro en tabla usuarios...");
      print("DEBUG: auth_user_id: ${authResponse.user!.id}");
      print("DEBUG: clinica_id: $clinicaId");
      print("DEBUG: nombre: $nombre");
      print("DEBUG: email: $email");
      print("DEBUG: rol: psicologo");

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

      print("DEBUG: ===== USUARIO CREADO CORRECTAMENTE EN TABLA USUARIOS =====");
      print("DEBUG: ID en tabla usuarios: ${userData['id']}");
      print("DEBUG: auth_user_id: ${userData['auth_user_id']}");

      // 6. Verificación final
      print("DEBUG: Realizando verificación final...");
      
      // Verificar en Auth
      try {
        final authCheck = await _client.auth.admin.getUserById(authResponse.user!.id);
        print("DEBUG: Verificación final Auth: ${authCheck.user != null ? 'OK' : 'FALLO'}");
      } catch (e) {
        print("DEBUG: ERROR en verificación final Auth: $e");
      }
      
      // Verificar en tabla usuarios
      try {
        final dbCheck = await _client
            .from(AppConstants.tableUsuarios)
            .select('*')
            .eq('auth_user_id', authResponse.user!.id)
            .single();
        print("DEBUG: Verificación final BD: ${dbCheck.isNotEmpty ? 'OK' : 'FALLO'}");
      } catch (e) {
        print("DEBUG: ERROR en verificación final BD: $e");
      }

      print("DEBUG: ===== CREACIÓN COMPLETADA CON ÉXITO =====");
      
      return Psicologo.fromMap(userData);
      
    } on AuthException catch (e) {
      print("DEBUG: ===== ERROR EN SUPABASE AUTH =====");
      print("DEBUG: AuthException code: ${e.code}");
      print("DEBUG: AuthException message: ${e.message}");
      print("DEBUG: AuthException statusCode: ${e.statusCode}");
      
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
      print("DEBUG: ===== ERROR EN BASE DE DATOS =====");
      print("DEBUG: PostgrestException code: ${e.code}");
      print("DEBUG: PostgrestException message: ${e.message}");
      print("DEBUG: PostgrestException details: ${e.details}");
      print("DEBUG: PostgrestException hint: ${e.hint}");
      
      if (e.code == '23505') {
        throw Exception('El correo electrónico ya está registrado (violación de constraint unique)');
      } else {
        throw Exception('Error de base de datos: ${e.message}');
      }
    } catch (e) {
      print("DEBUG: ===== ERROR GENERAL =====");
      print("DEBUG: Error: $e");
      print("DEBUG: Error type: ${e.runtimeType}");
      
      // Si falló la inserción en la BD, eliminar el usuario de Auth si se creó
      try {
        if (authResponse?.user != null) {
          print("DEBUG: Intentando eliminar usuario de Auth debido a error...");
          await _client.auth.admin.deleteUser(authResponse!.user!.id);
          print("DEBUG: Usuario eliminado de Auth correctamente");
        }
      } catch (deleteError) {
        print("DEBUG: ERROR al eliminar usuario de Auth: $deleteError");
      }
      
      throw Exception('Error al crear psicólogo: $e');
    }
  }

  // Eliminar un psicólogo (desactivar)
  Future<bool> eliminarPsicologo(String psicologoId) async {
    try {
      print("DEBUG: Eliminando psicólogo: $psicologoId");
      
      // Obtener el auth_user_id antes de desactivar
      final psicologoData = await _client
          .from(AppConstants.tableUsuarios)
          .select('auth_user_id')
          .eq('id', psicologoId)
          .single();

      print("DEBUG: auth_user_id a eliminar: ${psicologoData['auth_user_id']}");

      // 1. Desactivar en la tabla usuarios
      await _client
          .from(AppConstants.tableUsuarios)
          .update({'activo': false})
          .eq('id', psicologoId);

      print("DEBUG: Usuario desactivado en tabla usuarios");

      // 2. Eliminar usuario de Supabase Auth
      final authUserId = psicologoData['auth_user_id'] as String;
      await _client.auth.admin.deleteUser(authUserId);

      print("DEBUG: Usuario eliminado de Supabase Auth");

      return true;
    } on AuthException catch (e) {
      print("DEBUG: Error al eliminar usuario de Auth: ${e.message}");
      throw Exception('Error al eliminar usuario de autenticación: ${e.message}');
    } on PostgrestException catch (e) {
      print("DEBUG: Error al desactivar psicólogo: ${e.message}");
      throw Exception('Error al desactivar psicólogo: ${e.message}');
    } catch (e) {
      print("DEBUG: Error general al eliminar psicólogo: $e");
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
      print("DEBUG: Error al verificar email exists: $e");
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
      print("DEBUG: Error al obtener estadísticas: $e");
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
