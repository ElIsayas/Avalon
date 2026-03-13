import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/pacientes/presentation/screens/pacientes_screen.dart';
import 'features/citas/presentation/screens/citas_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xovztnvrchdgpxnyebpr.supabase.co',
    anonKey: 'sb_publishable_TnT_BhEuiijFaXjw8vhamg_1i-rWmKB',
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1600, 900), // Reducido para mejor escalabilidad
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Avalon',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: const AuthWrapper(),
          routes: {
            '/dashboard': (context) => const DashboardScreen(),
            '/pacientes': (context) => const PacientesScreen(),
            '/citas': (context) => const CitasScreen(),
            '/admin': (context) => const AdminDashboardScreen(),
            // Rutas temporales para las que no tenemos pantalla aún
            '/sesiones': (context) => const Scaffold(
              body: Center(child: Text('Pantalla de Sesiones - En desarrollo')),
            ),
            '/evaluaciones': (context) => const Scaffold(
              body: Center(child: Text('Pantalla de Evaluaciones - En desarrollo')),
            ),
            '/reportes': (context) => const Scaffold(
              body: Center(child: Text('Pantalla de Reportes - En desarrollo')),
            ),
          },
        );
      },
    );
  }
}
