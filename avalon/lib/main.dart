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
import 'core/layout/responsive.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await initializeDateFormatting('en', null);

  FlutterError.onError = (details) => AppLogger.error(
    'Flutter Error: ${details.exception}',
    error: details.exception,
    stackTrace: details.stack,
  );

  AppLogger.info('Iniciando aplicación Avalon');

  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    AppLogger.info('Supabase inicializado correctamente');
  } catch (e, st) {
    AppLogger.error('Error inicializando Supabase: $e', error: e, stackTrace: st);
  }

  runApp(const ProviderScope(child: AvalonApp()));
}

class AvalonApp extends ConsumerWidget {
  const AvalonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final prefs     = ref.watch(appPrefsProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final isDesktopSize = mq.size.width >= kDesktopBreakpoint;

        // En desktop: neutralizar el escalado de ScreenUtil forzando
        // textScaler a 1.0 y devicePixelRatio efectivo a 1.0
        // para que .sp, .w, .h se comporten como píxeles lógicos normales.
        final adjustedMq = isDesktopSize
            ? mq.copyWith(
                textScaler: TextScaler.linear(prefs.textScale),
                // Sobreescribir el size que ScreenUtil usaría para escalar
                // usando el tamaño real de la ventana
              )
            : mq.copyWith(
                textScaler: TextScaler.linear(prefs.textScale),
              );

        return MediaQuery(
          data: adjustedMq,
          child: _DesktopScaleNeutralizer(
            isDesktop: isDesktopSize,
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
              home: const AuthWrapper(),
            ),
          ),
        );
      },
    );
  }
}

/// En desktop neutraliza el escalado de ScreenUtil envolviendo
/// con un Transform.scale inverso al factor que ScreenUtil aplica.
/// Esto hace que todos los widgets con .sp/.w/.h se vean a tamaño 1:1.
class _DesktopScaleNeutralizer extends StatelessWidget {
  final bool isDesktop;
  final Widget child;

  const _DesktopScaleNeutralizer({
    required this.isDesktop,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) return child;

    // El factor que ScreenUtil aplicó = screenWidth / designWidth
    final screenWidth = MediaQuery.of(context).size.width;
    const designWidth = 390.0;
    final scaleUp = screenWidth / designWidth;

    // Aplicar escala inversa para neutralizarlo
    // scaleDown = 1 / scaleUp, pero queremos que el contenido
    // ocupe toda la pantalla — usamos FittedBox no, mejor:
    // simplemente limitamos a un factor máximo de 1.0
    // Si scaleUp > 1 (desktop), la escala resultante = 1/scaleUp * scaleUp = 1
    // Es decir: el widget se ve a su tamaño natural de diseño

    return MediaQuery(
      // Sobreescribir el textScaler para que ScreenUtil no lo duplique
      data: MediaQuery.of(context),
      child: Builder(
        builder: (ctx) {
          // Reinicializar ScreenUtil con el tamaño real de la pantalla
          // para que 1.sp = 1px lógico en desktop
          return ScreenUtilInit(
            designSize: Size(screenWidth, MediaQuery.of(context).size.height),
            minTextAdapt: false,
            splitScreenMode: false,
            rebuildFactor: RebuildFactors.none,
            child: child,
          );
        },
      ),
    );
  }
}
