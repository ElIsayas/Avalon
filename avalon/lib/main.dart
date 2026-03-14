import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar manejo de errores globales
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  AppLogger.info('Iniciando aplicación Avalon');

  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    AppLogger.info('Supabase inicializado correctamente');
  } catch (e, stackTrace) {
    AppLogger.error('Error inicializando Supabase: $e', error: e, stackTrace: stackTrace);
    // Continuar aunque falle Supabase para mostrar error en UI
  }

  runApp(
    const ProviderScope(
      child: AvalonApp(),
    ),
  );
}

class AvalonApp extends StatelessWidget {
  const AvalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 base
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Avalon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
