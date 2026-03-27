import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../domain/cita.dart';
import '../providers/citas_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/utils/cita_ui_utils.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'nueva_cita_screen.dart';
import 'cita_detalle_screen.dart';
import '../../../recordatorios/presentation/screens/recordatorios_screen.dart';
import '../../../recordatorios/presentation/providers/recordatorios_provider.dart';

class CitasScreen extends ConsumerStatefulWidget {
  const CitasScreen({super.key});

  @override
  ConsumerState<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends ConsumerState<CitasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _busqueda = '';
  String _estadoFiltro = 'todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(citasProvider.notifier).cargarTodo();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final citasState = ref.watch(citasProvider);
    final recordatorios = ref.watch(recordatoriosExProvider).recordatorios;

    final tieneRecordatoriosUrgentes =
        recordatorios.any((r) => r.prioridad == 'urgente');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Citas',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => ref.read(citasProvider.notifier).cargarTodo(),
            icon: const Icon(Icons.refresh),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecordatoriosScreen()),
                  );
                },
                icon: const Icon(Iconsax.notification),
              ),
              if (tieneRecordatoriosUrgentes)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
                text: context.t.calendario,
                icon: const Icon(Icons.calendar_month)),
            Tab(text: context.t.lista, icon: const Icon(Icons.list)),
            Tab(text: context.t.psicologos, icon: const Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CalendarioTab(citasState: citasState),
          _ListaTab(
            citasState: citasState,
            searchController: _searchController,
            busqueda: _busqueda,
            estadoFiltro: _estadoFiltro,
            onSearchChanged: (v) => setState(() => _busqueda = v),
            onEstadoChanged: (estado) => setState(() => _estadoFiltro = estado),
          ),
          _PsicologosTab(citasState: citasState),
        ],
      ),
      floatingActionButton: (user?.isSecretaria == true ||
              user?.isAdmin == true ||
              user?.isSuperAdmin == true)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NuevaCitaScreen()),
                );
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _CalendarioTab extends ConsumerStatefulWidget {
  final CitasState citasState;

  const _CalendarioTab({required this.citasState});

  @override
  ConsumerState<_CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends ConsumerState<_CalendarioTab> {
  late DateTime _mesActual;

  @override
  void initState() {
    super.initState();
    _mesActual = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final citasPorDia = ref.watch(citasPorDiaProvider);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MesNavigator(
            mesActual: _mesActual,
            onMesChanged: (nuevo) => setState(() => _mesActual = nuevo),
          ),
          _CalendarioGrid(
            mesActual: _mesActual,
            citasPorDia: citasPorDia,
          ),
        ],
      ),
    );
  }
}

class _MesNavigator extends StatelessWidget {
  final DateTime mesActual;
  final ValueChanged<DateTime> onMesChanged;

