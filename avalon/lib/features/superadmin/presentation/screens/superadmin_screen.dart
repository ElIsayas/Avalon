import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/superadmin_provider.dart';
import '../../data/superadmin_service.dart';
import 'pasarelas_tab.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/string_utils.dart';

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).cargarTodo();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);

    ref.listen(superAdminProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(next.successMessage!),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(superAdminProvider.notifier).clearMessages();
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(next.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(superAdminProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(children: [
          Text('âš¡ ', style: TextStyle(fontSize: 18.sp)),
          Text('Consola Superadmin',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(superAdminProvider.notifier).cargarTodo();
              if (_tabs.index == 2) {
                ref.read(superAdminProvider.notifier).cargarUsuarios();
              }
              if (_tabs.index == 3) {
                ref.read(superAdminProvider.notifier).cargarPagos();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(
                icon: Icon(Icons.dashboard_outlined, size: 18),
                text: 'MÃ©tricas'),
            Tab(icon: Icon(Icons.business_outlined, size: 18), text: 'Orgs'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Usuarios'),
            Tab(
                icon: Icon(Icons.receipt_long_outlined, size: 18),
                text: 'Pagos'),
            Tab(
                icon: Icon(Icons.credit_card_outlined, size: 18),
                text: 'Pasarelas'),
          ],
          onTap: (i) {
            if (i == 1 && state.organizaciones.isEmpty) {
              ref.read(superAdminProvider.notifier).cargarTodo();
            }
            if (i == 2 && state.usuarios.isEmpty) {
              ref.read(superAdminProvider.notifier).cargarUsuarios();
            }
            if (i == 3 && state.pagos.isEmpty) {
              ref.read(superAdminProvider.notifier).cargarPagos();
            }
          },
        ),
      ),
      body: state.isLoading && state.metricas == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _MetricasTab(metricas: state.metricas),
                _OrgsTab(orgs: state.organizaciones),
                _UsuariosTab(
                    usuarios: state.usuarios, orgs: state.organizaciones),
                _PagosTab(pagos: state.pagos),
                PasarelasTab(organizaciones: state.organizaciones),
              ],
            ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB MÃ‰TRICAS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _MetricasTab extends StatelessWidget {
  final SaMetricas? metricas;
  const _MetricasTab({this.metricas});

  @override
  Widget build(BuildContext context) {
    if (metricas == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final m = metricas!;
    final fmt = NumberFormat('#,###', 'es_CO');

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas principales
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard('Organizaciones', m.totalOrgs.toString(),
                  '${m.orgsActivas} activas', Icons.business, AppTheme.primary),
              _MetricCard('Usuarios', m.totalUsuarios.toString(), 'activos',
                  Icons.people, AppTheme.secondary),
              _MetricCard('Pacientes', m.totalPacientes.toString(),
                  'registrados', Icons.person_outline, AppTheme.accent),
              _MetricCard('Pagos del mes', m.pagosMes.toString(),
                  'transacciones', Icons.credit_card, AppTheme.warning),
            ],
          ),
          SizedBox(height: 16.h),

          // Ingresos
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingresos del mes',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 12.sp)),
                    SizedBox(height: 4.h),
                    Text('\$${fmt.format(m.ingresosMes)} COP',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold)),
                  ],
                )),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingresos totales',
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 12.sp)),
                    SizedBox(height: 4.h),
                    Text('\$${fmt.format(m.ingresoTotal)} COP',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600)),
                  ],
                )),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Orgs por plan
          if (m.orgsPorPlan.isNotEmpty) ...[
            Text('DistribuciÃ³n por plan',
                style: GoogleFonts.inter(
                    fontSize: 14.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            ...m.orgsPorPlan.map((p) => _PlanBar(
                  plan: p['plan']?.toString() ?? '',
                  cantidad: (p['cantidad'] as num?)?.toInt() ?? 0,
                  total: m.totalOrgs,
                )),
            SizedBox(height: 16.h),
          ],

          // Ãšltimos pagos
          if (m.ultimosPagos.isNotEmpty) ...[
            Text('Ãšltimos pagos',
                style: GoogleFonts.inter(
                    fontSize: 14.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            ...m.ultimosPagos.map((p) => _UltimoPagoRow(pago: p)),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _MetricCard(this.label, this.value, this.sub, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22.sp),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              Text('$label Â· $sub',
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: AppTheme.textGrey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanBar extends StatelessWidget {
  final String plan;
  final int cantidad, total;
  const _PlanBar(
      {required this.plan, required this.cantidad, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? cantidad / total : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(children: [
        SizedBox(
            width: 80.w,
            child: Text(plan, style: GoogleFonts.inter(fontSize: 12.sp))),
        Expanded(
            child: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: pct.toDouble(),
            minHeight: 8.h,
            backgroundColor: AppTheme.divider,
            color: AppTheme.primary,
          ),
        )),
        SizedBox(width: 8.w),
        Text('$cantidad',
            style: GoogleFonts.inter(
                fontSize: 12.sp, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _UltimoPagoRow extends StatelessWidget {
  final Map<String, dynamic> pago;
  const _UltimoPagoRow({required this.pago});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'es_CO');
    final monto = double.tryParse(pago['monto'].toString()) ?? 0;
    final fecha = pago['fecha'] != null
        ? DateFormat('dd/MM/yy')
            .format(DateTime.parse(pago['fecha'].toString()))
        : 'â€”';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(children: [
        Expanded(
            child: Text(pago['org']?.toString() ?? 'â€”',
                style: GoogleFonts.inter(fontSize: 13.sp))),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(pago['plan']?.toString() ?? 'â€”',
              style:
                  GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.primary)),
        ),
        SizedBox(width: 8.w),
        Text('\$${fmt.format(monto)}',
            style: GoogleFonts.inter(
                fontSize: 12.sp, fontWeight: FontWeight.w600)),
        SizedBox(width: 8.w),
        Text(fecha,
            style:
                GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.textGrey)),
      ]),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB ORGANIZACIONES
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _OrgsTab extends ConsumerWidget {
  final List<SaOrganizacion> orgs;
  const _OrgsTab({required this.orgs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearOrgDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva org'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: orgs.isEmpty
          ? Center(
              child: Text('No hay organizaciones',
                  style: GoogleFonts.inter(color: AppTheme.textGrey)))
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r, 80.r),
              itemCount: orgs.length,
              itemBuilder: (_, i) => _OrgCard(org: orgs[i]),
            ),
    );
  }

  void _showCrearOrgDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva organizaciÃ³n'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(superAdminProvider.notifier)
                  .crearOrganizacion(ctrl.text.trim());
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

class _OrgCard extends ConsumerWidget {
  final SaOrganizacion org;
  const _OrgCard({required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,###', 'es_CO');

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: org.activa
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.textGrey.withValues(alpha: 0.1),
          child: Icon(Icons.business,
              color: org.activa ? AppTheme.primary : AppTheme.textGrey,
              size: 20.sp),
        ),
        title: Row(children: [
          Expanded(
              child: Text(org.nombre,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 14.sp))),
          _PlanBadge(org.planNombre),
        ]),
        subtitle: Text(
          '${org.totalUsuarios} usuarios Â· ${org.totalPacientes} pacientes'
          '${org.vencida ? " Â· âš ï¸ VENCIDA" : ""}',
          style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: org.vencida ? AppTheme.error : AppTheme.textGrey),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.r, 0, 16.r, 12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (org.fechaVencimiento != null)
                  _InfoRow('Vence',
                      DateFormat('dd/MM/yyyy').format(org.fechaVencimiento!)),
                if (org.maxCustom != null)
                  _InfoRow('LÃ­mite custom', '${org.maxCustom} usuarios'),
                _InfoRow(
                    'Ingresos totales', '\$${fmt.format(org.ingresos)} COP'),
                if (org.fechaCreacion != null)
                  _InfoRow('Creada',
                      DateFormat('dd/MM/yyyy').format(org.fechaCreacion!)),
                SizedBox(height: 12.h),
                Wrap(spacing: 8.w, runSpacing: 8.h, children: [
                  _ActionBtn(
                    label: org.activa ? 'Desactivar' : 'Activar',
                    icon: org.activa ? Icons.block : Icons.check_circle_outline,
                    color: org.activa ? AppTheme.error : AppTheme.accent,
                    onTap: () => ref
                        .read(superAdminProvider.notifier)
                        .editarOrganizacion(org.id, activa: !org.activa),
                  ),
                  _ActionBtn(
                    label: 'Cambiar plan',
                    icon: Icons.upgrade,
                    color: AppTheme.primary,
                    onTap: () => _showCambiarPlanDialog(context, ref),
                  ),
                  if (org.planNombre == 'ilimitado')
                    _ActionBtn(
                      label: 'LÃ­mite usuarios',
                      icon: Icons.tune,
                      color: AppTheme.warning,
                      onTap: () => _showLimitePlatinumDialog(context, ref),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCambiarPlanDialog(BuildContext context, WidgetRef ref) {
    String planSeleccionado = org.planNombre;
    DateTime? vencimiento =
        org.fechaVencimiento ?? DateTime.now().add(const Duration(days: 30));
    int? maxCustom = org.maxCustom;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Cambiar plan â€” ${org.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: planSeleccionado,
                decoration: const InputDecoration(labelText: 'Plan'),
                items: [
                  'inicio',
                  'starter',
                  'profesional',
                  'clinica',
                  'corporativo',
                  'ilimitado'
                ]
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => planSeleccionado = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: vencimiento ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => vencimiento = picked);
                },
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Fecha vencimiento'),
                  child: Text(vencimiento != null
                      ? DateFormat('dd/MM/yyyy').format(vencimiento!)
                      : 'Sin vencimiento'),
                ),
              ),
              if (planSeleccionado == 'ilimitado') ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: maxCustom?.toString() ?? '30',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'LÃ­mite usuarios (ilimitado)'),
                  onChanged: (v) => maxCustom = int.tryParse(v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(superAdminProvider.notifier).cambiarPlan(
                      org.id,
                      planSeleccionado,
                      vencimiento: vencimiento,
                      maxCustom:
                          planSeleccionado == 'ilimitado' ? maxCustom : null,
                    );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLimitePlatinumDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: org.maxCustom?.toString() ?? '30');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajustar lÃ­mite Ilimitado'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: 'MÃ¡ximo de usuarios normales'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final n = int.tryParse(ctrl.text.trim());
              if (n == null || n < 1) return;
              Navigator.pop(ctx);
              await ref
                  .read(superAdminProvider.notifier)
                  .ajustarLimitePlatinum(org.id, n);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB USUARIOS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _UsuariosTab extends ConsumerStatefulWidget {
  final List<SaUsuario> usuarios;
  final List<SaOrganizacion> orgs;
  const _UsuariosTab({required this.usuarios, required this.orgs});

  @override
  ConsumerState<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends ConsumerState<_UsuariosTab> {
  String? _filtroOrgId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).cargarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = _filtroOrgId == null
        ? widget.usuarios
        : widget.usuarios
            .where((u) => u.organizacionId == _filtroOrgId)
            .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearUsuarioDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo usuario'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtro por org
          Padding(
            padding: EdgeInsets.fromLTRB(16.r, 12.r, 16.r, 0),
            child: DropdownButtonFormField<String?>(
              initialValue: _filtroOrgId,
              decoration: InputDecoration(
                labelText: 'Filtrar por organizaciÃ³n',
                prefixIcon: const Icon(Icons.filter_list),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...widget.orgs.map((o) =>
                    DropdownMenuItem(value: o.id, child: Text(o.nombre))),
              ],
              onChanged: (v) {
                setState(() => _filtroOrgId = v);
                ref.read(superAdminProvider.notifier).cargarUsuarios(orgId: v);
              },
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: usuarios.isEmpty
                ? Center(
                    child: Text('No hay usuarios',
                        style: GoogleFonts.inter(color: AppTheme.textGrey)))
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.r, 4.r, 16.r, 80.r),
                    itemCount: usuarios.length,
                    itemBuilder: (_, i) => _UsuarioCard(usuario: usuarios[i]),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCrearUsuarioDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String rol = 'psicologo';
    String? orgId =
        _filtroOrgId ?? (widget.orgs.isNotEmpty ? widget.orgs.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nuevo usuario'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: orgId,
                decoration: const InputDecoration(labelText: 'OrganizaciÃ³n'),
                items: widget.orgs
                    .map((o) => DropdownMenuItem<String>(
                        value: o.id, child: Text(o.nombre)))
                    .toList(),
                onChanged: (v) => setState(() => orgId = v),
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 10),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'ContraseÃ±a'),
                  obscureText: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: ['admin', 'psicologo', 'secretaria', 'superadmin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => rol = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (orgId == null ||
                    nombreCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty ||
                    passCtrl.text.isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                await ref.read(superAdminProvider.notifier).crearUsuario(
                      orgId: orgId!,
                      nombre: nombreCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text,
                      rol: rol,
                    );
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsuarioCard extends ConsumerWidget {
  final SaUsuario usuario;
  const _UsuarioCard({required this.usuario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: usuario.activa
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.textGrey.withValues(alpha: 0.1),
          child: Text(usuario.nombre.iniciales,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color:
                      usuario.activa ? AppTheme.primary : AppTheme.textGrey)),
        ),
        title: Row(children: [
          Expanded(
              child: Text(usuario.nombre,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13.sp))),
          _RolBadge(usuario.rol),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.email,
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: AppTheme.textGrey)),
            Text(usuario.organizacion,
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: AppTheme.primary)),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'toggle') {
              await ref
                  .read(superAdminProvider.notifier)
                  .editarUsuario(usuario.id, activa: !usuario.activa);
            } else if (v == 'editar') {
              _showEditarDialog(context, ref);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'editar',
                child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                    dense: true)),
            PopupMenuItem(
                value: 'toggle',
                child: ListTile(
                  leading: Icon(usuario.activa
                      ? Icons.block
                      : Icons.check_circle_outline),
                  title: Text(usuario.activa ? 'Desactivar' : 'Activar'),
                  dense: true,
                )),
          ],
        ),
      ),
    );
  }

  void _showEditarDialog(BuildContext context, WidgetRef ref) {
    final nombreCtrl = TextEditingController(text: usuario.nombre);
    final passCtrl = TextEditingController();
    String rol = usuario.rol;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Editar â€” ${usuario.nombre}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: rol,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: ['admin', 'psicologo', 'secretaria', 'superadmin']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => rol = v!),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                    labelText:
                        'Nueva contraseÃ±a (dejar vacÃ­o para no cambiar)'),
                obscureText: true),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(superAdminProvider.notifier).editarUsuario(
                      usuario.id,
                      nombre: nombreCtrl.text.trim(),
                      rol: rol,
                      nuevaPassword:
                          passCtrl.text.isNotEmpty ? passCtrl.text : null,
                    );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB PAGOS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _PagosTab extends ConsumerStatefulWidget {
  final List<SaPago> pagos;
  const _PagosTab({required this.pagos});

  @override
  ConsumerState<_PagosTab> createState() => _PagosTabState();
}

