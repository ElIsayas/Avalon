import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/secure_auth_provider.dart';
import '../widgets/secure_signout_button.dart';

/// Ejemplo completo de cómo usar el sistema de signOut seguro
class SecureSignOutExample extends ConsumerStatefulWidget {
  const SecureSignOutExample({super.key});

  @override
  ConsumerState<SecureSignOutExample> createState() => _SecureSignOutExampleState();
}

class _SecureSignOutExampleState extends ConsumerState<SecureSignOutExample> {
  @override
  void initState() {
    super.initState();
    // Verificar estado de autenticación al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(secureAuthNotifierProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(secureAuthNotifierProvider);
    final authNotifier = ref.read(secureAuthNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo de SignOut Seguro'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => authNotifier.checkAuthStatus(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Verificar Estado',
          ),
        ],
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de estado
                  _buildStatusCard(authState),
                  const SizedBox(height: 20),

                  // Información de sesión
                  const SessionInfoWidget(),
                  const SizedBox(height: 20),

                  // Opciones de signOut
                  _buildSignOutOptions(),
                  const SizedBox(height: 20),

                  // Utilidades
                  _buildUtilities(),
                  const SizedBox(height: 20),

                  // Logs de ejemplo
                  _buildLogsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(SecureAuthState authState) {
    return Card(
      color: authState.isAuthenticated ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              authState.isAuthenticated ? Icons.check_circle : Icons.error,
              color: authState.isAuthenticated ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authState.isAuthenticated ? 'Autenticado' : 'No Autenticado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: authState.isAuthenticated ? Colors.green : Colors.red,
                    ),
                  ),
                  if (authState.error != null)
                    Text(
                      'Error: ${authState.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opciones de Cierre de Sesión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // SignOut normal
            const SecureSignOutButton(),
            const SizedBox(height: 12),

            // SignOut con mensaje personalizado
            CustomSignOutButton(
              onPressed: () => _handleCustomSignOut('Logout desde ejemplo'),
              child: const Text('Cerrar con Mensaje'),
            ),
            const SizedBox(height: 12),

            // SignOut limpiando todos los datos
            CustomSignOutButton(
              onPressed: () => _handleCustomSignOut('Logout completo desde ejemplo', clearAllData: true),
              child: const Text('Cerrar y Limpiar Todo'),
            ),
            const SizedBox(height: 12),

            // SignOut manteniendo device info
            CustomSignOutButton(
              onPressed: () => _handleCustomSignOut('Logout manteniendo dispositivo', keepDeviceInfo: true),
              child: const Text('Cerrar manteniendo dispositivo'),
            ),
            const SizedBox(height: 20),

            // SignOut completo (elimina todo)
            const CompleteSignOutButton(
              reason: 'Ejemplo de eliminación completa',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilities() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Utilidades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Botones de utilidad
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _simulateLogin(),
                  icon: const Icon(Icons.login),
                  label: const Text('Simular Login'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _refreshUserInfo(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refrescar Info'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _clearError(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar Error'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDeviceInfo(),
                  icon: const Icon(Icons.info),
                  label: const Text('Info Dispositivo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Logs de Actividad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Los logs se registran automáticamente en:\n'
              '• Consola de desarrollo\n'
              '• Archivos de log del sistema\n'
              '• Logger con niveles (DEBUG, INFO, WARNING, ERROR)\n\n'
              'Eventos registrados:\n'
              '• Inicio de signOut\n'
              '• Limpieza de datos sensibles\n'
              '• Verificación de limpieza\n'
              '• Completado exitoso\n'
              '• Errores y recuperación',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos de utilidad
  void _simulateLogin() {
    // Aquí simularías un login real
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Para simular login, implementa el método signIn()'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _handleCustomSignOut(String message, {bool clearAllData = false, bool keepDeviceInfo = false}) async {
    try {
      await ref.read(secureAuthNotifierProvider.notifier).signOut(
        clearAllData: clearAllData,
        keepDeviceInfo: keepDeviceInfo,
        customLogMessage: message,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SignOut completado: $message'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en signOut: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshUserInfo() {
    ref.read(secureAuthNotifierProvider.notifier).refreshUserInfo();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Información de usuario refrescada'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearError() {
    ref.read(secureAuthNotifierProvider.notifier).clearError();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error limpiado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeviceInfo() async {
    final secureSignOutService = ref.read(secureSignOutServiceProvider);
    final deviceId = await secureSignOutService.getCurrentDeviceId();
    final userInfo = await secureSignOutService.getStoredUserInfo();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Información del Dispositivo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device ID: ${deviceId ?? 'No disponible'}'),
              const SizedBox(height: 8),
              if (userInfo.isNotEmpty) ...[
                const Text('Usuario Info:'),
                ...userInfo.entries.map((e) => Text('  ${e.key}: ${e.value}')),
              ] else
                const Text('No hay información de usuario'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }
}

/// Widget personalizado para botón con child
class CustomSignOutButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const CustomSignOutButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: child,
    );
  }
}
