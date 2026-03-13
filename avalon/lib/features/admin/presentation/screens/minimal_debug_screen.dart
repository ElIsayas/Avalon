import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/supabase/supabase.dart';
import '../../../../core/constants/app_constants.dart';

class MinimalDebugScreen extends StatefulWidget {
  const MinimalDebugScreen({super.key});

  @override
  State<MinimalDebugScreen> createState() => _MinimalDebugScreenState();
}

class _MinimalDebugScreenState extends State<MinimalDebugScreen> {
  List<String> logs = [];
  bool isLoading = false;

  void addLog(String message) {
    setState(() {
      logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
      if (logs.length > 30) logs.removeAt(0);
    });
  }

  Future<void> _testMinimalAuth() async {
    setState(() => isLoading = true);
    addLog('=== INICIANDO PRUEBA MÍNIMA ===');
    
    try {
      final email = 'minimal${DateTime.now().millisecondsSinceEpoch}@test.com';
      final password = '123456';
      
      addLog('Email: $email');
      addLog('Password: [${password.length} caracteres]');
      
      // 1. Test básico de conexión
      addLog('1. Probando conexión básica...');
      await supabase
          .from(AppConstants.tableUsuarios)
          .select('count')
          .limit(1);
      addLog('   ✅ Conexión BD exitosa');
      
      // 2. Crear usuario sin confirmación
      addLog('2. Creando usuario en Auth...');
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'test_mode': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (authResponse.user != null) {
        addLog('   ✅ Usuario creado en Auth');
        addLog('   User ID: ${authResponse.user!.id}');
        addLog('   Email: ${authResponse.user!.email}');
        addLog('   Created: ${authResponse.user!.createdAt}');
        
        // 3. Verificación inmediata
        addLog('3. Verificando usuario...');
        await Future.delayed(Duration(seconds: 2));
        
        try {
          final verification = await supabase.auth.admin.getUserById(authResponse.user!.id);
          if (verification.user != null) {
            addLog('   ✅ Verificación admin exitosa');
            addLog('   Verificado: ${verification.user!.email}');
          } else {
            addLog('   ❌ Usuario no encontrado en admin');
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
        addLog('   1. RLS Policies bloqueando auth.users');
        addLog('   2. Email confirmation requerido');
        addLog('   3. Problemas con schema de auth.users');
        addLog('   4. Rate limiting del plan');
        addLog('');
        addLog('💡 SOLUCIONES:');
        addLog('   1. Desactivar email confirmation en Settings');
        addLog('   2. Revisar Authentication > Policies');
        addLog('   3. Verificar límites en Billing');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Mínimo - Auth Error',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Test button
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
                    'Prueba Mínima de Auth',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: isLoading ? null : _testMinimalAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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
                        : Text('Ejecutar Prueba'),
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
                                       log.contains('💡') ? Colors.blueAccent :
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