class _PagosTabState extends ConsumerState<_PagosTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).cargarPagos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'es_CO');
    if (widget.pagos.isEmpty) {
      return Center(
          child: Text('No hay pagos registrados',
              style: GoogleFonts.inter(color: AppTheme.textGrey)));
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: widget.pagos.length,
      itemBuilder: (_, i) {
        final p = widget.pagos[i];
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
              child:
                  Icon(Icons.credit_card, color: AppTheme.accent, size: 18.sp),
            ),
            title: Row(children: [
              Expanded(
                  child: Text(p.orgNombre,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 13.sp))),
              Text('\$${fmt.format(p.monto)}',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: AppTheme.accent)),
            ]),
            subtitle: Text(
              '${p.planNombre} Â· ${p.pasarela} Â· '
              '${p.fechaPago != null ? DateFormat('dd/MM/yy').format(p.fechaPago!) : "â€”"}',
              style:
                  GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.textGrey),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: p.estado == 'completado'
                    ? AppTheme.accent.withValues(alpha: 0.1)
                    : AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(p.estado,
                  style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: p.estado == 'completado'
                          ? AppTheme.accent
                          : AppTheme.error)),
            ),
          ),
        );
      },
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// WIDGETS HELPERS COMPARTIDOS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _PlanBadge extends StatelessWidget {
  final String plan;
  const _PlanBadge(this.plan);

  Color get color {
    switch (plan) {
      case 'ilimitado':
        return const Color(0xFF7C3AED);
      case 'corporativo':
        return const Color(0xFF0369A1);
      case 'clinica':
        return const Color(0xFF0891B2);
      case 'profesional':
        return const Color(0xFF059669);
      case 'starter':
        return const Color(0xFFD97706);
      case 'inicio':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get label {
    switch (plan) {
      case 'inicio':
        return 'Inicio';
      case 'starter':
        return 'Starter';
      case 'profesional':
        return 'Profesional';
      case 'clinica':
        return 'Clinica';
      case 'corporativo':
        return 'Corporativo';
      case 'ilimitado':
        return 'Ilimitado';
      default:
        return plan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10.sp, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge(this.rol);

  @override
  Widget build(BuildContext context) {
    final colors = {
      'superadmin': const Color(0xFF7C3AED),
      'admin': const Color(0xFFD97706),
      'psicologo': const Color(0xFF0369A1),
      'secretaria': const Color(0xFF059669),
    };
    final c = colors[rol] ?? const Color(0xFF6B7280);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5.r)),
      child: Text(rol,
          style: GoogleFonts.inter(
              fontSize: 9.sp, color: c, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(children: [
        SizedBox(
            width: 100.w,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: AppTheme.textGrey))),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 12.sp, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14.sp, color: color),
      label:
          Text(label, style: GoogleFonts.inter(fontSize: 12.sp, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }
}
