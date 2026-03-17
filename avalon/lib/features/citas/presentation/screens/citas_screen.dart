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
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/domain/app_user.dart';
import 'nueva_cita_screen.dart';
import 'cita_detalle_screen.dart';

class CitasScreen extends ConsumerStatefulWidget {
  const CitasScreen({super.key});

  @override
  ConsumerState<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends ConsumerState<CitasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
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
    final recordatorios = ref.watch(recordatoriosProvider);
    
    final tieneRecordatoriosUrgentes = recordatorios
        .any((r) => r.prioridad == PrioridadRecordatorio.urgente);

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
                    MaterialPageRoute(builder: (_) => const RecordatoriosScreen()),
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
            Tab(text: context.t.calendario, icon: const Icon(Icons.calendar_month)),
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
            estadoFiltro: _estadoFiltro,
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

    final dias = List.generate(42, (i) =>
        primerDiaMes.add(Duration(days: i - primerDiaSemana)));

    // Altura de celda adaptativa: en desktop más compacto, en mobile más alto
    final isDesktopView = MediaQuery.of(context).size.width > 600;
    final cellHeight = isDesktopView ? 72.0 : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DiasSemanaHeader(),
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
      children: dias.map((dia) => Expanded(
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
      )).toList(),
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
    Color color;
    switch (cita.estado) {
      case EstadoCita.confirmada:
        color = AppTheme.accent;
        break;
      case EstadoCita.agendada:
        color = AppTheme.warning;
        break;
      case EstadoCita.cancelada:
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.primary;
    }
    
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
          ...citas.map((cita) => _CitaListItem(cita: cita)),
        ],
      ),
    );
  }
}

class _ListaTab extends ConsumerWidget {
  final CitasState citasState;
  final TextEditingController searchController;
  final String estadoFiltro;
  final Function(String) onEstadoChanged;

  const _ListaTab({
    required this.citasState,
    required this.searchController,
    required this.estadoFiltro,
    required this.onEstadoChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _desktopWrap(context, Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por paciente o psicólogo...',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: estadoFiltro,
                decoration: InputDecoration(
                  labelText: 'Filtrar por estado',
                ),
                items: const [
                  DropdownMenuItem(value: 'todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'agendada', child: Text('Agendada')),
                  DropdownMenuItem(value: 'confirmada', child: Text('Confirmada')),
                  DropdownMenuItem(value: 'en_progreso', child: Text('En Progreso')),
                  DropdownMenuItem(value: 'completada', child: Text('Completada')),
                  DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                  DropdownMenuItem(value: 'no_asistio', child: Text('No Asistió')),
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
                  itemCount: citasState.citas.length,
                  itemBuilder: (context, index) {
                    final cita = citasState.citas[index];
                    return _CitaListItem(cita: cita);
                  },
                ),
        ),
      ],
    ));
  }
}

class _CitaListItem extends ConsumerWidget {
  final Cita cita;

  const _CitaListItem({required this.cita});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final puedeCancelar = user?.isSecretaria == true ||
        user?.isAdmin == true ||
        user?.isSuperAdmin == true;

    // Nombres reales o fallback legible
    final nombrePaciente   = cita.pacienteNombre   ?? 'Paciente';
    final nombrePsicologo  = cita.psicologoNombre  ?? 'Psicólogo';

