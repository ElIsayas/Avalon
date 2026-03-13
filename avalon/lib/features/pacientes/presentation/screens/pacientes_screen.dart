import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/paciente_provider.dart';
import '../widgets/paciente_form_dialog.dart';
import '../widgets/paciente_card.dart';
import '../widgets/paciente_search_delegate.dart';

class PacientesScreen extends ConsumerStatefulWidget {
  const PacientesScreen({super.key});

  @override
  ConsumerState<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends ConsumerState<PacientesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pacientesProvider.notifier).loadPacientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pacientesState = ref.watch(pacientesProvider);

    ref.listen<PacientesState>(pacientesProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(pacientesProvider.notifier).clearMessages();
      }
      
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(pacientesProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Gestión de Pacientes',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(),
            icon: const Icon(Icons.search),
            tooltip: 'Buscar pacientes',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'activos') {
                setState(() {
                  _showOnlyActive = !_showOnlyActive;
                });
                if (_showOnlyActive) {
                  ref.read(pacientesProvider.notifier).loadPacientesActivos();
                } else {
                  ref.read(pacientesProvider.notifier).loadPacientes();
                }
              } else if (value == 'refresh') {
                if (_showOnlyActive) {
                  ref.read(pacientesProvider.notifier).loadPacientesActivos();
                } else {
                  ref.read(pacientesProvider.notifier).loadPacientes();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'activos',
                child: Row(
                  children: [
                    Icon(
                      _showOnlyActive ? Icons.check_box : Icons.check_box_outline_blank,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text('Solo activos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Actualizar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildEstadisticsCard(pacientesState),
          Expanded(
            child: pacientesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pacientesState.pacientes.isEmpty
                    ? _buildEmptyState()
                    : _buildPacientesList(pacientesState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePacienteDialog(),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Nuevo Paciente',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEstadisticsCard(PacientesState state) {
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
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Pacientes',
            state.totalCount.toString(),
            Icons.people,
            Colors.white,
          ),
          _buildStatItem(
            'Activos',
            state.activeCount.toString(),
            Icons.person,
            Colors.green[300]!,
          ),
          _buildStatItem(
            'Inactivos',
            (state.totalCount - state.activeCount).toString(),
            Icons.person_off,
            Colors.red[300]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32.sp, color: color),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24.sp,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No hay pacientes registrados',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Presiona el botón + para agregar un nuevo paciente',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacientesList(PacientesState state) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_showOnlyActive) {
          await ref.read(pacientesProvider.notifier).loadPacientesActivos();
        } else {
          await ref.read(pacientesProvider.notifier).loadPacientes();
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: state.pacientes.length,
        itemBuilder: (context, index) {
          final paciente = state.pacientes[index];
          return PacienteCard(
            paciente: paciente,
            onEdit: () => _showEditPacienteDialog(paciente),
            onDelete: () => _showDeleteConfirmation(paciente),
            onToggleStatus: () => _togglePacienteStatus(paciente),
            onView: () => _showPacienteDetails(paciente),
          );
        },
      ),
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: PacienteSearchDelegate(ref),
    );
  }

  void _showCreatePacienteDialog() {
    showDialog(
      context: context,
      builder: (context) => PacienteFormDialog(
        onSave: (nombre, email, numeroDocumento, telefono, direccion, fechaNacimiento, historialMedico) {
          ref.read(pacientesProvider.notifier).createPaciente(
            nombre: nombre,
            email: email,
            numeroDocumento: numeroDocumento,
            telefono: telefono,
            direccion: direccion,
            fechaNacimiento: fechaNacimiento,
            historialMedico: historialMedico,
          );
        },
      ),
    );
  }

  void _showEditPacienteDialog(paciente) {
    showDialog(
      context: context,
      builder: (context) => PacienteFormDialog(
        paciente: paciente,
        onSave: (nombre, email, numeroDocumento, telefono, direccion, fechaNacimiento, historialMedico) {
          ref.read(pacientesProvider.notifier).updatePaciente(
            id: paciente.id,
            nombre: nombre,
            email: email,
            telefono: telefono,
            direccion: direccion,
            fechaNacimiento: fechaNacimiento,
            historialMedico: historialMedico,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(paciente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Paciente'),
        content: Text('¿Estás seguro de que deseas eliminar a ${paciente.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(pacientesProvider.notifier).deletePaciente(paciente.id);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _togglePacienteStatus(paciente) {
    final action = paciente.activo ? 'desactivar' : 'activar';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Paciente'),
        content: Text('¿Estás seguro de que deseas $action a ${paciente.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(pacientesProvider.notifier).desactivarPaciente(paciente.id);
            },
            child: Text(action, style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showPacienteDetails(paciente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Paciente'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', paciente.nombre),
              _buildDetailRow('Email:', paciente.email),
              if (paciente.telefono != null) _buildDetailRow('Teléfono:', paciente.telefono!),
              if (paciente.direccion != null) _buildDetailRow('Dirección:', paciente.direccion!),
              if (paciente.fechaNacimiento != null)
                _buildDetailRow('Fecha Nacimiento:', _formatDate(paciente.fechaNacimiento!)),
              if (paciente.historialMedico != null)
                _buildDetailRow('Historial Médico:', paciente.historialMedico!),
              _buildDetailRow('Estado:', paciente.activo ? 'Activo' : 'Inactivo'),
              _buildDetailRow('Fecha Registro:', _formatDate(paciente.fechaRegistro)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
