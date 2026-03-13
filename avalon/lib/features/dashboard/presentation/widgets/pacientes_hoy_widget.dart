import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../citas/presentation/providers/cita_provider.dart';

class PacientesHoyWidget extends ConsumerWidget {
  const PacientesHoyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citasState = ref.watch(citasProvider);
    
    // Obtener pacientes con citas hoy
    final pacientesHoy = _getPacientesConCitasHoy(citasState.citasHoy);

    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.people_alt,
                  color: Colors.white,
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pacientes de Hoy',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${pacientesHoy.length} pacientes agendados',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pacientesHoy.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${DateTime.now().day}/${DateTime.now().month}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // Lista de pacientes
            if (pacientesHoy.isEmpty)
              _buildEmptyState()
            else
              Expanded(
                child: _buildPacientesList(pacientesHoy, citasState.citasHoy),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48.sp,
            color: Colors.white70,
          ),
          SizedBox(height: 12.h),
          Text(
            'No hay pacientes agendados hoy',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Disfruta de tu día libre',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacientesList(List<String> pacientesIds, List citas) {
    // Agrupar citas por paciente
    final Map<String, List> citasPorPaciente = {};
    for (final cita in citas) {
      final pacienteId = cita.pacienteId;
      if (!citasPorPaciente.containsKey(pacienteId)) {
        citasPorPaciente[pacienteId] = [];
      }
      citasPorPaciente[pacienteId]!.add(cita);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pacientesIds.length,
      itemBuilder: (context, index) {
        final pacienteId = pacientesIds[index];
        final citasDelPaciente = citasPorPaciente[pacienteId] ?? [];
        
        return _buildPacienteCard(pacienteId, citasDelPaciente);
      },
    );
  }

  Widget _buildPacienteCard(String pacienteId, List citas) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del paciente
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paciente ID: ${pacienteId.substring(0, 8)}...',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${citas.length} cita(s) hoy',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Lista de citas del paciente
          if (citas.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ...citas.map((cita) => _buildCitaItem(cita)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildCitaItem(cita) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16.sp,
            color: Colors.white70,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cita.horaFormateada}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  cita.tipo.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: cita.estado.color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              cita.estado.displayName,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: cita.estado.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getPacientesConCitasHoy(List citas) {
    final Set<String> pacientesIds = {};
    for (final cita in citas) {
      pacientesIds.add(cita.pacienteId);
    }
    return pacientesIds.toList();
  }
}
