import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../core/theme/app_theme.dart';

// â”€â”€ MODELOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PasarelaConfig {
  final String id;
  final String nombre;
  final String logo;
  final bool implementada;
  final Color color;
  final String? fechaEstimada;

  const PasarelaConfig({
    required this.id,
    required this.nombre,
    required this.logo,
    required this.implementada,
    required this.color,
    this.fechaEstimada,
  });
}

const _pasarelas = [
  PasarelaConfig(
    id: 'mercadopago',
    nombre: 'Mercado Pago',
    logo: 'ðŸ’³',
    implementada: true,
    color: Color(0xFF009EE3),
  ),
  PasarelaConfig(
    id: 'stripe',
    nombre: 'Stripe',
    logo: 'âš¡',
    implementada: false,
    color: Color(0xFF635BFF),
    fechaEstimada: 'Q3 2026',
  ),
  PasarelaConfig(
    id: 'payu',
    nombre: 'PayU',
    logo: 'ðŸ”µ',
    implementada: false,
    color: Color(0xFF00B1EA),
    fechaEstimada: 'Q4 2026',
  ),
  PasarelaConfig(
    id: 'epayco',
    nombre: 'ePayco',
    logo: 'ðŸŸ¢',
    implementada: false,
    color: Color(0xFF00C853),
    fechaEstimada: 'Q4 2026',
  ),
];

// â”€â”€ STATE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PasarelaTestResult {
  final bool ok;
  final int? ms;
  final String? usuario;
  final String? pais;
  final String? ambiente;
  final String? error;

  const PasarelaTestResult({
    required this.ok,
    this.ms,
    this.usuario,
    this.pais,
    this.ambiente,
    this.error,
  });

  factory PasarelaTestResult.fromJson(Map<String, dynamic> j) =>
      PasarelaTestResult(
        ok: j['ok'] as bool? ?? false,
        ms: j['ms'] as int?,
        usuario: j['usuario']?.toString(),
        pais: j['pais']?.toString(),
        ambiente: j['ambiente']?.toString(),
        error: j['error']?.toString(),
      );
}

class PagoMp {
  final String id;
  final String status;
  final double monto;
  final String moneda;
  final String? externalRef;
  final DateTime? fecha;
  final String? metodo;

  const PagoMp({
    required this.id,
    required this.status,
    required this.monto,
    required this.moneda,
    this.externalRef,
    this.fecha,
    this.metodo,
  });

  factory PagoMp.fromJson(Map<String, dynamic> j) => PagoMp(
        id: j['id'].toString(),
        status: j['status'].toString(),
        monto: double.tryParse(j['monto'].toString()) ?? 0,
        moneda: j['moneda']?.toString() ?? 'COP',
        externalRef: j['external_reference']?.toString(),
        metodo: j['metodo']?.toString(),
        fecha: j['fecha'] != null
            ? DateTime.tryParse(j['fecha'].toString())
            : null,
      );
}

class PasarelasState {
  final PasarelaTestResult? testResult;
  final bool testando;
  final bool creandoPrueba;
  final bool cargandoPagos;
  final String? urlPrueba;
  final String? preferenceId;
  final List<PagoMp> pagosMp;
  final Map<String, dynamic>? usuariosPrueba;
  final String? error;
  final String? success;

  const PasarelasState({
    this.testResult,
    this.testando = false,
    this.creandoPrueba = false,
    this.cargandoPagos = false,
    this.urlPrueba,
    this.preferenceId,
    this.pagosMp = const [],
    this.usuariosPrueba,
    this.error,
    this.success,
  });

  PasarelasState copyWith({
    PasarelaTestResult? testResult,
    bool? testando,
    bool? creandoPrueba,
    bool? cargandoPagos,
    String? urlPrueba,
    String? preferenceId,
    List<PagoMp>? pagosMp,
    Map<String, dynamic>? usuariosPrueba,
    String? error,
    String? success,
    bool clear = false,
  }) =>
      PasarelasState(
        testResult: testResult ?? this.testResult,
        testando: testando ?? this.testando,
        creandoPrueba: creandoPrueba ?? this.creandoPrueba,
        cargandoPagos: cargandoPagos ?? this.cargandoPagos,
        urlPrueba: clear ? null : urlPrueba ?? this.urlPrueba,
        preferenceId: clear ? null : preferenceId ?? this.preferenceId,
        pagosMp: pagosMp ?? this.pagosMp,
        usuariosPrueba: clear ? null : usuariosPrueba ?? this.usuariosPrueba,
        error: clear ? null : error ?? this.error,
        success: clear ? null : success ?? this.success,
      );
}