    Color estadoColor;
    switch (cita.estado) {
      case EstadoCita.confirmada:
      case EstadoCita.enProgreso:  estadoColor = AppTheme.accent;    break;
      case EstadoCita.completada:  estadoColor = AppTheme.primary;   break;
      case EstadoCita.cancelada:
      case EstadoCita.noAsistio:   estadoColor = AppTheme.error;     break;
      default:                     estadoColor = AppTheme.warning;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => Navigator.push(
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
                  if (puedeCancelar && cita.estado != EstadoCita.cancelada &&
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
              onPressed: () => Navigator.pop(context),
              child: const Text('No')),
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

  String _getEstadoLabel(EstadoCita estado) {
    switch (estado) {
      case EstadoCita.agendada: return 'Agendada';
      case EstadoCita.confirmada: return 'Confirmada';
      case EstadoCita.enProgreso: return 'En Progreso';
      case EstadoCita.completada: return 'Completada';
      case EstadoCita.cancelada: return 'Cancelada';
      case EstadoCita.noAsistio: return 'No Asistió';
      case EstadoCita.reprogramada: return 'Reprogramada';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.primary;
    switch (estado) {
      case EstadoCita.agendada:
        color = AppTheme.warning;
        break;
      case EstadoCita.confirmada:
      case EstadoCita.enProgreso:
        color = AppTheme.accent;
        break;
      case EstadoCita.cancelada:
      case EstadoCita.noAsistio:
        color = AppTheme.error;
        break;
      case EstadoCita.completada:
        color = AppTheme.primary;
        break;
      case EstadoCita.reprogramada:
        color = AppTheme.secondary;
        break;
    }
    
    return Chip(
      label: Text(
        _getEstadoLabel(estado),
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
    
    return _desktopWrap(context, ListView.builder(
      itemCount: disponibilidad.length,
      itemBuilder: (context, index) {
        final psicologo = disponibilidad[index];
        return _PsicologoCard(psicologo: psicologo);
      },
    ));
  }
}

class _PsicologoCard extends StatelessWidget {
  final DisponibilidadPsicologo psicologo;

  const _PsicologoCard({required this.psicologo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: psicologo.estaDisponible ? AppTheme.accent : AppTheme.warning,
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
            if (psicologo.especialidad != null)
              Text(psicologo.especialidad!),
            Text(
              psicologo.estaDisponible ? 'Disponible' : 'En sesión',
              style: GoogleFonts.inter(
                color: psicologo.estaDisponible ? AppTheme.accent : AppTheme.warning,
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
        trailing: Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: psicologo.estaDisponible ? AppTheme.accent : AppTheme.warning,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

extension on String {
  String get iniciales {
    final partes = trim().split(' ');
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return substring(0, length >= 2 ? 2 : 1).toUpperCase();
  }
}

class RecordatoriosScreen extends ConsumerWidget {
  const RecordatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordatorios = ref.watch(recordatoriosProvider);
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: recordatorios.isEmpty
                ? Center(
                    child: Text(
                      'No hay recordatorios activos',
                      style: GoogleFonts.inter(color: AppTheme.textGrey),
                    ),
                  )
                : ListView.builder(
                    itemCount: recordatorios.length,
                    itemBuilder: (context, index) {
                      final recordatorio = recordatorios[index];
                      return _RecordatorioCard(
                        recordatorio: recordatorio,
                        user: ref.read(currentUserProvider)!,
                        onResolver: () => ref.read(citasProvider.notifier).resolverRecordatorio(recordatorio.id),
                        onEliminar: () {
                          final user = ref.read(currentUserProvider);
                          if ((user?.isAdmin == true) || (user?.isSuperAdmin == true)) {
                            ref.read(citasProvider.notifier).eliminarRecordatorio(recordatorio.id);
                          }
                        },
                      );
                    },
                  ),
          ),
          if ((user?.isPsicologo == true) || (user?.isAdmin == true) || (user?.isSuperAdmin == true))
            _CrearRecordatorioForm(
              onCrear: (titulo, descripcion, prioridad) {
                ref.read(citasProvider.notifier).crearRecordatorio(
                  titulo: titulo,
                  descripcion: descripcion,
                  prioridad: prioridad,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RecordatorioCard extends StatelessWidget {
  final Recordatorio recordatorio;
  final AppUser user;
  final VoidCallback onResolver;
  final VoidCallback? onEliminar;

  const _RecordatorioCard({
    required this.recordatorio,
    required this.user,
    required this.onResolver,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (recordatorio.prioridad) {
      case PrioridadRecordatorio.urgente:
        color = AppTheme.error;
        break;
      case PrioridadRecordatorio.normal:
        color = AppTheme.primary;
        break;
      case PrioridadRecordatorio.baja:
        color = AppTheme.accent;
        break;
    }
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        leading: Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(recordatorio.titulo),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recordatorio.descripcion != null) Text(recordatorio.descripcion!),
            Text(
              'Creado por ${recordatorio.creadoPor} • ${_tiempoRelativo(recordatorio.fechaRegistro)}',
              style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.textGrey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.isPsicologo || user.isAdmin || user.isSuperAdmin)
              IconButton(
                onPressed: onResolver,
                icon: const Icon(Icons.check, color: AppTheme.accent),
              ),
            if (onEliminar != null)
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete, color: AppTheme.error),
              ),
          ],
        ),
      ),
    );
  }

  String _tiempoRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    
    if (diferencia.inDays > 0) return 'Hace ${diferencia.inDays} días';
    if (diferencia.inHours > 0) return 'Hace ${diferencia.inHours} horas';
    if (diferencia.inMinutes > 0) return 'Hace ${diferencia.inMinutes} minutos';
    return 'Hace unos momentos';
  }
}

class _CrearRecordatorioForm extends StatefulWidget {
  final Function(String titulo, String? descripcion, String prioridad) onCrear;

  const _CrearRecordatorioForm({required this.onCrear});

  @override
  State<_CrearRecordatorioForm> createState() => _CrearRecordatorioFormState();
}

class _CrearRecordatorioFormState extends State<_CrearRecordatorioForm> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _prioridad = 'normal';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nuevo Recordatorio',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _tituloController,
            decoration: InputDecoration(
              labelText: 'Título *',
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _descripcionController,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
            ),
            maxLines: 2,
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: _prioridad,
            decoration: InputDecoration(
              labelText: 'Prioridad',
            ),
            items: const [
              DropdownMenuItem(value: 'baja', child: Text('Baja')),
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
            ],
            onChanged: (value) => setState(() => _prioridad = value!),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _tituloController.text.isNotEmpty
                  ? () {
                      widget.onCrear(
                        _tituloController.text,
                        _descripcionController.text.isEmpty ? null : _descripcionController.text,
                        _prioridad,
                      );
                      _tituloController.clear();
                      _descripcionController.clear();
                      setState(() => _prioridad = 'normal');
                    }
                  : null,
              child: const Text('Agregar'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}

Widget _desktopWrap(BuildContext context, Widget child) {
  if (!context.isDesktop) return child;
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: child,
    ),
  );
}