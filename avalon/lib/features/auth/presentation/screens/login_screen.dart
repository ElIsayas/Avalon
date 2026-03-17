import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/layout/responsive.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure       = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signIn(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: context.isDesktop
          ? _DesktopLogin(
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              passwordCtrl: _passwordCtrl,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
              state: state,
            )
          : _MobileLogin(
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              passwordCtrl: _passwordCtrl,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
              state: state,
            ),
    );
  }
}

// ── MOBILE (igual que antes) ──────────────────────────────────────────────────
class _MobileLogin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure, onSubmit;
  final dynamic state;

  const _MobileLogin({
    required this.formKey, required this.emailCtrl, required this.passwordCtrl,
    required this.obscure, required this.onToggleObscure, required this.onSubmit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80.w, height: 80.w,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(Icons.psychology, color: Colors.white, size: 44.sp),
              ),
              SizedBox(height: 24.h),
              Text('Avalon',
                  style: GoogleFonts.inter(fontSize: 32.sp,
                      fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              SizedBox(height: 4.h),
              Text('Gestión psicológica',
                  style: GoogleFonts.inter(fontSize: 15.sp, color: AppTheme.textGrey)),
              SizedBox(height: 40.h),
              _LoginForm(
                formKey: formKey, emailCtrl: emailCtrl, passwordCtrl: passwordCtrl,
                obscure: obscure, onToggleObscure: onToggleObscure,
                onSubmit: onSubmit, state: state,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DESKTOP — panel izquierdo de marca + formulario centrado ──────────────────
class _DesktopLogin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure, onSubmit;
  final dynamic state;

  const _DesktopLogin({
    required this.formKey, required this.emailCtrl, required this.passwordCtrl,
    required this.obscure, required this.onToggleObscure, required this.onSubmit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Panel izquierdo — marca ─────────────────────────────────
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.psychology, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 28),
                  Text('Avalon',
                      style: GoogleFonts.inter(fontSize: 40,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Plataforma de gestión psicológica',
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 48),
                  // Features
                  ...[
                    ('Gestión de pacientes y expedientes', Icons.people_outline),
                    ('Agenda de citas inteligente',        Icons.calendar_today_outlined),
                    ('Notas de sesión y evaluaciones',     Icons.note_outlined),
                    ('Recordatorios y seguimiento',        Icons.notifications_outlined),
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$2, color: Colors.white70, size: 18),
                        const SizedBox(width: 10),
                        Text(item.$1,
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),

        // ── Panel derecho — formulario ──────────────────────────────
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenido',
                        style: GoogleFonts.inter(fontSize: 28,
                            fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 6),
                    Text('Ingresa tus credenciales para continuar',
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textGrey)),
                    const SizedBox(height: 36),
                    _LoginForm(
                      formKey: formKey, emailCtrl: emailCtrl,
                      passwordCtrl: passwordCtrl, obscure: obscure,
                      onToggleObscure: onToggleObscure, onSubmit: onSubmit,
                      state: state,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── FORMULARIO compartido ─────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure, onSubmit;
  final dynamic state;

  const _LoginForm({
    required this.formKey, required this.emailCtrl, required this.passwordCtrl,
    required this.obscure, required this.onToggleObscure, required this.onSubmit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu email';
              if (!v.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordCtrl,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              return null;
            },
          ),

          if (state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.error!,
                      style: TextStyle(color: AppTheme.error, fontSize: 13)),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : onSubmit,
              child: state.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('Iniciar sesión',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
