import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';
import 'auto_register_screen.dart';

class AutoLoginScreen extends ConsumerStatefulWidget {
  const AutoLoginScreen({super.key});

  @override
  ConsumerState<AutoLoginScreen> createState() => _AutoLoginScreenState();
}

class _AutoLoginScreenState extends ConsumerState<AutoLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    Logger.debug('🖥️ LOGIN DEBUG: Botón de login presionado', 'AutoLoginScreen');
    
    if (!_formKey.currentState!.validate()) {
      Logger.warning('❌ LOGIN DEBUG: Validación del formulario falló', 'AutoLoginScreen');
      return;
    }

    Logger.debug('✅ LOGIN DEBUG: Validación del formulario exitosa', 'AutoLoginScreen');

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    Logger.debug('📝 LOGIN DEBUG: Email: $email', 'AutoLoginScreen');
    Logger.debug('🔒 LOGIN DEBUG: Password: ${password.isNotEmpty ? "***" : "EMPTY"}', 'AutoLoginScreen');

    await ref.read(authProvider.notifier).signIn(
      email,
      password,
    );

    Logger.debug('🔄 LOGIN DEBUG: SignIn completado, verificando estado', 'AutoLoginScreen');

    // Esperar un momento para que el estado se actualice
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && ref.read(authProvider).isAuthenticated) {
      Logger.info('🎉 LOGIN DEBUG: Login exitoso, navegando al dashboard', 'AutoLoginScreen');
      // Navegar al dashboard o pantalla principal
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Logger.warning('😞 LOGIN DEBUG: Login falló, error ya mostrado en UI', 'AutoLoginScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: const Color(0xFF1E5AA8),
        foregroundColor: Colors.white,
        actions: [
          if (authState.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authProvider.notifier).clearError();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Logo o título
              const Icon(
                Icons.lock_person,
                size: 80,
                color: Color(0xFF1E5AA8),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Bienvenido',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E5AA8),
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                'Ingrese sus credenciales para acceder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese su email';
                  }
                  if (!value.contains('@')) {
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
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Mensaje de error
              if (authState.error != null) ...[
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
                const SizedBox(height: 16),
              ],

              // Botón de login
              SizedBox(
                height: 40.h,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar Sesión'),
                ),
              ),
              const SizedBox(height: 32),

              // Enlaces
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // NOTE: Password recovery functionality to be implemented
                    },
                    child: const Text(
                      '¿Olvidó su contraseña?',
                      style: TextStyle(color: Color(0xFF1E5AA8)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AutoRegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(color: Color(0xFF1E5AA8)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Información del sistema
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Inicio de sesión seguro con validación de credenciales',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
