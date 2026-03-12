import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_user.dart' as auth;

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /*
  =========================
  LOGIN
  =========================
  */
  Future<auth.AuthUser> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 1. Autenticar con Supabase Auth
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('No se pudo iniciar sesión');
      }

      print("LOGIN OK: ${response.user!.id}");

      // 2. Obtener datos completos del usuario
      final userData = await _client
          .from('usuarios')
          .select()
          .eq('auth_user_id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        throw Exception('Perfil de usuario no encontrado en el sistema');
      }

      // 3. Validar estado del usuario
      if (userData['activo'] == false) {
        throw Exception('Usuario desactivado. Contacte al administrador.');
      }

      // 4. Validar que tenga clínica vinculada
      if (userData['clinica_id'] == null || userData['clinica_id'].toString().isEmpty) {
        throw Exception('El usuario no está vinculado a ninguna clínica. Contacte al administrador.');
      }

      final clinicaId = userData['clinica_id'].toString();

      // 5. Obtener y validar datos de la clínica
      final clinicaData = await _client
          .from('clinicas')
          .select('id, nombre, activa')
          .eq('id', clinicaId)
          .maybeSingle();

      if (clinicaData == null) {
        throw Exception('Clínica no encontrada. Contacte al administrador.');
      }

      if (clinicaData['activa'] == false) {
        throw Exception('Clínica desactivada. Contacte al administrador.');
      }

      print("CLÍNICA VÁLIDA: ${clinicaData['nombre']} ($clinicaId)");

      // 6. Validar suscripción activa
      await _validateSubscription(clinicaId);

      // 7. Control de sesión única
      await _handleSingleSession(userData['id'].toString());

      // 8. Registrar dispositivo
      final deviceId = await _registerDevice(userData['id'].toString());

      // 9. Crear sesión de usuario
      await _createUserSession(userData['id'].toString(), deviceId);

      // 10. Crear AuthUser con todos los datos
      final authUser = auth.AuthUser.fromMap({
        ...response.user!.toJson(),
        ...userData,
        'clinica_nombre': clinicaData['nombre'],
        'dispositivo_id': deviceId,
      });

      print("LOGIN COMPLETADO: ${authUser.nombre} - Clínica: ${clinicaData['nombre']}");
      return authUser;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /*
  =========================
  VALIDACIÓN DE LICENCIA
  =========================
  */
  Future<Map<String, dynamic>> _validateLicense(String licenseKey) async {
    try {
      // 1. Obtener datos de la licencia
      final licenseData = await _client
          .from('licencias')
          .select('clinica_id, estado, max_usuarios')
          .eq('license_key', licenseKey)
          .maybeSingle();

      if (licenseData == null) {
        throw Exception('Licencia inválida');
      }

      // 2. Validar estado de la licencia
      if (licenseData['estado'] != 'activa') {
        throw Exception('Licencia no activa');
      }

      // 3. Validar que tenga clínica vinculada
      if (licenseData['clinica_id'] == null || licenseData['clinica_id'].toString().isEmpty) {
        throw Exception('Licencia no vinculada a clínica');
      }

      final clinicaId = licenseData['clinica_id'].toString();
      final maxUsuarios = licenseData['max_usuarios'] as int;

      // 4. Contar usuarios actuales de la clínica
      final countResult = await _client
          .from('usuarios')
          .select('id')
          .eq('clinica_id', clinicaId)
          .eq('activo', true);

      final usuariosActuales = countResult.length;

      // 5. Validar límite de usuarios
      if (usuariosActuales >= maxUsuarios) {
        throw Exception('Límite de usuarios alcanzado para esta clínica ($maxUsuarios usuarios permitidos)');
      }

      print("LICENCIA VÁLIDA: Clínica $clinicaId - Usuarios: $usuariosActuales/$maxUsuarios");

      return {
        'clinica_id': clinicaId,
        'max_usuarios': maxUsuarios,
        'usuarios_actuales': usuariosActuales,
      };
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /*
  =========================
  VALIDACIÓN DE SUSCRIPCIÓN
  =========================
  */
  Future<Map<String, dynamic>> _validateSubscription(String clinicaId) async {
    try {
      final subscriptionData = await _client
          .from('suscripciones')
          .select('estado, fecha_fin')
          .eq('clinica_id', clinicaId)
          .eq('estado', 'activa')
          .gte('fecha_fin', DateTime.now().toIso8601String())
          .order('fecha_fin', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subscriptionData == null) {
        throw Exception('La clínica no tiene una suscripción activa');
      }

      print("SUSCRIPCIÓN VÁLIDA: ${subscriptionData['estado']} - Vence: ${subscriptionData['fecha_fin']}");

      return subscriptionData;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /*
  =========================
  CONTROL DE SESIÓN ÚNICA
  =========================
  */
  Future<void> _handleSingleSession(String usuarioId) async {
    try {
      // Buscar sesiones activas existentes
      final activeSessions = await _client
          .from('sesiones_usuario')
          .select('id')
          .eq('usuario_id', usuarioId)
          .eq('activa', true);

      if (activeSessions.isNotEmpty) {
        // Cerrar sesiones anteriores
        for (final session in activeSessions) {
          await _client
              .from('sesiones_usuario')
              .update({'activa': false})
              .eq('id', session['id']);
        }
        print("Cerradas ${activeSessions.length} sesiones anteriores para usuario $usuarioId");
      }
    } catch (e) {
      print("Error controlando sesión única: $e");
      // No bloquear el login si falla el control de sesión
    }
  }

  /*
  =========================
  REGISTRAR DISPOSITIVO
  =========================
  */
  Future<String> _registerDevice(String usuarioId) async {
    try {
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _client
          .from('dispositivos')
          .upsert({
            'usuario_id': usuarioId,
            'dispositivo_id': deviceId,
            'plataforma': 'flutter_web',
            'activo': true,
          }, onConflict: 'usuario_id');

      print("Dispositivo registrado: $deviceId");
      return deviceId;
    } catch (e) {
      print("Error registrando dispositivo: $e");
      // Continuar con login aunque falle el registro de dispositivo
      return 'fallback_device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /*
  =========================
  CREAR SESIÓN DE USUARIO
  =========================
  */
  Future<void> _createUserSession(String usuarioId, String deviceId) async {
    try {
      await _client
          .from('sesiones_usuario')
          .insert({
            'usuario_id': usuarioId,
            'dispositivo_id': deviceId,
            'activa': true,
            'login_time': DateTime.now().toIso8601String(),
          });

      print("Sesión creada para usuario $usuarioId con dispositivo $deviceId");
    } catch (e) {
      print("Error creando sesión: $e");
      // No bloquear el login si falla la creación de sesión
    }
  }

  /*
  =========================
  REGISTRO CON LICENCIA
  =========================
  */
  Future<auth.AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String nombre,
    required String licenseKey,
  }) async {
    try {
      print("SIGNUP: validando licencia $licenseKey");

      // 1. Validar licencia antes de crear usuario
      final licenseValidation = await _validateLicense(licenseKey);
      final clinicaId = licenseValidation['clinica_id'] as String;

      print("SIGNUP: licencia válida para clínica $clinicaId");

      // 2. Crear usuario en Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception("No se pudo crear el usuario en el sistema de autenticación");
      }

      print("AUTH USER ID: ${response.user!.id}");

      // 3. Insertar perfil en tabla usuarios con clinica_id de la licencia
      final userData = await _client
          .from('usuarios')
          .insert({
            'auth_user_id': response.user!.id,
            'clinica_id': clinicaId, // Usar el clinica_id de la licencia validada
            'nombre': nombre,
            'email': email,
            'rol': 'psicologo',
            'activo': true,
          })
          .select()
          .single();

      print("Usuario creado en tabla usuarios con clínica $clinicaId");

      // 4. Retornar usuario completo
      return auth.AuthUser.fromMap({
        ...response.user!.toJson(),
        ...userData,
      });
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /*
  =========================
  USUARIO ACTUAL
  =========================
  */
  Future<auth.AuthUser?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;

      if (user == null) {
        return null;
      }

      final userData = await _client
          .from('usuarios')
          .select()
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (userData == null) {
        return auth.AuthUser.fromMap(user.toJson());
      }

      return auth.AuthUser.fromMap({
        ...user.toJson(),
        ...userData,
      });
    } catch (_) {
      return null;
    }
  }

  /*
  =========================
  LOGOUT
  =========================
  */
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /*
  =========================
  RECUPERAR CONTRASEÑA
  =========================
  */
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /*
  =========================
  STREAM DE AUTENTICACIÓN
  =========================
  */
  Stream<auth.AuthUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;

      if (user == null) {
        return null;
      }

      return await getCurrentUser();
    });
  }

  /*
  =========================
  MANEJO DE ERRORES
  =========================
  */
  String _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'invalid_credentials':
          return 'Email o contraseña incorrectos';

        case 'user_already_exists':
          return 'El email ya está registrado';

        case 'email_not_confirmed':
          return 'Debes confirmar tu email';

        case 'over_email_send_rate_limit':
          return 'Demasiados intentos, espera unos segundos';

        default:
          return error.message;
      }
    }

    if (error is PostgrestException) {
      if (error.code == '23505') {
        return 'El número de documento ya está registrado';
      }
    }

    return "Error de autenticación";
  }
}