import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/paciente_provider.dart';
import '../../domain/entities/paciente.dart';

class MisPacientesScreenFinal extends ConsumerStatefulWidget {
  const MisPacientesScreenFinal({super.key});

  @override
  ConsumerState<MisPacientesScreenFinal> createState() => _MisPacientesScreenFinalState();
}

class _MisPacientesScreenFinalState extends ConsumerState<MisPacientesScreenFinal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPacientes() async {
    final notifier = ref.read(pacientesProvider.notifier);
    await notifier.loadPacientes();
  }

  void _showPacienteDetails(Paciente paciente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Paciente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', paciente.id),
              _buildDetailRow('Nombre', paciente.nombre),
              _buildDetailRow('Email', paciente.email),
              _buildDetailRow('Teléfono', paciente.telefono ?? 'N/A'),
              _buildDetailRow('Documento', paciente.numeroDocumento),
              _buildDetailRow('Estado', paciente.activo ? 'Activo' : 'Inactivo'),
              _buildDetailRow('Fecha Registro', _formatDate(paciente.fechaRegistro)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
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
            width: 100.w,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pacientesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Pacientes',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        foregroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: _refreshPacientes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar pacientes',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value != null) {
                setState(() {
                  _selectedFilter = value;
                });
                _filterPacientes();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Row(
                  children: [
                    const Icon(Icons.list, size: 16),
                    SizedBox(width: 8),
                    const Text('Todos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'activos',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    const Text('Activos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'inactivos',
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    const Text('Inactivos'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar pacientes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14.sp),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _filterPacientes();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCreatePacienteDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.w,
                            color: Colors.red[400],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Ocurrió un error',
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              color: Colors.red[700],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            state.error!,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton.icon(
                            onPressed: _refreshPacientes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : _buildPacientesList(state.pacientes),
          ),
        ],
      ),
    );
  }

  void _filterPacientes() {
    final state = ref.read(pacientesProvider);
    final allPacientes = state.pacientes;
    
    List<Paciente> filteredPacientes = [];
    
    if (_searchQuery.isNotEmpty) {
      filteredPacientes = allPacientes.where((paciente) {
        final nombre = paciente.nombre.toLowerCase();
        final email = paciente.email.toLowerCase();
        final documento = paciente.numeroDocumento.toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return nombre.contains(query) || 
               email.contains(query) || 
               documento.contains(query);
      }).toList();
    } else {
      filteredPacientes = allPacientes;
    }
    
    switch (_selectedFilter) {
      case 'activos':
        filteredPacientes = filteredPacientes.where((p) => p.activo).toList();
        break;
      case 'inactivos':
        filteredPacientes = filteredPacientes.where((p) => !p.activo).toList();
        break;
      case 'todos':
      default:
        break;
    }
    
    final notifier = ref.read(pacientesProvider.notifier);
    notifier.updatePacientes(filteredPacientes);
  }

  Widget _buildPacientesList(List<Paciente> pacientes) {
    if (pacientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No tienes pacientes registrados',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _showCreatePacienteDialog,
              icon: const Icon(Icons.add),
              label: const Text('Crear Primer Paciente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: pacientes.length,
      itemBuilder: (context, index) {
        final paciente = pacientes[index];
        return _buildPacienteCard(paciente);
      },
    );
  }

  Widget _buildPacienteCard(Paciente paciente) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 4,
      child: InkWell(
        onTap: () => _showPacienteDetails(paciente),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: paciente.activo ? Colors.green : Colors.grey,
                    child: Icon(
                      paciente.activo ? Icons.person : Icons.person_outline,
                      color: Colors.white,
                      size: 20.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paciente.nombre,
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          paciente.email,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: paciente.activo ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          paciente.activo ? 'Activo' : 'Inactivo',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: paciente.activo ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'ID: ${paciente.id.substring(0, 8)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePacienteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Paciente'),
        content: Text('Funcionalidad de creación de pacientes disponible próximamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
