import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase.dart';
import '../../../../core/constants/app_constants.dart';

class SimpleDebugScreen extends StatefulWidget {
  const SimpleDebugScreen({super.key});

  @override
  State<SimpleDebugScreen> createState() => _SimpleDebugScreenState();
}

class _SimpleDebugScreenState extends State<SimpleDebugScreen> {
  final _nombreController = TextEditingController(text: 'Test Psicólogo');
  final _emailController = TextEditingController(text: 'test${DateTime.now().millisecondsSinceEpoch}@clinica.com');
  final _passwordController = TextEditingController(text: '123456');
  final _formKey = GlobalKey<FormState>();
  
  List<String> logs = [];
  bool isLoading = false;

  void addLog(String message) {
    setState(() {
      logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
      if (logs.length > 50) logs.removeAt(0); // Mantener solo últimos 50 logs
    });
  }

  Future<void> _testBasicConnection() async {
    setState(() => isLoading = true);
    addLog('=== PRUEBA BÁSICA DE CONEXIÓN ===');
    
    try {
      addLog('URL Supabase: ${AppConstants.supabaseUrl}');
      addLog('Cliente Supabase: ${supabase != null ? "OK" : "NULL"}');
      
      // Test básico: intentar obtener la lista de usuarios
      addLog('Intentando consultar tabla usuarios...');
      final result = await supabase
          .from(AppConstants.tableUsuarios)
          .select('count')
          .limit(1);
      
      addLog('✅ Conexión básica exitosa');
      addLog('Resultado: $result');
      
    } catch (e) {
      addLog('❌ Error en conexión básica: $e');
      addLog('Tipo de error: ${e.runtimeType}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _testAuthDirect() async {
    setState(() => isLoading = true);
    addLog('\n=== PRUEBA DIRECTA CON SUPABASE AUTH ===');
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      addLog('Email: $email');
      addLog('Password: [${password.length} caracteres]');
      
      // 1. Verificar si ya existe
      addLog('Verificando si el email ya existe en Auth...');
      try {
        final signInTest = await supabase.auth.signInWithPassword(email: email, password: password);
        if (signInTest.user != null) {
          addLog('⚠️ Usuario ya existe en Auth');
          addLog('User ID: ${signInTest.user!.id}');
          await supabase.auth.signOut();
          return;
        }
      } catch (e) {
        addLog('Usuario no existe en Auth (esperado)');
      }
      
      // 2. Crear usuario en Auth
      addLog('Creando usuario en Supabase Auth...');
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      addLog('Respuesta Auth:');
      addLog('  User: ${authResponse.user != null ? "CREADO" : "NULL"}');
      addLog('  Session: ${authResponse.session != null ? "ACTIVA" : "NULL"}');
      
      if (authResponse.user != null) {
        addLog('✅ Usuario creado en Auth');
        addLog('  User ID: ${authResponse.user!.id}');
        addLog('  Email: ${authResponse.user!.email}');
        addLog('  Created At: ${authResponse.user!.createdAt}');
        addLog('  Email Confirmed: ${authResponse.user!.emailConfirmedAt}');
        
        // 3. Verificar inmediatamente con admin API
        addLog('Verificando con admin API...');
        try {
          final adminCheck = await supabase.auth.admin.getUserById(authResponse.user!.id);
          addLog('✅ Verificación admin: ${adminCheck.user != null ? "EXITOSA" : "FALLÓ"}');
          if (adminCheck.user != null) {
            addLog('  Email verificado: ${adminCheck.user!.email}');
          }
        } catch (e) {
          addLog('❌ Error en verificación admin: $e');
          addLog('Posible causa: No se tienen permisos de admin o el usuario no se guardó correctamente');
        }
        
        // 4. Intentar login para verificar
        addLog('Verificando con login...');
        try {
          await supabase.auth.signOut();
          final loginTest = await supabase.auth.signInWithPassword(email: email, password: password);
          if (loginTest.user != null) {
            addLog('✅ Login verification: EXITOSO');
            addLog('  User ID: ${loginTest.user!.id}');
          } else {
            addLog('❌ Login verification: FALLÓ');
          }
          await supabase.auth.signOut();
        } catch (e) {
          addLog('❌ Error en login verification: $e');
        }
        
      } else {
        addLog('❌ Falló creación en Auth: user es null');
      }
      
    } catch (e) {
      addLog('❌ Error en prueba Auth: $e');
      addLog('Tipo de error: ${e.runtimeType}');
      if (e is AuthException) {
        addLog('AuthException Code: ${e.code}');
        addLog('AuthException Message: ${e.message}');
        addLog('AuthException Status: ${e.statusCode}');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _testFullCreation() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    addLog('\n=== PRUEBA COMPLETA DE CREACIÓN ===');
    
    try {
      final nombre = _nombreController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final clinicaId = 'yuse-clinica-id';
      
      addLog('Datos de creación:');
      addLog('  Nombre: $nombre');
      addLog('  Email: $email');
      addLog('  Clinica ID: $clinicaId');
      
      // 1. Verificar límite de psicólogos
      addLog('Verificando límite de psicólogos...');
      final psicologosExistentes = await supabase
          .from(AppConstants.tableUsuarios)
          .select('id')
          .eq('clinica_id', clinicaId)
          .eq('rol', 'psicologo')
          .eq('activo', true);
      
      final cantidad = psicologosExistentes.length;
      addLog('Psicólogos existentes: $cantidad');
      addLog('Límite máximo: 5');
      
      if (cantidad >= 5) {
        addLog('❌ Límite alcanzado');
        return;
      }
      
      // 2. Verificar email duplicado en BD
      addLog('Verificando email duplicado en BD...');
      final emailCheck = await supabase
          .from(AppConstants.tableUsuarios)
          .select('id')
          .eq('email', email)
          .eq('activo', true);
      
      if (emailCheck.isNotEmpty) {
        addLog('❌ Email ya existe en BD');
        return;
      }
      
      // 3. Crear en Auth
      addLog('Creando usuario en Auth...');
      AuthResponse? authResponse;
      
      try {
        authResponse = await supabase.auth.signUp(email: email, password: password);
        
        if (authResponse.user != null) {
          addLog('✅ Usuario creado en Auth');
          addLog('  Auth User ID: ${authResponse.user!.id}');
        } else {
          addLog('❌ Falló creación en Auth');
          return;
        }
      } catch (e) {
        addLog('❌ Error creando usuario en Auth: $e');
        return;
      }
      
      // 4. Crear en tabla usuarios
      addLog('Creando registro en tabla usuarios...');
      try {
        final userData = await supabase
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
        
        addLog('✅ Usuario creado en tabla usuarios');
        addLog('  BD User ID: ${userData['id']}');
        addLog('  Auth User ID: ${userData['auth_user_id']}');
        
        // 5. Verificación final
        addLog('\nVerificación final...');
        
        // Verificar en BD
        final bdVerification = await supabase
            .from(AppConstants.tableUsuarios)
            .select('*')
            .eq('auth_user_id', authResponse.user!.id)
            .single();
        
        addLog('✅ Verificación BD: ${bdVerification['nombre']}');
        
        // Verificar en Auth
        try {
          final authVerification = await supabase.auth.admin.getUserById(authResponse.user!.id);
          addLog('✅ Verificación Auth: ${authVerification.user != null ? "EXITOSA" : "FALLÓ"}');
        } catch (e) {
          addLog('❌ Error verificación Auth: $e');
        }
        
        addLog('\n✅ CREACIÓN COMPLETADA EXITOSAMENTE');
        
      } catch (e) {
        addLog('❌ Error creando en tabla usuarios: $e');
        
        // Intentar rollback: eliminar de Auth
        if (authResponse?.user != null) {
          try {
            await supabase.auth.admin.deleteUser(authResponse!.user!.id);
            addLog('🔄 Rollback: Usuario eliminado de Auth');
          } catch (deleteError) {
            addLog('❌ Error en rollback: $deleteError');
          }
        }
      }
      
    } catch (e) {
      addLog('❌ Error general en creación: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearLogs() {
    setState(() => logs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Simple - Supabase Auth',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Limpiar logs',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulario
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formulario de Prueba',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Requerido';
                        if (!value!.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Requerido';
                        if (value!.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 8.w,
                      children: [
                        ElevatedButton(
                          onPressed: isLoading ? null : _testBasicConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test Conexión'),
                        ),
                        ElevatedButton(
                          onPressed: isLoading ? null : _testAuthDirect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test Auth'),
                        ),
                        ElevatedButton(
                          onPressed: isLoading ? null : _testFullCreation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Test Completo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Logs
            Container(
              width: double.infinity,
              height: 400.h,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logs de Depuración',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: logs.map((log) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          child: Text(
                            log,
                            style: GoogleFonts.poppins(
                              color: log.contains('✅') ? Colors.greenAccent :
                                     log.contains('❌') ? Colors.redAccent :
                                     log.contains('⚠️') ? Colors.yellowAccent :
                                     log.contains('ERROR') ? Colors.red :
                                     Colors.white,
                              fontSize: 11.sp,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (isLoading)
              Container(
                margin: EdgeInsets.only(top: 16.h),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
