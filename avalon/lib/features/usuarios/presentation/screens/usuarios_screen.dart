import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../domain/usuario_org.dart';
import '../providers/usuarios_org_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});

  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  String? _filtroRol;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usuariosOrgProvider.notifier).cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuariosOrgProvider);
    final currentUser = ref.watch(currentUserProvider);
    final esAdmin = currentUser?.puedeGestionarUsuarios ?? false;
    final puedeCrear = esAdmin && !state.limiteAlcanzado;

    final usuarios = _filtroRol == null
        ? state.usuarios
        : state.usuarios.where((u) => u.rol == _filtroRol).toList();

    ref.listen(usuariosOrgProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(next.successMessage!),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(usuariosOrgProvider.notifier).clearMessages();
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(next.error!),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(usuariosOrgProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.equipoConsultorio),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usuariosOrgProvider.notifier).cargar(),
          ),
        ],
      ),
      body: ResponsiveBody(
        maxWidth: kDesktopContentMaxWidth,
        child: Column(
          children: [
            _StatsBar(state: state),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _RolChip('Todos', null, _filtroRol,
                        (v) => setState(() => _filtroRol = v)),
                    _RolChip('Psicologos', 'psicologo', _filtroRol,
                        (v) => setState(() => _filtroRol = v)),
                    _RolChip('Secretarias', 'secretaria', _filtroRol,
                        (v) => setState(() => _filtroRol = v)),
                    _RolChip('Admins', 'admin', _filtroRol,
                        (v) => setState(() => _filtroRol = v)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : usuarios.isEmpty
                      ? _Empty(
                          esAdmin: esAdmin,
                          puedeCrear: puedeCrear,
                          onCrear: _showCrearDialog,
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.read(usuariosOrgProvider.notifier).cargar(),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 4.h),
                            itemCount: usuarios.length,
                            itemBuilder: (_, i) => _UsuarioCard(
                              usuario: usuarios[i],
                              currentUserId: currentUser?.id ?? '',
                              esAdmin: esAdmin,
                              onEditar: () => _showEditarDialog(usuarios[i]),
                              onToggle: () => ref
                                  .read(usuariosOrgProvider.notifier)
                                  .editar(usuarios[i].id,
                                      activa: !usuarios[i].activa),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: esAdmin
          ? FloatingActionButton.extended(
              onPressed: puedeCrear ? _showCrearDialog : null,
              icon: const Icon(Icons.person_add),
              label: Text(context.t.nuevoUsuario),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showCrearDialog() {
    final state = ref.read(usuariosOrgProvider);
    if (state.limiteAlcanzado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(_planLimitMsg(state)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => _FormUsuario(
        onGuardar: (datos) async {
          final ok = await ref.read(usuariosOrgProvider.notifier).crear(
                nombre: datos['nombre']!,
                email: datos['email']!,
                password: datos['password']!,
                rol: datos['rol']!,
                especialidad: datos['especialidad'],
              );
          if (ok && mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditarDialog(UsuarioOrg usuario) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => _FormUsuario(
        usuario: usuario,
        onGuardar: (datos) async {
          final ok = await ref.read(usuariosOrgProvider.notifier).editar(
                usuario.id,
                nombre: datos['nombre'],
                rol: datos['rol'],
                especialidad: datos['especialidad'],
                nuevaPassword: datos['password']?.isNotEmpty == true
                    ? datos['password']
                    : null,
              );
          if (ok && mounted) Navigator.pop(context);
        },
      ),
    );
  }

  String _planLimitMsg(UsuariosOrgState state) {
    if (state.esPlanIlimitado) return 'Plan ilimitado activo';
    return 'Limite de usuarios alcanzado (${state.usuariosUsados}/${state.limiteUsuarios})';
  }
}

class _StatsBar extends StatelessWidget {
  final UsuariosOrgState state;
  const _StatsBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final usados = state.usuariosUsados;
    final limite = state.limiteUsuarios;
    final ratio = state.esPlanIlimitado || limite <= 0
        ? 0.0
        : (usados / limite).clamp(0.0, 1.0);

    return Container(
      color: Theme.of(context).cardColor,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(
                  'Total', state.usuarios.length.toString(), AppTheme.primary),
              SizedBox(width: 12.w),
              _Stat('Activos', state.totalActivos.toString(), AppTheme.accent),
              SizedBox(width: 12.w),
              _Stat('Psicologos', state.totalPsicologos.toString(),
                  AppTheme.secondary),
              SizedBox(width: 12.w),
              _Stat('Secretarias', state.totalSecretarias.toString(),
                  AppTheme.warning),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            state.esPlanIlimitado
                ? 'Plan usuarios: Ilimitado'
                : 'Plan usuarios: $usados / $limite',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: state.limiteAlcanzado ? AppTheme.error : AppTheme.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!state.esPlanIlimitado && limite > 0) ...[
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6.h,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation(
                  state.limiteAlcanzado ? AppTheme.error : AppTheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
          SizedBox(width: 3.w),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.textGrey)),
        ],
      );
}

class _RolChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? selected;
  final ValueChanged<String?> onTap;

  const _RolChip(this.label, this.value, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(isSelected ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final UsuarioOrg usuario;
  final String currentUserId;
  final bool esAdmin;
  final VoidCallback onEditar;
  final VoidCallback onToggle;

  const _UsuarioCard({
    required this.usuario,
    required this.currentUserId,
    required this.esAdmin,
    required this.onEditar,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final esTuMismo = usuario.id == currentUserId;

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundColor: usuario.activa
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : AppTheme.textGrey.withValues(alpha: 0.1),
              child: Text(
                usuario.iniciales,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: usuario.activa ? AppTheme.primary : AppTheme.textGrey,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${usuario.nombre}${esTuMismo ? ' (tu)' : ''}',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14.sp),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _RolBadge(usuario.rol),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(usuario.email,
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: AppTheme.textGrey),
                      overflow: TextOverflow.ellipsis),
                  if (usuario.especialidad != null)
                    Text(usuario.especialidad!,
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: AppTheme.primary)),
                  if (usuario.ultimoLogin != null)
                    Text(
                      'Ultimo acceso: ${DateFormat('dd/MM/yy HH:mm').format(usuario.ultimoLogin!)}',
                      style: GoogleFonts.inter(
                          fontSize: 10.sp, color: AppTheme.textGrey),
                    ),
                ],
              ),
            ),
            if (esAdmin && !esTuMismo)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'editar') onEditar();
                  if (v == 'toggle') onToggle();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: ListTile(
                      leading: Icon(usuario.activa
                          ? Icons.person_off_outlined
                          : Icons.person_outlined),
                      title: Text(usuario.activa ? 'Desactivar' : 'Activar'),
                      dense: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge(this.rol);

  Color get _color {
    switch (rol) {
      case 'admin':
        return const Color(0xFFD97706);
      case 'psicologo':
        return AppTheme.primary;
      case 'secretaria':
        return const Color(0xFF059669);
      default:
        return AppTheme.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        rol,
        style: GoogleFonts.inter(
            fontSize: 10.sp, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool esAdmin;
  final bool puedeCrear;
  final VoidCallback onCrear;

  const _Empty({
    required this.esAdmin,
    required this.puedeCrear,
    required this.onCrear,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.people,
                size: 72.sp, color: AppTheme.textGrey.withValues(alpha: 0.3)),
            SizedBox(height: 16.h),
            Text('Sin usuarios',
                style: GoogleFonts.inter(
                    fontSize: 18.sp, color: AppTheme.textGrey)),
            if (esAdmin) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: puedeCrear ? onCrear : null,
                icon: const Icon(Icons.person_add),
                label: const Text('Anadir usuario'),
              ),
            ],
          ],
        ),
      );
}

class _FormUsuario extends StatefulWidget {
  final UsuarioOrg? usuario;
  final Future<void> Function(Map<String, String?>) onGuardar;

  const _FormUsuario({this.usuario, required this.onGuardar});

  @override
  State<_FormUsuario> createState() => _FormUsuarioState();
}

class _FormUsuarioState extends State<_FormUsuario> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _especialidadCtrl = TextEditingController();
  String _rol = 'psicologo';
  bool _obscure = true;
  bool _guardando = false;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final u = widget.usuario!;
      _nombreCtrl.text = u.nombre;
      _emailCtrl.text = u.email;
      _especialidadCtrl.text = u.especialidad ?? '';
      _rol = u.rol;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _especialidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20.w,
        right: 20.w,
        top: 20.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(
              _esEdicion ? context.t.editarUsuario : context.t.nuevoUsuario,
              style: GoogleFonts.inter(
                  fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _nombreCtrl,
              decoration: InputDecoration(
                labelText: '${context.t.nombreCompleto} *',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 14.h),
            if (!_esEdicion) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              SizedBox(height: 14.h),
            ],
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: _esEdicion
                    ? 'Nueva contrasena (dejar vacio para no cambiar)'
                    : 'Contrasena *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            DropdownButtonFormField<String>(
              initialValue: _rol,
              decoration: const InputDecoration(
                  labelText: 'Rol', prefixIcon: Icon(Icons.badge_outlined)),
              items: const [
                DropdownMenuItem(value: 'psicologo', child: Text('Psicologo')),
                DropdownMenuItem(
                    value: 'secretaria', child: Text('Secretaria')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (v) => setState(() => _rol = v!),
            ),
            SizedBox(height: 14.h),
            if (_rol == 'psicologo') ...[
              TextField(
                controller: _especialidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Especialidad (opcional)',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              SizedBox(height: 14.h),
            ],
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _esEdicion
                            ? context.t.guardarCambios
                            : context.t.crearUsuario,
                      ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('El nombre es obligatorio')),
      );
      return;
    }
    if (!_esEdicion && _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('El email es obligatorio')),
      );
      return;
    }
    if (!_esEdicion && _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('La contrasena es obligatoria')),
      );
      return;
    }

    setState(() => _guardando = true);
    await widget.onGuardar({
      'nombre': _nombreCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text.isEmpty ? null : _passCtrl.text,
      'rol': _rol,
      'especialidad': _especialidadCtrl.text.trim().isEmpty
          ? null
          : _especialidadCtrl.text.trim(),
    });
    setState(() => _guardando = false);
  }
}
