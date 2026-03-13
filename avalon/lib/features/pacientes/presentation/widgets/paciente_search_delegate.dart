import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/paciente_provider.dart';
import 'paciente_card.dart';

class PacienteSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  PacienteSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return _buildEmptySearch();
    }

    return FutureBuilder<void>(
      future: ref.read(pacientesProvider.notifier).buscarPacientes(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Consumer(
          builder: (context, ref, _) {
            final pacientesState = ref.watch(pacientesProvider);

            if (pacientesState.pacientes.isEmpty) {
              return _buildNoResults();
            }

            return ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: pacientesState.pacientes.length,
              itemBuilder: (context, index) {
                final paciente = pacientesState.pacientes[index];
                return PacienteCard(
                  paciente: paciente,
                  onEdit: () => _editPaciente(context, paciente),
                  onDelete: () => _deletePaciente(context, paciente),
                  onToggleStatus: () => _toggleStatus(context, paciente),
                  onView: () => _viewPaciente(context, paciente),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return _buildRecentSearches();
    }

    return FutureBuilder<void>(
      future: ref.read(pacientesProvider.notifier).buscarPacientes(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Consumer(
          builder: (context, ref, _) {
            final pacientesState = ref.watch(pacientesProvider);

            if (pacientesState.pacientes.isEmpty) {
              return _buildNoSuggestions();
            }

            return ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: pacientesState.pacientes.length,
              itemBuilder: (context, index) {
                final paciente = pacientesState.pacientes[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: paciente.activo 
                        ? Colors.green.withValues(alpha:0.2) 
                        : Colors.grey.withValues(alpha:0.2),
                    child: Icon(
                      Icons.person,
                      color: paciente.activo ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(
                    paciente.nombre,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(paciente.email),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: paciente.activo 
                          ? Colors.green.withValues(alpha:0.2) 
                          : Colors.red.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      paciente.activo ? 'Activo' : 'Inactivo',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: paciente.activo ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  onTap: () {
                    close(context, paciente.id);
                    _viewPaciente(context, paciente);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'Buscar pacientes',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Escribe el nombre, email o teléfono del paciente',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No se encontraron resultados',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Intenta con otra búsqueda',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSuggestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'Sin sugerencias',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Escribe más caracteres para ver sugerencias',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Consumer(
      builder: (context, ref, _) {
        final pacientesState = ref.watch(pacientesProvider);
        
        if (pacientesState.pacientes.isEmpty) {
          return _buildEmptySearch();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Text(
                'Todos los pacientes',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: pacientesState.pacientes.length,
                itemBuilder: (context, index) {
                  final paciente = pacientesState.pacientes[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: paciente.activo 
                          ? Colors.green.withValues(alpha:0.2) 
                          : Colors.grey.withValues(alpha:0.2),
                      child: Icon(
                        Icons.person,
                        color: paciente.activo ? Colors.green : Colors.grey,
                      ),
                    ),
                    title: Text(
                      paciente.nombre,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(paciente.email),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: paciente.activo 
                            ? Colors.green.withValues(alpha:0.2) 
                            : Colors.red.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        paciente.activo ? 'Activo' : 'Inactivo',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: paciente.activo ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    onTap: () {
                      close(context, paciente.id);
                      _viewPaciente(context, paciente);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewPaciente(BuildContext context, paciente) {
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

  void _editPaciente(BuildContext context, paciente) {
    close(context, paciente.id);
  }

  void _deletePaciente(BuildContext context, paciente) {
    close(context, paciente.id);
  }

  void _toggleStatus(BuildContext context, paciente) {
    close(context, paciente.id);
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
