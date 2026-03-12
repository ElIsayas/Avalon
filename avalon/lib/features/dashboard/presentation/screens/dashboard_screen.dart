import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/supabase/supabase.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _showDebugDialog(context),
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Supabase Auth',
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido!',
                        style: GoogleFonts.poppins(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        authState.user?.displayName ?? 'Usuario',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        authState.user?.email ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24.h),
                
                // Quick actions
                Text(
                  'Acciones Rápidas',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 1.2,
                  children: [
                    // Pacientes
                    _buildActionCard(
                      context,
                      icon: Icons.people,
                      title: 'Pacientes',
                      subtitle: 'Gestionar pacientes',
                      color: Colors.green,
                      onTap: () {
                        // TODO: Navegar a pacientes
                      },
                    ),
                    
                    // Citas
                    _buildActionCard(
                      context,
                      icon: Icons.calendar_today,
                      title: 'Citas',
                      subtitle: 'Ver citas',
                      color: Colors.orange,
                      onTap: () {
                        // TODO: Navegar a citas
                      },
                    ),
                    
                    // Sesiones
                    _buildActionCard(
                      context,
                      icon: Icons.psychology,
                      title: 'Sesiones',
                      subtitle: 'Registrar sesiones',
                      color: Colors.purple,
                      onTap: () {
                        // TODO: Navegar a sesiones
                      },
                    ),
                    
                    // Tests
                    _buildActionCard(
                      context,
                      icon: Icons.quiz,
                      title: 'Tests',
                      subtitle: 'Tests psicológicos',
                      color: Colors.red,
                      onTap: () {
                        // TODO: Navegar a tests
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: 24.h),
                
                // Recent activity
                Text(
                  'Actividad Reciente',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildActivityItem(
                        icon: Icons.person_add,
                        title: 'Nuevo paciente registrado',
                        time: 'Hace 2 horas',
                        color: Colors.green,
                      ),
                      _buildActivityItem(
                        icon: Icons.calendar_today,
                        title: 'Cita programada',
                        time: 'Hace 3 horas',
                        color: Colors.orange,
                      ),
                      _buildActivityItem(
                        icon: Icons.psychology,
                        title: 'Sesión completada',
                        time: 'Ayer',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40.w,
                color: color,
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Debug - Supabase Auth',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'URL Supabase:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                AppConstants.supabaseUrl,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              Text(
                'Tabla Usuarios:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                AppConstants.tableUsuarios,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _testAuthCreation(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Test Creación Auth'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _testAuthCreation(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final email = 'test${DateTime.now().millisecondsSinceEpoch}@clinica.com';
    final password = '123456';
    
    try {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Probando creación de usuario en Auth...'),
          backgroundColor: Colors.blue,
        ),
      );

      // 1. Crear usuario en Auth
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('✅ Usuario creado en Auth: ${authResponse.user!.id}'),
            backgroundColor: Colors.green,
          ),
        );

        // 2. Verificar con admin API
        try {
          final verification = await supabase.auth.admin.getUserById(authResponse.user!.id);
          if (verification.user != null) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('✅ Verificación admin exitosa'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('❌ Usuario no encontrado en verificación admin'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('❌ Error en verificación admin: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // 3. Intentar crear en tabla usuarios
        try {
          final userData = await supabase
              .from(AppConstants.tableUsuarios)
              .insert({
                'auth_user_id': authResponse.user!.id,
                'clinica_id': 'yuse-clinica-id',
                'nombre': 'Test User',
                'email': email,
                'rol': 'psicologo',
                'activo': true,
              })
              .select()
              .single();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('✅ Usuario creado en tabla usuarios: ${userData['id']}'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('❌ Error creando en tabla usuarios: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }

      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Falló creación en Auth: user es null'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error general: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 20.w,
              color: color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
