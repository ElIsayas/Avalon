import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  final String? requiredRole;

  const AuthGuard({
    super.key,
    required this.child,
    this.requiredRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Show loading while checking authentication
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if any
    if (authState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${authState.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).clearError(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if user is authenticated
    if (authState.user == null) {
      return const LoginRequiredScreen();
    }

    // Check role requirements
    if (requiredRole != null) {
      if (requiredRole == 'admin' && !authState.user!.isAdministrador) {
        return const AccessDeniedScreen(requiredRole: 'admin');
      }
      if (requiredRole == 'psicologo' && !authState.user!.isPsicologo) {
        return const AccessDeniedScreen(requiredRole: 'psicologo');
      }
    }

    return child;
  }
}

class LoginRequiredScreen extends StatelessWidget {
  const LoginRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autenticación Requerida')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Inicia sesión para continuar',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Por favor, inicia sesión para acceder a esta función',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  final String requiredRole;

  const AccessDeniedScreen({super.key, required this.requiredRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso Denegado')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Acceso Denegado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Se requiere rol de ${requiredRole == 'admin' ? 'Administrador' : 'Psicólogo'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                (route) => false,
              ),
              child: const Text('Volver al Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleBasedRedirect extends ConsumerWidget {
  const RoleBasedRedirect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState.user == null) {
      return const LoginRequiredScreen();
    }

    // Redirect based on role
    if (authState.user!.isAdministrador) {
      return const DashboardScreen(); // NOTE: Change to AdminDashboard when created
    } else if (authState.user!.isPsicologo) {
      return const DashboardScreen();
    } else {
      return const AccessDeniedScreen(requiredRole: 'admin or psicologo');
    }
  }
}
