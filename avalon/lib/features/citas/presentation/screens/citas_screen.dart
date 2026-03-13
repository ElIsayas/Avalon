import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cita_provider.dart';
import '../widgets/cita_card.dart';
import '../widgets/cita_form_dialog.dart';
import '../widgets/calendario_widget.dart';
import '../../domain/entities/cita.dart';

class CitasScreen extends ConsumerStatefulWidget {
  const CitasScreen({super.key});

  @override
  ConsumerState<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends ConsumerState<CitasScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fechaSeleccionada = DateTime.now();
  bool _vistaCalendario = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(citasProvider.notifier).refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citasState = ref.watch(citasProvider);

    ref.listen<CitasState>(citasProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(citasProvider.notifier).clearMessages();
      }
      
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(citasProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Gestión de Citas',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Hoy', icon: Icon(Icons.today)),
            Tab(text: 'Próximas', icon: Icon(Icons.schedule)),
            Tab(text: 'Todas', icon: Icon(Icons.list)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _toggleVista(),
            icon: Icon(_vistaCalendario ? Icons.list : Icons.calendar_month),
            tooltip: _vistaCalendario ? 'Vista Lista' : 'Vista Calendario',
          ),
          IconButton(
            onPressed: () => ref.read(citasProvider.notifier).refreshAll(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas
          _buildEstadisticasCard(citasState),
          
          // Vista principal
          Expanded(
            child: _vistaCalendario 
                ? _buildCalendarioView(citasState)
                : _buildListView(citasState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCitaDialog(),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Nueva Cita',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEstadisticasCard(CitasState state) {
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            state.citas.length.toString(),
            Icons.event,
            Colors.white,
          ),
          _buildStatItem(
            'Hoy',
            state.citasHoy.length.toString(),
            Icons.today,
            Colors.green[300]!,
          ),
          _buildStatItem(
            'Completadas',
            state.estadisticas['completadas']?.toString() ?? '0',
            Icons.check_circle,
            Colors.grey[300]!,
          ),
          _buildStatItem(
            'Canceladas',
            state.estadisticas['canceladas']?.toString() ?? '0',
            Icons.cancel,
            Colors.red[300]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28.sp, color: color),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarioView(CitasState state) {
    return Column(
      children: [
        // Calendario
        Container(
          height: 350.h,
          margin: EdgeInsets.all(16.r),
          child: CalendarioWidget(
            fechaSeleccionada: _fechaSeleccionada,
            citas: state.citas,
            onFechaSeleccionada: (fecha) {
              setState(() {
                _fechaSeleccionada = fecha;
              });
              ref.read(citasProvider.notifier).seleccionarFecha(fecha);
            },
          ),
        ),
        
        // Citas del día seleccionado
        Expanded(
          child: state.fechaSeleccionada != null
              ? _buildCitasDelDia(state)
              : const Center(child: Text('Selecciona una fecha')),
        ),
      ],
    );
  }

  Widget _buildListView(CitasState state) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCitasLista(state.citasHoy, 'Citas de Hoy'),
        _buildCitasLista(
          state.citas.where((c) => 
            c.fechaHora.isAfter(DateTime.now()) && 
            c.estado == EstadoCita.agendada
          ).toList(),
          'Próximas Citas'
        ),
        _buildCitasLista(state.citas, 'Todas las Citas'),
      ],
    );
  }

  Widget _buildCitasDelDia(CitasState state) {
    if (state.citasDelDia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No hay citas para ${_formatFecha(state.fechaSeleccionada!)}',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: state.citasDelDia.length,
      itemBuilder: (context, index) {
        final cita = state.citasDelDia[index];
        return CitaCard(
          cita: cita,
          onEdit: () => _showEditCitaDialog(cita),
          onDelete: () => _showDeleteConfirmation(cita),
          onConfirm: () => _confirmarCita(cita),
          onCancel: () => _showCancelDialog(cita),
          onComplete: () => _completarCita(cita),
        );
      },
    );
  }

  Widget _buildCitasLista(List<Cita> citas, String titulo) {
    if (citas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No hay $titulo',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Presiona el botón + para agendar una nueva cita',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(citasProvider.notifier).refreshAll();
      },
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: citas.length,
        itemBuilder: (context, index) {
          final cita = citas[index];
          return CitaCard(
            cita: cita,
            onEdit: () => _showEditCitaDialog(cita),
            onDelete: () => _showDeleteConfirmation(cita),
            onConfirm: () => _confirmarCita(cita),
            onCancel: () => _showCancelDialog(cita),
            onComplete: () => _completarCita(cita),
          );
        },
      ),
    );
  }

  void _toggleVista() {
    setState(() {
      _vistaCalendario = !_vistaCalendario;
    });
  }

  void _showCreateCitaDialog() {
    showDialog(
      context: context,
      builder: (context) => CitaFormDialog(
        onSave: (pacienteId, psicologoId, fechaHora, duracion, tipo, notas, motivoConsulta, esOnline, costo) {
          ref.read(citasProvider.notifier).createCita(
            pacienteId: pacienteId,
            psicologoId: psicologoId,
            fechaHora: fechaHora,
            duracion: duracion,
            tipo: tipo,
            notas: notas,
            motivoConsulta: motivoConsulta,
            esOnline: esOnline,
            costo: costo,
          );
        },
      ),
    );
  }

  void _showEditCitaDialog(Cita cita) {
    showDialog(
      context: context,
      builder: (context) => CitaFormDialog(
        cita: cita,
        onSave: (pacienteId, psicologoId, fechaHora, duracion, tipo, notas, motivoConsulta, esOnline, costo) {
          ref.read(citasProvider.notifier).updateCita(
            id: cita.id,
            fechaHora: fechaHora,
            duracion: duracion,
            tipo: tipo,
            notas: notas,
            motivoConsulta: motivoConsulta,
            esOnline: esOnline,
            costo: costo,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Cita cita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Cita'),
        content: Text('¿Estás seguro de que deseas eliminar la cita con ${cita.pacienteId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(citasProvider.notifier).deleteCita(cita.id);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmarCita(Cita cita) {
    ref.read(citasProvider.notifier).confirmarCita(cita.id);
  }

  void _showCancelDialog(Cita cita) {
    final TextEditingController motivoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancelar Cita'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Estás seguro de que deseas cancelar esta cita?'),
            SizedBox(height: 16.h),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo de cancelación',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (motivoController.text.trim().isNotEmpty) {
                ref.read(citasProvider.notifier).cancelarCita(cita.id, motivoController.text);
              }
            },
            child: Text('Confirmar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _completarCita(Cita cita) {
    ref.read(citasProvider.notifier).completarCita(cita.id);
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
