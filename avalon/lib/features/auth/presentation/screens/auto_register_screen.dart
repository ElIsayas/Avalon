import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';
import 'auto_login_screen.dart';

class AutoRegisterScreen extends ConsumerStatefulWidget {
  const AutoRegisterScreen({super.key});

  @override
  ConsumerState<AutoRegisterScreen> createState() => _AutoRegisterScreenState();
}

class _AutoRegisterScreenState extends ConsumerState<AutoRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    Logger.debug('🖥️ UI DEBUG: Botón de registro presionado', 'AutoRegisterScreen');
    
    if (!_formKey.currentState!.validate()) {
      Logger.warning('❌ UI DEBUG: Validación del formulario falló', 'AutoRegisterScreen');
      return;
    }

    Logger.info('✅ UI DEBUG: Validación del formulario exitosa', 'AutoRegisterScreen');

    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    // Opcional: obtener device_id del dispositivo
    String? deviceId;
    try {
      // Aquí podrías obtener el device_id real si lo necesitas
      // deviceId = await _getDeviceId();
      deviceId = null; // Por ahora null
    } catch (e) {
      Logger.warning('⚠️ UI DEBUG: No se pudo obtener device_id: $e', 'AutoRegisterScreen');
      deviceId = null;
    }

    Logger.debug('📝 UI DEBUG: Datos del formulario - Nombre: $nombre, Email: $email, Password: ${password.isNotEmpty ? "***" : "EMPTY"}', 'AutoRegisterScreen');
    Logger.debug('📱 UI DEBUG: Device ID: ${deviceId ?? "NO PROPORCIONADO"}', 'AutoRegisterScreen');

    await ref.read(authProvider.notifier).signUp(
      email: email,
      password: password,
      nombre: nombre,
      licenseKey: '', // Licencia vacía por ahora
    );

    Logger.debug('📊 UI DEBUG: Registro completado, verificando estado', 'AutoRegisterScreen');

    // Esperar un momento para que el estado se actualice
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && ref.read(authProvider).isAuthenticated) {
      Logger.info('🎉 UI DEBUG: Registro exitoso, mostrando SnackBar y navegando', 'AutoRegisterScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Usuario registrado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navegar al login o dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Logger.warning('😞 UI DEBUG: Registro falló, error ya mostrado en UI', 'AutoRegisterScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: const Color(0xFF1E5AA8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Logo o título
              const Icon(
                Icons.person_add,
                size: 80,
                color: Color(0xFF1E5AA8),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Crear Cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E5AA8),
                ),
              ),
              const SizedBox(height: 8),
              
              // Mensaje simple sin mencionar licencias
              const Text(
                'Complete sus datos para registrarse',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese su nombre';
                  }
                  if (value.length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (opcional según el requisito)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  helperText: 'Puede dejar este campo vacío',
                ),
                validator: (value) {
                  // Email es opcional, pero si se ingresa debe ser válido
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese su contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme su contraseña';
                  }
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón de registro simple
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Crear Cuenta'),
                ),
              ),

              // Mensaje de error
              if (authState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Enlace al login
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AutoLoginScreen()),
                    );
                  },
                  child: const Text(
                    '¿Ya tiene cuenta? Inicie sesión',
                    style: TextStyle(color: Color(0xFF1E5AA8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
