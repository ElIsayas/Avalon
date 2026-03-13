import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/supabase/supabase.dart';
import '../../../../core/constants/app_constants.dart';

class FixedDebugScreen extends StatefulWidget {
  const FixedDebugScreen({super.key});

  @override
  State<FixedDebugScreen> createState() => _FixedDebugScreenState();
}

class _FixedDebugScreenState extends State<FixedDebugScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  List<String> logs = [];
  bool isLoading = false;
  bool canTest = true;
  DateTime? lastTestTime;

  void addLog(String message) {
    setState(() {
      logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
      if (logs.length > 50) logs.removeAt(0);
    });
  }

  Future<void> _testFixedAuth() async {
    if (!canTest) {
      addLog('❌ Debes esperar 40 segundos entre pruebas');
      final waitTime = DateTime.now().difference(lastTestTime ?? DateTime.now()).inSeconds;
      addLog('   Tiempo restante: ${40 - waitTime} segundos');
      return;
    }

    setState(() {
      isLoading = true;
      canTest = false;
      lastTestTime = DateTime.now();
    });

    addLog('=== INICIANDO PRUEBA CORREGIDA ===');
    
    try {
      final email = 'fixed${DateTime.now().millisecondsSinceEpoch}@test.com';
      final password = '123456';
      final name = 'Test User';
      
      addLog('Email: $email');
      addLog('Nombre: $name');
      
      // 1. Test con datos simplificados
      addLog('1. Creando usuario con datos mínimos...');
      
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': name,
          'test_mode': true,
        },
      );
      
      if (authResponse.user != null) {
        addLog('   ✅ Usuario creado en Auth');
        addLog('   User ID: ${authResponse.user!.id}');
        addLog('   Email: ${authResponse.user!.email}');
        
        // 2. Verificación con delay para evitar rate limiting
        addLog('2. Esperando 3 segundos antes de verificar...');
        await Future.delayed(Duration(seconds: 3));
        
        try {
          final verification = await supabase.auth.admin.getUserById(authResponse.user!.id);
          if (verification.user != null) {
            addLog('   ✅ Verificación admin exitosa');
            addLog('   Usuario verificado: ${verification.user!.email}');
            
            // 3. Crear en tabla usuarios con datos básicos
            addLog('3. Creando registro en tabla usuarios...');
            
            final userData = await supabase
                .from(AppConstants.tableUsuarios)
                .insert({
                  'auth_user_id': authResponse.user!.id,
                  'nombre': name,
                  'email': email,
                  'rol': 'psicologo',
                  'activo': true,
                  // No incluir clinica_id para evitar errores
                })
                .select('id, auth_user_id, nombre, email, rol, activo')
                .single();
            
            addLog('   ✅ Usuario creado en tabla usuarios');
            addLog('   BD ID: ${userData['id']}');
            addLog('   Auth ID: ${userData['auth_user_id']}');
            
            addLog('');
            addLog('🎉 PRUEBA COMPLETADA EXITOSAMENTE');
            addLog('✅ Auth: Funcionando');
            addLog('✅ BD: Funcionando');
            addLog('✅ Verificación: Funcionando');
            
          } else {
            addLog('   ❌ Usuario no encontrado en verificación admin');
          }
        } catch (e) {
          addLog('   ❌ Error verificación: $e');
          addLog('   Tipo: ${e.runtimeType}');
        }
        
      } else {
        addLog('   ❌ Falló creación en Auth - sin usuario creado');
      }
      
    } catch (e) {
      addLog('❌ ERROR GENERAL: $e');
      addLog('Tipo: ${e.runtimeType}');
      
      if (e.toString().contains('Database error saving new user')) {
        addLog('');
        addLog('🔍 DIAGNÓSTICO: Error de base de datos en Auth');
        addLog('📋 Posibles causas:');
        addLog('   1. Stack depth limit (solución: aumentar en Settings)');
        addLog('   2. Rate limiting (solución: esperar 40s)');
        addLog('   3. RLS Policies (solución: revisar Auth > Policies)');
        addLog('   4. Email confirmation (solución: desactivar temporalmente)');
      }
      
      if (e.toString().contains('over_email_send_rate_limit')) {
        addLog('');
        addLog('⏰ RATE LIMIT DETECTADO');
        addLog('   Esperar 40 segundos para próxima prueba...');
        
        // Programar reactivación después de 40 segundos
        Future.delayed(Duration(seconds: 40), () {
          setState(() => canTest = true);
        });
      }
    } finally {
      if (!canTest) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Corregido - Auth',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Formulario
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Formulario de Prueba',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: isLoading || !canTest ? null : _testFixedAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canTest ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48.h),
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text('Probando...'),
                            ],
                          )
                        : Text(canTest ? 'Ejecutar Prueba Corregida' : 'Esperar ${40 - DateTime.now().difference(lastTestTime ?? DateTime.now()).inSeconds}s'),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Logs
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logs de Diagnóstico:',
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
                                       log.contains('🔍') ? Colors.yellowAccent :
                                       log.contains('🎉') ? Colors.blueAccent :
                                       log.contains('⏰') ? Colors.orangeAccent :
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
            ),
          ],
        ),
      ),
    );
  }
}
