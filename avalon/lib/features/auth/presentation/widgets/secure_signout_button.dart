import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/secure_auth_provider.dart';

/// Widget de botón de cierre de sesión seguro
class SecureSignOutButton extends ConsumerWidget {
  final String? customMessage;
  final bool clearAllData;
  final bool keepDeviceInfo;
  final VoidCallback? onSignOutComplete;

  const SecureSignOutButton({
    super.key,
    this.customMessage,
    this.clearAllData = false,
    this.keepDeviceInfo = false,
    this.onSignOutComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(secureAuthNotifierProvider);
    final authNotifier = ref.read(secureAuthNotifierProvider.notifier);

    return ElevatedButton.icon(
      onPressed: authState.isLoading ? null : () => _handleSignOut(context, ref, authNotifier),
      icon: authState.isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.logout),
      label: Text(
        authState.isLoading ? 'Cerrando sesión...' : 'Cerrar Sesión',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(
    BuildContext context,
    WidgetRef ref,
    SecureAuthNotifier authNotifier,
  ) async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cierre de Sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que deseas cerrar sesión?'),
            const SizedBox(height: 16),
            if (clearAllData)
              const Text(
                '⚠️ Se eliminarán todos los datos locales del usuario.',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
              ),
            if (keepDeviceInfo)
              const Text(
                'ℹ️ Se conservará la información del dispositivo.',
                style: TextStyle(color: Colors.blue),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Ejecutar signOut seguro
      await authNotifier.signOut(
        clearAllData: clearAllData,
        keepDeviceInfo: keepDeviceInfo,
        customLogMessage: customMessage,
      );

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Ejecutar callback si existe
      onSignOutComplete?.call();

      // Navegar al login (esto depende de tu estructura de navegación)
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Mostrar mensaje de error (aunque el signOut debería completarse)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error durante el cierre de sesión: $e'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Widget de botón para cierre de sesión completo (limpia todo)
class CompleteSignOutButton extends ConsumerWidget {
  final String? reason;
  final VoidCallback? onSignOutComplete;

  const CompleteSignOutButton({
    super.key,
    this.reason,
    this.onSignOutComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(secureAuthNotifierProvider.notifier);

    return ElevatedButton.icon(
      onPressed: () => _handleCompleteSignOut(context, authNotifier),
      icon: const Icon(Icons.delete_forever),
      label: const Text('Eliminar Todos los Datos'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _handleCompleteSignOut(
    BuildContext context,
    SecureAuthNotifier authNotifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Todos los Datos'),
        content: const Text(
          '¿Estás seguro? Esta acción eliminará:\n'
          '• Todos los datos de sesión\n'
          '• Información del usuario\n'
          '• Configuraciones guardadas\n'
          '• Datos del dispositivo\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await authNotifier.signOutCompletely(reason: reason);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los datos han sido eliminados'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }

      onSignOutComplete?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error eliminando datos: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Widget que muestra información de la sesión actual
class SessionInfoWidget extends ConsumerWidget {
  const SessionInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(secureAuthNotifierProvider);

    if (!authState.isAuthenticated) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay sesión activa'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Sesión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (authState.userInfo != null) ...[
              _buildInfoRow('Email', authState.userInfo!['email']),
              _buildInfoRow('Device ID', authState.userInfo!['device_id']),
              _buildInfoRow('Último Login', authState.userInfo!['last_login']),
            ],
            if (authState.deviceId != null)
              _buildInfoRow('Device ID Actual', authState.deviceId!),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                const Text('Sesión Activa'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
