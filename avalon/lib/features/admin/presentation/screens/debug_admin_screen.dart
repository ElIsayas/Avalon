import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/admin_service.dart';
import '../../../../core/supabase/supabase.dart';
import '../../../../core/constants/app_constants.dart';

class DebugAdminScreen extends ConsumerStatefulWidget {
  const DebugAdminScreen({super.key});

  @override
  ConsumerState<DebugAdminScreen> createState() => _DebugAdminScreenState();
}

class _DebugAdminScreenState extends ConsumerState<DebugAdminScreen> {
  final _nombreController = TextEditingController(text: 'Test Psicólogo');
  final _emailController = TextEditingController(text: 'test@clinica.com');
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

  Future<void> _runDiagnostic() async {
    setState(() => isLoading = true);
    addLog('=== INICIANDO DIAGNÓSTICO COMPLETO ===');
    
    try {
      final service = AdminService(supabase);
      
      // 1. Diagnóstico de conexión
      addLog('1. Verificando conexión con Supabase...');
      final diagnostic = await service.diagnosticarConexion();
      
      addLog('   URL Supabase: ${diagnostic['supabase_url']}');
      addLog('   Conexión activa: ${diagnostic['conexion_activa']}');
      addLog('   Tabla usuarios accesible: ${diagnostic['tabla_usuarios_accesible']}');
      if (diagnostic['error_tabla_usuarios'] != null) {
        addLog('   Error tabla usuarios: ${diagnostic['error_tabla_usuarios']}');
      }
      addLog('   Usuario actual Auth: ${diagnostic['usuario_actual_auth']}');
      addLog('   Permisos admin Auth: ${diagnostic['permisos_admin_auth']}');
      
      // 2. Verificar tabla usuarios
      addLog('\n2. Verificando tabla usuarios...');
      try {
        final psicologos = await service.getPsicologosByClinica('yuse-clinica-id');
        addLog('   Psicólogos existentes: ${psicologos.length}');
        for (var p in psicologos) {
          addLog('   - ${p.nombre} (${p.email}) - Auth ID: ${p.authUserId}');
        }
      } catch (e) {
        addLog('   Error al obtener psicólogos: $e');
      }
      
      // 3. Verificar tabla auth.users directamente
      addLog('\n3. Verificando usuarios en Auth...');
      try {
        // Intentar obtener usuario actual
        final currentUser = supabase.auth.currentUser;
        if (currentUser != null) {
          addLog('   Usuario actual logueado: ${currentUser.email}');
          addLog('   User ID: ${currentUser.id}');
        } else {
          addLog('   No hay usuario logueado');
        }
      } catch (e) {
        addLog('   Error al verificar Auth: $e');
      }
      
      addLog('\n=== DIAGNÓSTICO COMPLETADO ===');
      
    } catch (e) {
      addLog('ERROR EN DIAGNÓSTICO: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _testCreatePsicologo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    addLog('\n=== INICIANDO PRUEBA DE CREACIÓN ===');
    
    try {
      final service = AdminService(supabase);
      
      final psicologo = await service.crearPsicologo(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        clinicaId: 'yuse-clinica-id',
      );
      
      addLog('✅ PSICÓLOGO CREADO EXITOSAMENTE');
      addLog('   ID: ${psicologo.id}');
      addLog('   Auth User ID: ${psicologo.authUserId}');
      addLog('   Nombre: ${psicologo.nombre}');
      addLog('   Email: ${psicologo.email}');
      
      // Verificación post-creación
      addLog('\nVerificación post-creación...');
      
      // 1. Verificar en tabla usuarios
      try {
        final verification = await supabase
            .from(AppConstants.tableUsuarios)
            .select('*')
            .eq('auth_user_id', psicologo.authUserId)
            .single();
        addLog('✅ Verificado en tabla usuarios: ${verification['nombre']}');
      } catch (e) {
        addLog('❌ Error al verificar en tabla usuarios: $e');
      }
      
      // 2. Verificar en Auth
      try {
        final authVerification = await supabase.auth.admin.getUserById(psicologo.authUserId);
        if (authVerification.user != null) {
          addLog('✅ Verificado en Auth: ${authVerification.user!.email}');
        } else {
          addLog('❌ NO ENCONTRADO EN AUTH');
        }
      } catch (e) {
        addLog('❌ Error al verificar en Auth: $e');
      }
      
      addLog('\n=== PRUEBA COMPLETADA ===');
      
    } catch (e) {
      addLog('❌ ERROR EN CREACIÓN: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _testDirectAuth() async {
    setState(() => isLoading = true);
    addLog('\n=== PRUEBA DIRECTA CON AUTH ===');
    
    try {
      addLog('Creando usuario directamente en Auth...');
      
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (authResponse.user != null) {
        addLog('✅ Usuario creado en Auth');
        addLog('   User ID: ${authResponse.user!.id}');
        addLog('   Email: ${authResponse.user!.email}');
        addLog('   Created At: ${authResponse.user!.createdAt}');
        
        // Verificar inmediatamente
        try {
          final verification = await supabase.auth.admin.getUserById(authResponse.user!.id);
          addLog('✅ Verificación inmediata: ${verification.user != null ? 'EXITOSA' : 'FALLÓ'}');
        } catch (e) {
          addLog('❌ Error en verificación: $e');
        }
        
      } else {
        addLog('❌ Falló creación en Auth: user es null');
      }
      
    } catch (e) {
      addLog('❌ Error en prueba directa Auth: $e');
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
          'Debug - Administración',
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
            // Formulario de prueba
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _runDiagnostic,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Diagnosticar'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _testDirectAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Test Auth Directo'),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _testCreatePsicologo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Crear Psicólogo'),
                          ),
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
