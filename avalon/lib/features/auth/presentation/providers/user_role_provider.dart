import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../../../../core/utils/logger.dart';

// Provider para verificar si el usuario es administrador
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user?.isAdministrador ?? false;
});

// Provider para verificar si el usuario es psicólogo (rol normal)
final isPsicologoProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user?.isPsicologo ?? false;
});

// Provider para obtener el rol del usuario como string
final userRoleProvider = Provider<String>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user?.rol ?? 'unknown';
});

// Provider para obtener información del rol formateada
final userRoleInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  
  Logger.debug('🔐 ROLE DEBUG: User object: $user', 'UserRoleProvider');
  Logger.debug('🔐 ROLE DEBUG: User role: ${user?.rol}', 'UserRoleProvider');
  Logger.debug('🔐 ROLE DEBUG: Is admin: ${user?.isAdministrador}', 'UserRoleProvider');
  Logger.debug('🔐 ROLE DEBUG: Is psicologo: ${user?.isPsicologo}', 'UserRoleProvider');
  
  if (user == null) {
    return {
      'role': 'unknown',
      'displayName': 'Usuario no identificado',
      'isAdmin': false,
      'isPsicologo': false,
      'color': 'grey',
      'icon': Icons.person,
    };
  }

  switch (user.rol) {
    case 'admin':
    case 'administrador':
      return {
        'role': user.rol, // Keep the original role
        'displayName': 'Administrador',
        'isAdmin': true,
        'isPsicologo': false,
        'color': 'red',
        'icon': Icons.admin_panel_settings,
      };
    case 'psicologo':
    case 'user':
      return {
        'role': user.rol, // Keep the original role ('psicologo' or 'user')
        'displayName': 'Psicólogo',
        'isAdmin': false,
        'isPsicologo': true,
        'color': 'blue',
        'icon': Icons.psychology,
      };
    default:
      return {
        'role': 'unknown',
        'displayName': 'Usuario',
        'isAdmin': false,
        'isPsicologo': false,
        'color': 'grey',
        'icon': Icons.person,
      };
  }
});
