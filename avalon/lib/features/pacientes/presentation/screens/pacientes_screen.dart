import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/paciente_provider.dart';
import '../widgets/paciente_form_dialog.dart';
import '../widgets/paciente_card.dart';
import '../widgets/paciente_search_delegate.dart';
import '../../../../models/paciente_model.dart';

class PacientesScreen extends ConsumerStatefulWidget {
  const PacientesScreen({super.key});

  @override
  ConsumerState<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends ConsumerState<PacientesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyActive = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pacientesProvider.notifier).loadPacientes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showUserInfo,
            icon: const Icon(Icons.person),
            tooltip: 'Info del Usuario',
          ),
          IconButton(
            onPressed: _testDatabaseConnection,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Testear conexión DB',
          ),
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search),
            tooltip: 'Buscar pacientes',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle_active':
                  setState(() {
                    _showOnlyActive = !_showOnlyActive;
                  });
                  break;
                case 'refresh':
                  if (_showOnlyActive) {
                    ref.read(pacientesProvider.notifier).loadPacientesActivos();
                  } else {
                    ref.read(pacientesProvider.notifier).loadPacientes();
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_active',
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
          _buildSearchAndFilterBar(pacientesState),
          _buildEstadisticsCard(pacientesState),
          Expanded(
            child: pacientesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredPacientes(pacientesState).isEmpty
                    ? _buildEmptyState()
                    : _buildPacientesList(_getFilteredPacientes(pacientesState)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePacienteDialog,
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

  Widget _buildSearchAndFilterBar(PacientesState state) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar pacientes por nombre, email o documento...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Filtros
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showOnlyActive = !_showOnlyActive;
                    });
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _showOnlyActive ? Colors.blue.withValues(alpha: 0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: _showOnlyActive ? Colors.blue : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showOnlyActive ? Icons.check_box : Icons.check_box_outline_blank,
                          color: _showOnlyActive ? Colors.blue : Colors.grey[600],
                          size: 20.w,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Solo activos',
                          style: GoogleFonts.inter(
                            color: _showOnlyActive ? Colors.blue : Colors.grey[700],
                            fontWeight: _showOnlyActive ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // Botón de búsqueda avanzada
              ElevatedButton.icon(
                onPressed: _showSearchDialog,
                icon: Icon(Icons.search, size: 18.w),
                label: Text('Búsqueda avanzada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Paciente> _getFilteredPacientes(PacientesState state) {
    List<Paciente> pacientes = state.pacientes;
    
    // Filtrar por estado activo
    if (_showOnlyActive) {
      pacientes = pacientes.where((p) => p.activo).toList();
    }
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      pacientes = pacientes.where((p) =>
          p.nombre.toLowerCase().contains(_searchQuery) ||
          p.email.toLowerCase().contains(_searchQuery) ||
          (p.numeroDocumento.toLowerCase().contains(_searchQuery))
      ).toList();
    }
    
    return pacientes;
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
            color: Colors.blue.withValues(alpha:0.3),
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

  Widget _buildPacientesList(List<Paciente> pacientes) {
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
        itemCount: pacientes.length,
        itemBuilder: (context, index) {
          final paciente = pacientes[index];
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

  void _showUserInfo() {
    final authState = ref.read(authProvider);
    final currentUser = authState.user;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Información del Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${currentUser?.id ?? "No disponible"}'),
            SizedBox(height: 8.h),
            Text('Nombre: ${currentUser?.nombre ?? "No disponible"}'),
            SizedBox(height: 8.h),
            Text('Email: ${currentUser?.email ?? "No disponible"}'),
            SizedBox(height: 8.h),
            Text('Rol: ${currentUser?.rol ?? "No disponible"}'),
            SizedBox(height: 8.h),
            Text('Es Administrador: ${currentUser?.isAdministrador ?? false}'),
            SizedBox(height: 8.h),
            Text('Es Psicólogo: ${currentUser?.isPsicologo ?? false}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _testDatabaseConnection() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Iniciando test de conexión a la base de datos...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      final service = ref.read(pacienteServiceProvider);
      final result = await service.testDatabaseConnection();
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test exitoso: ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test fallido: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showEditPacienteDialog(Paciente paciente) {
    showDialog(
      context: context,
      builder: (context) => PacienteFormDialog(
        paciente: paciente,
        onSave: (nombre, email, numeroDocumento, telefono, direccion, fechaNacimiento, historialMedico) {
          ref.read(pacientesProvider.notifier).updatePaciente(
            id: paciente.id,
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

  void _showDeleteConfirmation(Paciente paciente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Paciente'),
        content: Text('¿Estás seguro de que quieres eliminar a ${paciente.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(pacientesProvider.notifier).deletePaciente(paciente.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _togglePacienteStatus(Paciente paciente) {
    ref.read(pacientesProvider.notifier).togglePacienteStatus(paciente.id);
  }

  void _showPacienteDetails(Paciente paciente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(paciente.nombre),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', paciente.email),
              _buildDetailRow('Documento', paciente.numeroDocumento ?? 'No especificado'),
              _buildDetailRow('Teléfono', paciente.telefono ?? 'No especificado'),
              _buildDetailRow('Dirección', paciente.direccion ?? 'No especificado'),
              _buildDetailRow('Fecha de Nacimiento', _formatDate(paciente.fechaNacimiento)),
              _buildDetailRow('Estado', paciente.activo ? 'Activo' : 'Inactivo'),
              if (paciente.historialMedico?.isNotEmpty == true)
                _buildDetailRow('Historial Médico', paciente.historialMedico!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
              '$label:',
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'No especificada';
    return '${date.day}/${date.month}/${date.year}';
  }
}
