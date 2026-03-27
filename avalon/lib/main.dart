import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/app_prefs_provider.dart';
import 'core/notifications/notifications_service.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
  await initializeDateFormatting('es', null);
  await initializeDateFormatting('en', null);

  FlutterError.onError = (details) => AppLogger.error(
        'Flutter Error: ${details.exception}',
        error: details.exception,
        stackTrace: details.stack,
      );
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'Unhandled platform error: $error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  AppLogger.info('Iniciando aplicación Avalon');

  try {
    if (AppConstants.supabaseUrl.isEmpty ||
        AppConstants.supabaseAnonKey.isEmpty) {
      throw Exception(
          'Faltan SUPABASE_URL y SUPABASE_ANON_KEY. Usa --dart-define para configurarlas.');
    }
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    await AvalonNotificationsService.instance.init();
    AppLogger.info('Supabase inicializado correctamente');
  } catch (e, st) {
    AppLogger.error('Error inicializando Supabase: $e',
        error: e, stackTrace: st);
  }

  runApp(const ProviderScope(child: AvalonApp()));
}

class AvalonApp extends ConsumerWidget {
  const AvalonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final prefs = ref.watch(appPrefsProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final adjustedMq = mq.copyWith(
          textScaler: TextScaler.linear(prefs.textScale),
        );

        return MediaQuery(
          data: adjustedMq,
          child: MaterialApp(
            title: 'Avalon',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: prefs.locale,
            supportedLocales: soportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => child ?? const SizedBox.shrink(),
            home: const AuthWrapper(),
          ),
        );
      },
    );
  }
}
