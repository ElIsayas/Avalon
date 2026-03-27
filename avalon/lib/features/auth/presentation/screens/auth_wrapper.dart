import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../../core/navigation/app_shell.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Recuperar sesiÃ³n activa al iniciar la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      final msg = next.error;
      if (msg == null || next.isLoading) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(authProvider.notifier).clearError();
    });

    // Cargando sesiÃ³n inicial
    if (state.isLoading && state.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Autenticado â†’ Dashboard
    if (state.isAuthenticated) return const AppShell();

    // No autenticado â†’ Login
    return const LoginScreen();
  }
}