  const _MesNavigator({
    required this.mesActual,
    required this.onMesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => onMesChanged(
              DateTime(mesActual.year, mesActual.month - 1, 1),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat('MMMM yyyy', 'es').format(mesActual),
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => onMesChanged(
              DateTime(mesActual.year, mesActual.month + 1, 1),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _CalendarioGrid extends StatelessWidget {
  final DateTime mesActual;
  final Map<String, List<Cita>> citasPorDia;

  const _CalendarioGrid({
    required this.mesActual,
    required this.citasPorDia,
  });

  @override
  Widget build(BuildContext context) {
    final primerDiaMes = DateTime(mesActual.year, mesActual.month, 1);
    // Dart weekday: 1=lun ... 7=dom. Para calendario Dom=0: 7%7=0, 1%7=1, etc.
    final primerDiaSemana = primerDiaMes.weekday % 7;

    final dias = List.generate(
        42, (i) => primerDiaMes.add(Duration(days: i - primerDiaSemana)));

    // Altura de celda adaptativa: en desktop más compacto, en mobile más alto
    final isDesktopView = MediaQuery.of(context).size.width > 600;
    final cellHeight = isDesktopView ? 72.0 : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _DiasSemanaHeader(),
        // 6 filas de 7 días — altura fija para que siempre se vea el mes completo
        ...List.generate(6, (fila) {
          return Row(
            children: List.generate(7, (col) {
              final index = fila * 7 + col;
              final dia = dias[index];
              final esMesActual = dia.month == mesActual.month;
              final diaKey =
                  '${dia.year}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';
              final citasDia = citasPorDia[diaKey] ?? [];

              return Expanded(
                child: SizedBox(
                  height: cellHeight,
                  child: _DiaCalendario(
                    dia: dia,
                    esMesActual: esMesActual,
                    citas: citasDia,
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

class _DiasSemanaHeader extends StatelessWidget {
  const _DiasSemanaHeader();

  @override
  Widget build(BuildContext context) {
    final dias = context.t.diasSemana;

    return Row(
      children: dias
          .map((dia) => Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    dia,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _DiaCalendario extends StatelessWidget {
  final DateTime dia;
  final bool esMesActual;
  final List<Cita> citas;

  const _DiaCalendario({
    required this.dia,
    required this.esMesActual,
    required this.citas,
  });

  @override
  Widget build(BuildContext context) {
    final esHoy = _esHoy(dia);
    final citasMostrar = citas.take(2).toList();

    return GestureDetector(
      onTap: citas.isNotEmpty ? () => _mostrarCitasDia(context, citas) : null,
      child: Container(
        margin: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: esHoy ? AppTheme.primary.withValues(alpha: 0.1) : null,
          border: esHoy ? Border.all(color: AppTheme.primary) : null,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            SizedBox(height: 4.h),
            Text(
              '${dia.day}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: esHoy ? FontWeight.w600 : FontWeight.normal,
                color: esMesActual ? AppTheme.textDark : AppTheme.textGrey,
              ),
            ),
            const Spacer(),
            ...citasMostrar.map((cita) => _CitaIndicador(cita: cita)),
            if (citas.length > 2)
              Container(
                width: 4.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: const BoxDecoration(
                  color: AppTheme.textGrey,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _esHoy(DateTime dia) {
    final ahora = DateTime.now();
    return dia.year == ahora.year &&
        dia.month == ahora.month &&
        dia.day == ahora.day;
  }

  void _mostrarCitasDia(BuildContext context, List<Cita> citas) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _CitasDiaSheet(citas: citas),
    );
  }
}

class _CitaIndicador extends StatelessWidget {
  final Cita cita;

  const _CitaIndicador({required this.cita});

  @override
  Widget build(BuildContext context) {
    final color = cita.estado.color;

    return Container(
      width: 16.w,
      height: 2.h,
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.r),
      ),
    );
  }
}

class _CitasDiaSheet extends StatelessWidget {
  final List<Cita> citas;

  const _CitasDiaSheet({required this.citas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Citas del día',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          ...citas.map((cita) => _CitaListItem(
                cita: cita,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CitaDetalleScreen(cita: cita)),
                  );
                },
              )),
        ],
      ),
    );
  }
}

class _ListaTab extends ConsumerWidget {
  final CitasState citasState;
  final TextEditingController searchController;
  final String busqueda;
  final String estadoFiltro;
  final ValueChanged<String> onSearchChanged;
  final Function(String) onEstadoChanged;

  const _ListaTab({
    required this.citasState,
    required this.searchController,
    required this.busqueda,
    required this.estadoFiltro,
    required this.onSearchChanged,
    required this.onEstadoChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return desktopWrap(
        context,
        Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por paciente o psicólogo...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    initialValue: estadoFiltro,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por estado',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                      DropdownMenuItem(
                          value: 'agendada', child: Text('Agendada')),
                      DropdownMenuItem(
                          value: 'confirmada', child: Text('Confirmada')),
                      DropdownMenuItem(
                          value: 'en_progreso', child: Text('En Progreso')),
                      DropdownMenuItem(
                          value: 'completada', child: Text('Completada')),
                      DropdownMenuItem(
                          value: 'cancelada', child: Text('Cancelada')),
                      DropdownMenuItem(
                          value: 'no_asistio', child: Text('No Asistió')),
                    ],
                    onChanged: (value) => onEstadoChanged(value ?? 'todos'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: citasState.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filtradas.length,
                      itemBuilder: (context, index) {
                        final cita = _filtradas[index];
                        return _CitaListItem(cita: cita);
                      },
                    ),
            ),
          ],
        ));
  }

  List<Cita> get _filtradas {
    final q = busqueda.trim().toLowerCase();
    final base = citasState.citas.isNotEmpty
        ? citasState.citas
        : {...citasState.citasHoy, ...citasState.citasSemana}.toList();
    return base.where((c) {
      final matchEstado =
          estadoFiltro == 'todos' || c.estado.value == estadoFiltro;
      if (!matchEstado) return false;
      if (q.isEmpty) return true;
      final paciente = (c.pacienteNombre ?? '').toLowerCase();
      final psicologo = (c.psicologoNombre ?? '').toLowerCase();
      final tipo = c.tipoSesion.label.toLowerCase();
      return paciente.contains(q) || psicologo.contains(q) || tipo.contains(q);
    }).toList();
  }
}

class _CitaListItem extends ConsumerWidget {
  final Cita cita;
  final VoidCallback? onTap;

  const _CitaListItem({required this.cita, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final puedeCancelar = user?.isSecretaria == true ||
        user?.isAdmin == true ||
        user?.isSuperAdmin == true;

    // Nombres reales o fallback legible
    final nombrePaciente = cita.pacienteNombre ?? 'Paciente';
    final nombrePsicologo = cita.psicologoNombre ?? 'Psicólogo';

    final estadoColor = cita.estado.color;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap ??
            () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CitaDetalleScreen(cita: cita)),
                ),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              // Hora
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    DateFormat('HH:mm').format(cita.fechaHora),
                    style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: estadoColor),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombrePaciente,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text(
                      '$nombrePsicologo · ${cita.tipoSesion.label}',
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: AppTheme.textGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(children: [
                      Icon(
                        cita.modalidad == ModalidadCita.online
                            ? Icons.videocam_outlined
                            : Icons.location_on_outlined,
                        size: 12.sp,
                        color: AppTheme.textGrey,
                      ),
                      SizedBox(width: 3.w),
                      Text(cita.modalidad.label,
                          style: GoogleFonts.inter(
                              fontSize: 11.sp, color: AppTheme.textGrey)),
                    ]),
                  ],
                ),
              ),
              // Estado + acciones
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _EstadoChip(estado: cita.estado),
                  if (puedeCancelar &&
                      cita.estado != EstadoCita.cancelada &&
                      cita.estado != EstadoCita.completada)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: GestureDetector(
                        onTap: () => _cancelar(context, ref, cita),
                        child: Text('Cancelar',
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: AppTheme.error,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelar(BuildContext context, WidgetRef ref, Cita cita) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Confirmas la cancelación de esta cita?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              ref.read(citasProvider.notifier).actualizarCita(
                    citaId: cita.id,
                    estado: 'cancelada',
                  );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final EstadoCita estado;

  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = estado.color;

    return Chip(
      label: Text(
        estado.label,
        style: GoogleFonts.inter(fontSize: 10.sp),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
    );
  }
}

class _PsicologosTab extends ConsumerWidget {
  final CitasState citasState;

  const _PsicologosTab({required this.citasState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disponibilidad = ref.watch(disponibilidadProvider);

    return desktopWrap(
      context,
      ListView.builder(
        itemCount: disponibilidad.length,
        itemBuilder: (context, index) {
          final psicologo = disponibilidad[index];
          return _PsicologoCard(
            psicologo: psicologo,
            onAgendar: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NuevaCitaScreen(
                  psicologoIdInicial: psicologo.psicologoId,
                  psicologoNombreInicial: psicologo.nombre,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PsicologoCard extends StatelessWidget {
  final DisponibilidadPsicologo psicologo;
  final VoidCallback onAgendar;

  const _PsicologoCard({required this.psicologo, required this.onAgendar});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              psicologo.estaDisponible ? AppTheme.accent : AppTheme.warning,
          child: Text(
            psicologo.nombre.iniciales,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(psicologo.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (psicologo.especialidad != null) Text(psicologo.especialidad!),
            Text(
              psicologo.estaDisponible ? 'Disponible' : 'En sesión',
              style: GoogleFonts.inter(
                color: psicologo.estaDisponible
                    ? AppTheme.accent
                    : AppTheme.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (psicologo.proximaCita != null)
              Text(
                'Próxima cita: ${DateFormat('HH:mm').format(psicologo.proximaCita!)}',
                style: GoogleFonts.inter(fontSize: 12.sp),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: psicologo.estaDisponible
                    ? AppTheme.accent
                    : AppTheme.warning,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: 6.h),
            TextButton(
              onPressed: onAgendar,
              child: const Text('Agendar'),
            ),
          ],
        ),
      ),
    );
  }
}