// â”€â”€ NOTIFIER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PasarelasNotifier extends StateNotifier<PasarelasState> {
  final SupabaseClient _client;
  final String _token;

  PasarelasNotifier(this._client, this._token) : super(const PasarelasState());

  Future<void> testConexion() async {
    state = state.copyWith(testando: true, clear: true);
    try {
      final res = await _client.functions.invoke('sa-pasarelas-test', body: {
        'token': _token,
        'accion': 'test_conexion',
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      state = state.copyWith(
        testando: false,
        testResult: PasarelaTestResult.fromJson(data),
      );
    } catch (e) {
      state = state.copyWith(
        testando: false,
        testResult: PasarelaTestResult(ok: false, error: e.toString()),
      );
    }
  }

  Future<void> crearUsuariosPrueba() async {
    state = state.copyWith(creandoPrueba: true, clear: true);
    try {
      final res = await _client.functions.invoke('sa-pasarelas-test', body: {
        'token': _token,
        'accion': 'crear_usuarios_prueba',
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['ok'] == true) {
        state = state.copyWith(
          creandoPrueba: false,
          usuariosPrueba: data,
          success:
              'Usuarios de prueba creados â€” guÃ¡rdalos, MP no los muestra de nuevo',
        );
      } else {
        state = state.copyWith(
            creandoPrueba: false, error: data['error']?.toString());
      }
    } catch (e) {
      state = state.copyWith(creandoPrueba: false, error: e.toString());
    }
  }

  Future<void> crearPagoPrueba(String plan, String orgId) async {
    state = state.copyWith(creandoPrueba: true, clear: true);
    try {
      final res = await _client.functions.invoke('sa-pasarelas-test', body: {
        'token': _token,
        'accion': 'crear_pago_prueba',
        'plan': plan,
        'org_id': orgId,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['ok'] == true) {
        state = state.copyWith(
          creandoPrueba: false,
          urlPrueba: data['sandbox_init_point']?.toString() ??
              data['init_point']?.toString(),
          preferenceId: data['preference_id']?.toString(),
          success: 'Preferencia creada: ${data['preference_id']}',
        );
      } else {
        state = state.copyWith(
            creandoPrueba: false, error: data['error']?.toString());
      }
    } catch (e) {
      state = state.copyWith(creandoPrueba: false, error: e.toString());
    }
  }

  Future<void> listarPagosMp() async {
    state = state.copyWith(cargandoPagos: true);
    try {
      final res = await _client.functions.invoke('sa-pasarelas-test', body: {
        'token': _token,
        'accion': 'listar_pagos_mp',
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['ok'] == true) {
        final lista = (data['pagos'] as List? ?? [])
            .map((j) => PagoMp.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(pagosMp: lista, cargandoPagos: false);
      } else {
        state = state.copyWith(
            cargandoPagos: false, error: data['error']?.toString());
      }
    } catch (e) {
      state = state.copyWith(cargandoPagos: false, error: e.toString());
    }
  }

  void limpiar() => state = state.copyWith(clear: true);
}

final pasarelasProvider =
    StateNotifierProvider<PasarelasNotifier, PasarelasState>((ref) {
  final token = ref.watch(currentUserProvider)?.sessionToken ?? '';
  return PasarelasNotifier(Supabase.instance.client, token);
});

// â”€â”€ PANTALLA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class PasarelasTab extends ConsumerStatefulWidget {
  final List<dynamic> organizaciones; // List<SaOrganizacion>
  const PasarelasTab({super.key, required this.organizaciones});

  @override
  ConsumerState<PasarelasTab> createState() => _PasarelasTabState();
}

class _PasarelasTabState extends ConsumerState<PasarelasTab> {
  String _planSeleccionado = 'starter';
  String? _orgSeleccionada;

  @override
  void initState() {
    super.initState();
    if (widget.organizaciones.isNotEmpty) {
      _orgSeleccionada = widget.organizaciones.first.id as String;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pasarelasProvider.notifier).listarPagosMp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pasarelasProvider);

    ref.listen(pasarelasProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(next.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Tarjetas de pasarelas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _SectionTitle('Pasarelas de pago'),
          SizedBox(height: 10.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 1.5,
            children:
                _pasarelas.map((p) => _PasarelaCard(pasarela: p)).toList(),
          ),
          SizedBox(height: 20.h),

          // â”€â”€ Test de conexiÃ³n MP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _SectionTitle('Test de conexiÃ³n â€” Mercado Pago'),
          SizedBox(height: 10.h),
          _TestConexionCard(state: state),
          SizedBox(height: 20.h),

          // â”€â”€ Crear usuarios de prueba â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _SectionTitle('Paso 1 â€” Usuarios de prueba MP'),
          SizedBox(height: 6.h),
          Text(
            'MP requiere un usuario comprador para pagar en sandbox. CrÃ©alos aquÃ­.',
            style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.textGrey),
          ),
          SizedBox(height: 8.h),
          _UsuariosPruebaCard(state: state),
          SizedBox(height: 20.h),

          // â”€â”€ Crear pago de prueba â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const _SectionTitle('Paso 2 â€” Crear pago de prueba'),
          SizedBox(height: 10.h),
          _CrearPruebaCard(
            state: state,
            planSeleccionado: _planSeleccionado,
            orgSeleccionada: _orgSeleccionada,
            organizaciones: widget.organizaciones,
            onPlanChanged: (v) => setState(() => _planSeleccionado = v),
            onOrgChanged: (v) => setState(() => _orgSeleccionada = v),
          ),
          SizedBox(height: 20.h),

          // â”€â”€ Ãšltimos pagos en MP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(
            children: [
              const Expanded(
                  child: _SectionTitle(
                      'Ãšltimos pagos en Mercado Pago (7 dÃ­as)')),
              IconButton(
                icon: state.cargandoPagos
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.refresh, size: 20.sp),
                onPressed: () =>
                    ref.read(pasarelasProvider.notifier).listarPagosMp(),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _PagosMpList(pagos: state.pagosMp, cargando: state.cargandoPagos),
        ],
      ),
    );
  }
}

// â”€â”€ WIDGETS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark));
}

class _PasarelaCard extends StatelessWidget {
  final PasarelaConfig pasarela;
  const _PasarelaCard({required this.pasarela});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: pasarela.implementada
              ? pasarela.color.withValues(alpha: 0.4)
              : AppTheme.divider,
          width: pasarela.implementada ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(pasarela.logo, style: TextStyle(fontSize: 20.sp)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: pasarela.implementada
                    ? pasarela.color.withValues(alpha: 0.1)
                    : AppTheme.textGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                pasarela.implementada ? 'Activa' : 'PrÃ³ximamente',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: pasarela.implementada
                      ? pasarela.color
                      : AppTheme.textGrey,
                ),
              ),
            ),
          ]),
          Text(pasarela.nombre,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: pasarela.implementada
                    ? AppTheme.textDark
                    : AppTheme.textGrey,
              )),
          if (!pasarela.implementada && pasarela.fechaEstimada != null)
            Text(
              'Estimado: ${pasarela.fechaEstimada}',
              style:
                  GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.textGrey),
            ),
        ],
      ),
    );
  }
}

