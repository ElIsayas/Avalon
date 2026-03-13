import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../admin/presentation/screens/admin_database_screen.dart';
import '../../../../shared/widgets/desktop_layout.dart';
import '../../../../shared/widgets/debug_console.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAdmin = ref.watch(isAdminProvider);
    
    // Debug para verificar valores
    print('🔍 DASHBOARD DEBUG: authState.user?.rol = ${authState.user?.rol}');
    print('🔍 DASHBOARD DEBUG: isAdmin = $isAdmin');
    print('🔍 DASHBOARD DEBUG: authState.user?.isAdministrador = ${authState.user?.isAdministrador}');

    // Build desktop-optimized dashboard content
    final dashboardContent = Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.w), // Aumentado de 20 a 32
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and role indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Panel de Control',
                            style: GoogleFonts.poppins(
                              fontSize: 32.sp, // Aumentado de 24 a 32
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(width: 16.w), // Aumentado de 10 a 16
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h), // Aumentado padding
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.red.withValues(alpha:0.1) : Colors.blue.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(24.r), // Aumentado de 20 a 24
                              border: Border.all(
                                color: isAdmin ? Colors.red.withValues(alpha:0.3) : Colors.blue.withValues(alpha:0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAdmin ? Icons.admin_panel_settings : Icons.psychology,
                                  size: 20.w, // Aumentado de 14 a 20
                                  color: isAdmin ? Colors.red : Colors.blue,
                                ),
                                SizedBox(width: 8.w), // Aumentado de 4 a 8
                                Text(
                                  isAdmin ? 'ADMIN' : 'PSICÓLOGO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp, // Aumentado de 10 a 14
                                    fontWeight: FontWeight.w600,
                                    color: isAdmin ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h), // Aumentado de 6 a 12
                      Text(
                        'Bienvenido, ${authState.user?.displayName ?? "Usuario"}',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp, // Aumentado de 14 a 18
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Rol: ${isAdmin ? 'Administrador' : 'Psicólogo'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp, // Aumentado de 12 a 16
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  // Botón de logout para todos los usuarios
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showLogoutDialog(context, ref),
                        icon: const Icon(Icons.logout),
                        tooltip: 'Cerrar Sesión',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          foregroundColor: Colors.red,
                          iconSize: 28.w,
                          padding: EdgeInsets.all(12.w),
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin) ...[
                    // Botón de test de credenciales (solo admins)
                    IconButton(
                      onPressed: () => _testCredentials(context, ref),
                      icon: const Icon(Icons.bug_report),
                      tooltip: 'Test Credenciales',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        foregroundColor: Colors.orange,
                        iconSize: 28.w,
                        padding: EdgeInsets.all(12.w),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _showRoleDebugDialog(context, ref),
                          icon: const Icon(Icons.person_outline),
                          tooltip: 'Debug Roles',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey[600],
                            iconSize: 28.w,
                            padding: EdgeInsets.all(12.w),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          onPressed: () => _showDebugDialog(context),
                          icon: const Icon(Icons.bug_report),
                          tooltip: 'Debug Supabase Auth',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey[600],
                            iconSize: 28.w,
                            padding: EdgeInsets.all(12.w),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              SizedBox(height: 40.h), // Aumentado de 24 a 40
              
              // Role-specific Dashboard Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title based on role
                    Text(
                      isAdmin ? 'Panel Administrativo' : 'Panel Clínico',
                      style: GoogleFonts.poppins(
                        fontSize: 24.sp, // Aumentado de 18 a 24
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 24.h), // Aumentado de 16 a 24
                    
                    // Quick Actions Grid - Desktop optimized
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: isAdmin ? 3 : 2, // Different layout for roles
                        mainAxisSpacing: 24.h, // Aumentado de 16 a 24
                        crossAxisSpacing: 24.w, // Aumentado de 16 a 24
                        childAspectRatio: isAdmin ? 1.0 : 1.2, // Tarjetas más cuadradas para admin
                        children: isAdmin ? _buildAdminCards(context) : _buildPsicologoCards(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with DesktopLayout
    return DesktopLayout(
      currentRoute: '/dashboard',
      child: dashboardContent,
    );
  }

  // Tarjetas específicas para Administrador
  List<Widget> _buildAdminCards(BuildContext context) {
    return [
      _buildQuickActionCard(
        context: context,
        title: 'Administración BD',
        subtitle: 'Test conexión y estadísticas',
        icon: Icons.storage,
        color: Colors.deepPurple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminDatabaseScreen()),
        ),
      ),
      _buildQuickActionCard(
        context: context,
        title: 'Gestión de Usuarios',
        subtitle: 'Administrar psicólogos',
        icon: Icons.admin_panel_settings,
        color: Colors.red,
        onTap: () => Navigator.pushNamed(context, '/admin'),
      ),
      _buildQuickActionCard(
        context: context,
        title: 'Mis Pacientes',
        subtitle: 'Ver y gestionar mis pacientes',
        icon: Icons.people,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/mis-pacientes'),
      ),
      _buildQuickActionCard(
        context: context,
        title: 'Citas',
        subtitle: 'Gestionar citas',
        icon: Icons.calendar_today,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/citas'),
      ),
      _buildQuickActionCard(
        context: context,
        title: 'Reportes',
        subtitle: 'Estadísticas y reportes',
        icon: Icons.assessment,
        color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, '/reportes'),
      ),
      _buildQuickActionCard(
        context: context,
        title: 'Configuración',
        subtitle: 'Ajustes del sistema',
        icon: Icons.settings,
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/settings'),
      ),
    ];
  }

  // Tarjetas específicas para Psicólogo
  List<Widget> _buildPsicologoCards(BuildContext context) {
    return [
      _buildQuickActionCard(
        context: context,
        title: 'Mis Pacientes',
        subtitle: 'Gestionar mis pacientes',
        icon: Icons.people,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/pacientes'),
      ),
      _buildQuickActionCard(
        context: context,
        title: 'Agenda',
        subtitle: 'Mis citas y sesiones',
        icon: Icons.calendar_month,
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/citas'),
      ),
      _buildQuickActionCard(
        context: context,
        title: 'Sesiones',
        subtitle: 'Registrar sesiones clínicas',
        icon: Icons.psychology,
        color: Colors.teal,
        onTap: () => Navigator.pushNamed(context, '/sesiones'),
      ),
      _buildQuickActionCard(
        context: context,
        title: 'Evaluaciones',
        subtitle: 'Tests psicológicos',
        icon: Icons.quiz,
        color: Colors.indigo,
        onTap: () => Navigator.pushNamed(context, '/evaluaciones'),
      ),
    ];
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r), // Aumentado de 15 a 20
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20.r), // Aumentado de 15 a 20
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w), // Aumentado de 12 a 20
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48.w, // Aumentado de 32 a 48
                color: color,
              ),
              SizedBox(height: 16.h), // Aumentado de 8 a 16
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp, // Aumentado de 14 a 18
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h), // Aumentado de 2 a 8
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp, // Aumentado de 12 a 14
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
      builder: (context) => DebugConsoleDialog(),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cerrar Sesión',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showRoleDebugDialog(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRoleInfo = ref.watch(userRoleInfoProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isPsicologo = ref.watch(isPsicologoProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Debug - Roles de Usuario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auth User:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                authState.user?.toString() ?? 'No user',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              Text(
                'Rol desde AuthUser:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                authState.user?.rol ?? "No role",
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              Text(
                'isAdministrador (getter):',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                '${authState.user?.isAdministrador ?? false}',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              Text(
                'isPsicologo (getter):',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                '${authState.user?.isPsicologo ?? false}',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              Text(
                'isAdminProvider:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                '$isAdmin',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              Text(
                'isPsicologoProvider:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                '$isPsicologo',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16.h),
              Text(
                'userRoleInfo:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                userRoleInfo.toString(),
                style: GoogleFonts.poppins(color: Colors.grey[600]),
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

  void _testCredentials(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test de Credenciales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Este botón probará las credenciales directamente con Supabase.'),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Test directo con Supabase
                  final client = Supabase.instance.client;
                  
                  print('🧪 TEST DIRECTO: Iniciando test de admin@example.com');
                  final response = await client.auth.signInWithPassword(
                    email: 'admin@example.com',
                    password: 'admin123',
                  );
                  
                  print('✅ TEST DIRECTO: Response recibida');
                  print('👤 TEST DIRECTO: User: ${response.user?.email}');
                  print('🆔 TEST DIRECTO: ID: ${response.user?.id}');
                  
                  if (response.user != null) {
                    // Logout inmediato
                    await client.auth.signOut();
                    print('🚪 TEST DIRECTO: Logout completado');
                  }
                  
                } catch (e) {
                  print('❌ TEST DIRECTO: Error: $e');
                  print('❌ TEST DIRECTO: Error type: ${e.runtimeType}');
                  
                  // Si el error es 400, el usuario no existe
                  if (e.toString().contains('400') || e.toString().contains('Invalid login credentials')) {
                    print('🔧 USUARIO NO EXISTE - Intentando crear...');
                    await _createAdminUser();
                  }
                }
              },
              child: Text('Test Admin Credentials'),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _createAdminUser(),
              child: Text('Crear Usuario Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _testCustomAuth(),
              child: Text('Test Custom Auth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
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

  Future<void> _createAdminUser() async {
    try {
      final client = Supabase.instance.client;
      
      print('🔧 CREANDO USUARIO ADMIN EN TABLA USUARIOS...');
      
      // Verificar si ya existe
      final existingUser = await client
          .from('usuarios')
          .select()
          .eq('email', 'admin@example.com')
          .maybeSingle();
          
      if (existingUser != null) {
        print('✅ Usuario admin ya existe en tabla usuarios');
        print('� Usuario listo para usar!');
        return;
      }
      
      // Crear usuario en tabla usuarios
      await client.from('usuarios').insert({
        'nombre': 'Administrador',
        'email': 'admin@example.com',
        'password': 'admin123',
        'rol': 'admin',
        'activa': true,
        'licencia_id': '1',
        'device_id': null,
        'especialidad': null,
        'disponibilidad': true,
        'fecha_registro': DateTime.now().toIso8601String(),
      });
      
      print('✅ Usuario admin creado en tabla usuarios');
      print('🎉 USUARIO ADMIN CREADO EXITOSAMENTE');
      print('📧 Ahora puedes hacer login con: admin@example.com / admin123');
      
    } catch (e) {
      print('❌ Error creando usuario admin: $e');
      print('❌ Error type: ${e.runtimeType}');
    }
  }

  Future<void> _testCustomAuth() async {
    try {
      final client = Supabase.instance.client;
      
      print('🔐 TESTING CUSTOM AUTH...');
      
      // Test login personalizado
      final response = await client
          .from('usuarios')
          .select()
          .eq('email', 'admin@example.com')
          .eq('password', 'admin123')
          .eq('activa', true)
          .maybeSingle();
      
      if (response != null) {
        print('✅ Custom Auth exitoso:');
        print('   - Nombre: ${response['nombre']}');
        print('   - Rol: ${response['rol']}');
        print('   - Activo: ${response['activa']}');
      } else {
        print('❌ Custom Auth falló - Usuario no encontrado');
      }
      
    } catch (e) {
      print('❌ Error en test custom auth: $e');
    }
  }
}
