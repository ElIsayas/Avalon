import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/payment_service.dart';
import '../providers/payment_provider.dart';

class PagosScreen extends ConsumerStatefulWidget {
  const PagosScreen({super.key});

  @override
  ConsumerState<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends ConsumerState<PagosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).cargarTodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider);

    ref.listen(paymentProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
      }

      if (next.pagoDetectado && prev?.pagoDetectado != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('Pago confirmado. Tu plan ya fue actualizado.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.accent,
          ),
        );
        ref.read(paymentProvider.notifier).clearPagoMensajes();
      }

      if (next.retornoSinConfirmacion && prev?.retornoSinConfirmacion != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 5),
            content:
                Text('Regresaste a la app, pero no se confirmo un pago aun.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(paymentProvider.notifier).clearPagoMensajes();
      }
    });

    final planInfo = state.planInfo;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos y suscripciones'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.read(paymentProvider.notifier).cargarTodo(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveBody(
        maxWidth: 860,
        child: state.isLoading && planInfo == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(paymentProvider.notifier).cargarTodo(),
                child: ListView(
                  padding: EdgeInsets.all(16.r),
                  children: [
                    if (planInfo != null) _PlanActualCard(info: planInfo),
                    SizedBox(height: 14.h),
                    _PlanesSection(
                      planes: state.planes,
                      planActual: planInfo?.plan,
                      creandoPago: state.creandoPago,
                      onElegirPlan: (plan) =>
                          ref.read(paymentProvider.notifier).pagar(plan),
                    ),
                    SizedBox(height: 14.h),
                    _HistorialSection(
                      historial: state.historial,
                      onVerificar: () => ref
                          .read(paymentProvider.notifier)
                          .verificarPagoManual(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PlanActualCard extends StatelessWidget {
  final PlanInfo info;
  const _PlanActualCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final progreso = info.esIlimitado
        ? 0.0
        : (info.limiteUsuarios <= 0
            ? 0.0
            : info.usuariosUsados / info.limiteUsuarios);
    final progresoClamped = progreso.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    info.planLabel,
                    style: GoogleFonts.inter(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _vencimientoLabel(info),
                  style: GoogleFonts.inter(
                    color: AppTheme.textGrey,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              'Mi plan actual',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              info.esIlimitado
                  ? 'Usuarios: ${info.usuariosUsados} (sin limite)'
                  : 'Usuarios: ${info.usuariosUsados}/${info.limiteUsuarios}',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textGrey,
              ),
            ),
            SizedBox(height: 8.h),
            LinearProgressIndicator(
              value: info.esIlimitado ? null : progresoClamped.toDouble(),
              minHeight: 8.h,
              borderRadius: BorderRadius.circular(8.r),
              backgroundColor: AppTheme.divider,
              color: info.esIlimitado
                  ? AppTheme.primary
                  : _progressColor(progresoClamped),
            ),
            SizedBox(height: 8.h),
            Text(
              info.esIlimitado
                  ? 'Plan ilimitado sin tope de usuarios.'
                  : 'Disponibles: ${info.usuariosDisponibles}',
              style:
                  GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.textGrey),
            ),
            if (info.vencido || info.proximoAVencer) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: (info.vencido ? AppTheme.error : AppTheme.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: (info.vencido ? AppTheme.error : AppTheme.warning)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  info.vencido
                      ? 'Tu plan esta vencido. Realiza un pago para reactivar funciones.'
                      : 'Tu plan vence pronto (${info.diasRestantes ?? 0} dias).',
                  style: GoogleFonts.inter(
                    color: info.vencido ? AppTheme.error : AppTheme.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanesSection extends StatelessWidget {
  final List<PlanDisponible> planes;
  final String? planActual;
  final bool creandoPago;
  final Future<void> Function(String plan) onElegirPlan;

  const _PlanesSection({
    required this.planes,
    required this.planActual,
    required this.creandoPago,
    required this.onElegirPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planes disponibles',
              style: GoogleFonts.inter(
                  fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10.h),
            if (planes.isEmpty)
              Text(
                'No hay planes de pago disponibles en este momento.',
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: AppTheme.textGrey),
              ),
            ...planes.map(
              (plan) {
                final esActual = plan.nombre == planActual;
                return Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.label,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            plan.precioFormateado,
                            style: GoogleFonts.inter(
                              color: AppTheme.primary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '${plan.maxUsuarios} usuarios normales Â· ${plan.adminsLabel}',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp, color: AppTheme.textGrey),
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: esActual || creandoPago
                              ? null
                              : () => onElegirPlan(plan.nombre),
                          child: Text(
                              esActual ? 'Plan actual' : 'Elegir este plan'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorialSection extends StatelessWidget {
  final List<HistorialPago> historial;
  final VoidCallback onVerificar;

  const _HistorialSection({required this.historial, required this.onVerificar});

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat('#,###', 'es_CO');
    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Historial de pagos',
                    style: GoogleFonts.inter(
                        fontSize: 15.sp, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: onVerificar,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Ya pague'),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            if (historial.isEmpty)
              Text(
                'Aun no hay pagos registrados.',
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: AppTheme.textGrey),
              ),
            ...historial.map(
              (p) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_planLabel(p.planNombre)} Â· ${p.pasarela.toUpperCase()}',
                  style: GoogleFonts.inter(
                      fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _fechaLabel(p.fechaPago),
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: AppTheme.textGrey),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${number.format(p.monto)} ${p.moneda}',
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      p.estado,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color:
                            p.estado == 'completado' || p.estado == 'approved'
                                ? AppTheme.accent
                                : AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _vencimientoLabel(PlanInfo info) {
  if (info.fechaVencimiento == null) return 'Sin fecha de vencimiento';
  final fecha = DateFormat('dd/MM/yyyy').format(info.fechaVencimiento!);
  return 'Vence: $fecha';
}

String _fechaLabel(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';
  return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
}

String _planLabel(String plan) {
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

Color _progressColor(double pct) {
  if (pct >= 1) return AppTheme.error;
  if (pct >= 0.8) return AppTheme.warning;
  return AppTheme.accent;
}