class _TestConexionCard extends ConsumerWidget {
  final PasarelasState state;
  const _TestConexionCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = state.testResult;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('ðŸ’³', style: TextStyle(fontSize: 18.sp)),
            SizedBox(width: 8.w),
            Text('Mercado Pago',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13.sp)),
            const Spacer(),
            SizedBox(
              height: 34.h,
              child: ElevatedButton.icon(
                onPressed: state.testando
                    ? null
                    : () => ref.read(pasarelasProvider.notifier).testConexion(),
                icon: state.testando
                    ? SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.wifi_tethering, size: 14.sp),
                label: Text('Probar conexiÃ³n',
                    style: GoogleFonts.inter(fontSize: 12.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009EE3),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                ),
              ),
            ),
          ]),
          if (r != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: r.ok
                    ? AppTheme.accent.withValues(alpha: 0.05)
                    : AppTheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: r.ok
                      ? AppTheme.accent.withValues(alpha: 0.2)
                      : AppTheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: r.ok
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.accent, size: 16.sp),
                          SizedBox(width: 6.w),
                          Text('ConexiÃ³n exitosa',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                  color: AppTheme.accent)),
                          const Spacer(),
                          Text('${r.ms}ms',
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp, color: AppTheme.textGrey)),
                        ]),
                        SizedBox(height: 6.h),
                        _InfoFila('Cuenta', r.usuario ?? 'â€”'),
                        _InfoFila('PaÃ­s', r.pais ?? 'â€”'),
                        _InfoFila('Ambiente', r.ambiente ?? 'â€”'),
                      ],
                    )
                  : Row(children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.error, size: 16.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                          child: Text(r.error ?? 'Error desconocido',
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp, color: AppTheme.error))),
                    ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _CrearPruebaCard extends ConsumerWidget {
  final PasarelasState state;
  final String planSeleccionado;
  final String? orgSeleccionada;
  final List<dynamic> organizaciones;
  final void Function(String) onPlanChanged;
  final void Function(String?) onOrgChanged;

  const _CrearPruebaCard({
    required this.state,
    required this.planSeleccionado,
    required this.orgSeleccionada,
    required this.organizaciones,
    required this.onPlanChanged,
    required this.onOrgChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector plan
          DropdownButtonFormField<String>(
            initialValue: planSeleccionado,
            decoration: InputDecoration(
              labelText: 'Plan a probar',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            items: [
              'starter',
              'profesional',
              'clinica',
              'corporativo',
              'ilimitado'
            ]
                .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: GoogleFonts.inter(fontSize: 13.sp))))
                .toList(),
            onChanged: (v) => onPlanChanged(v!),
          ),
          SizedBox(height: 10.h),

          // Selector org
          if (organizaciones.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: orgSeleccionada,
              decoration: InputDecoration(
                labelText: 'OrganizaciÃ³n',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              items: organizaciones
                  .map((o) => DropdownMenuItem(
                        value: o.id as String,
                        child: Text(o.nombre as String,
                            style: GoogleFonts.inter(fontSize: 13.sp)),
                      ))
                  .toList(),
              onChanged: onOrgChanged,
            ),
          SizedBox(height: 12.h),

          // BotÃ³n crear
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.creandoPrueba || orgSeleccionada == null
                  ? null
                  : () => ref
                      .read(pasarelasProvider.notifier)
                      .crearPagoPrueba(planSeleccionado, orgSeleccionada!),
              icon: state.creandoPrueba
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.play_circle_outline, size: 18.sp),
              label: Text(
                  state.creandoPrueba ? 'Creando...' : 'Crear pago de prueba',
                  style: GoogleFonts.inter(fontSize: 13.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009EE3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),

          // Resultado
          if (state.urlPrueba != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8.r),
                border:
                    Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.check_circle,
                        color: AppTheme.accent, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text('Preferencia creada',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                            color: AppTheme.accent)),
                  ]),
                  SizedBox(height: 8.h),
                  if (state.preferenceId != null)
                    _CopiableRow('ID', state.preferenceId!),
                  SizedBox(height: 8.h),
                  // Botones de acciÃ³n
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                              ClipboardData(text: state.urlPrueba!));
                          if (!context.mounted) return;
                          messenger.showSnackBar(const SnackBar(
                              duration: Duration(seconds: 5),
                              content: Text('URL copiada'),
                              behavior: SnackBarBehavior.floating));
                        },
                        icon: Icon(Icons.copy, size: 14.sp),
                        label: Text('Copiar URL',
                            style: GoogleFonts.inter(fontSize: 12.sp)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(state.urlPrueba!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: Icon(Icons.open_in_new, size: 14.sp),
                        label: Text('Abrir pago',
                            style: GoogleFonts.inter(fontSize: 12.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009EE3),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ]),
                  SizedBox(height: 8.h),
                  Text('Usa la tarjeta de prueba:',
                      style: GoogleFonts.inter(
                          fontSize: 11.sp, color: AppTheme.textGrey)),
                  SizedBox(height: 4.h),
                  const _CopiableRow('NÃºmero', '4509 9535 6623 3704'),
                  const _CopiableRow('Vencimiento', '11/25'),
                  const _CopiableRow('CVV', '123'),
                  const _CopiableRow('Nombre', 'APRO  â† fuerza aprobaciÃ³n'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PagosMpList extends StatelessWidget {
  final List<PagoMp> pagos;
  final bool cargando;
  const _PagosMpList({required this.pagos, required this.cargando});

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (pagos.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Center(
            child: Text('No hay pagos en los Ãºltimos 7 dÃ­as',
                style: GoogleFonts.inter(
                    color: AppTheme.textGrey, fontSize: 13.sp))),
      );
    }

    final fmt = NumberFormat('#,###', 'es_CO');
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pagos.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.divider),
        itemBuilder: (_, i) {
          final p = pagos[i];
          final statusColor = p.status == 'approved'
              ? AppTheme.accent
              : p.status == 'pending'
                  ? AppTheme.warning
                  : AppTheme.error;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${p.id}',
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, fontWeight: FontWeight.w600)),
                  if (p.externalRef != null)
                    Text(p.externalRef!,
                        style: GoogleFonts.inter(
                            fontSize: 10.sp, color: AppTheme.textGrey)),
                  if (p.fecha != null)
                    Text(DateFormat('dd/MM/yy HH:mm').format(p.fecha!),
                        style: GoogleFonts.inter(
                            fontSize: 10.sp, color: AppTheme.textGrey)),
                ],
              )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${fmt.format(p.monto)}',
                      style: GoogleFonts.inter(
                          fontSize: 13.sp, fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(p.status,
                        style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: statusColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _InfoFila extends StatelessWidget {
  final String label, value;
  const _InfoFila(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(children: [
          SizedBox(
              width: 70.w,
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: AppTheme.textGrey))),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 11.sp, fontWeight: FontWeight.w500)),
        ]),
      );
}

