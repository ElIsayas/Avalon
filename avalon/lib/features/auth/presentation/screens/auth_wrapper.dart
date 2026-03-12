import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_auth_provider.dart';
import 'auto_login_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userAuthProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(userAuthProvider);

    // Mientras carga, mostrar splash
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si está autenticado, mostrar dashboard
    if (authState.isAuthenticated) {
      return const DashboardScreen();
    }

    // Si no está autenticado, mostrar login
    return const AutoLoginScreen();
  }
}