class _CopiableRow extends StatelessWidget {
  final String label, value;
  const _CopiableRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(children: [
          SizedBox(
              width: 80.w,
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: AppTheme.textGrey))),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.robotoMono(
                      fontSize: 11.sp, fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: value)),
            child: Icon(Icons.copy_outlined,
                size: 13.sp, color: AppTheme.textGrey),
          ),
        ]),
      );
}

class _UsuariosPruebaCard extends ConsumerWidget {
  final PasarelasState state;
  const _UsuariosPruebaCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = state.usuariosPrueba;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.creandoPrueba
                  ? null
                  : () => ref
                      .read(pasarelasProvider.notifier)
                      .crearUsuariosPrueba(),
              icon: state.creandoPrueba
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.group_add_outlined, size: 18.sp),
              label: Text(
                state.creandoPrueba
                    ? 'Creando usuarios...'
                    : 'Crear usuarios de prueba',
                style: GoogleFonts.inter(fontSize: 13.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009EE3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          if (u != null) ...[
            SizedBox(height: 12.h),
            // Seller
            _UsuarioBox(
              titulo: 'ðŸª Vendedor (tu cuenta de prueba)',
              color: AppTheme.primary,
              id: u['seller']?['id']?.toString() ?? 'â€”',
              email: u['seller']?['email']?.toString() ?? 'â€”',
              password: u['seller']?['password']?.toString() ?? 'â€”',
            ),
            SizedBox(height: 8.h),
            // Buyer
            _UsuarioBox(
              titulo: 'ðŸ›’ Comprador (usa este para pagar)',
              color: AppTheme.accent,
              id: u['buyer']?['id']?.toString() ?? 'â€”',
              email: u['buyer']?['email']?.toString() ?? 'â€”',
              password: u['buyer']?['password']?.toString() ?? 'â€”',
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14.sp, color: AppTheme.warning),
                SizedBox(width: 6.w),
                Expanded(
                    child: Text(
                  'Guarda estas credenciales â€” MP no las muestra de nuevo.',
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: AppTheme.warning),
                )),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsuarioBox extends StatelessWidget {
  final String titulo, id, email, password;
  final Color color;
  const _UsuarioBox({
    required this.titulo,
    required this.color,
    required this.id,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w600, color: color)),
          SizedBox(height: 6.h),
          _CopiableRow('ID', id),
          _CopiableRow('Email', email),
          _CopiableRow('Password', password),
        ],
      ),
    );
  }
}
