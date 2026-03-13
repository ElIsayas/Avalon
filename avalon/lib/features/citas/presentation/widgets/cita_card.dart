import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/cita.dart';

class CitaCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const CitaCard({
    super.key,
    required this.cita,
    required this.onEdit,
    required this.onDelete,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: cita.estado.color.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showCitaDetails(context),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado y hora
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: cita.estado.color.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12.r),
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
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    cita.horaFormateada,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Información principal
              Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: cita.esOnline 
                        ? Colors.blue.withValues(alpha:0.2) 
                        : Colors.green.withValues(alpha:0.2),
                    child: Icon(
                      cita.esOnline ? Icons.videocam : Icons.person,
                      color: cita.esOnline ? Colors.blue : Colors.green,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paciente: ${cita.pacienteId}',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          cita.tipo.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Duración y tipo de sesión
              if (cita.duracion.inMinutes > 0 || cita.esOnline) ...[
                SizedBox(height: 12.h),
                Container(
                  height: 1.h,
                  color: Colors.grey[200],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    if (cita.duracion.inMinutes > 0) ...[
                      Icon(Icons.timer, size: 16.sp, color: Colors.grey[600]),
                      SizedBox(width: 6.w),
                      Text(
                        cita.duracionFormateada,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    if (cita.duracion.inMinutes > 0 && cita.esOnline) ...[
                      SizedBox(width: 16.w),
                      Container(
                        width: 4.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 16.w),
                    ],
                    if (cita.esOnline) ...[
                      Icon(Icons.videocam, size: 16.sp, color: Colors.blue),
                      SizedBox(width: 6.w),
                      Text(
                        'Online',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              // Motivo de consulta
              if (cita.motivoConsulta != null && cita.motivoConsulta!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motivo:',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        cita.motivoConsulta!,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              
              // Botones de acción
              SizedBox(height: 16.h),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón de confirmar (solo si está agendada)
        if (cita.puedeConfirmar)
          TextButton.icon(
            onPressed: onConfirm,
            icon: Icon(Icons.check, size: 16.sp),
            label: Text(
              'Confirmar',
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        
        // Botón de completar (solo si está confirmada)
        if (cita.puedeIniciar)
          TextButton.icon(
            onPressed: onComplete,
            icon: Icon(Icons.play_arrow, size: 16.sp),
            label: Text(
              'Iniciar',
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        
        // Botón de cancelar
        if (cita.puedeCancelar)
          TextButton.icon(
            onPressed: onCancel,
            icon: Icon(Icons.cancel, size: 16.sp),
            label: Text(
              'Cancelar',
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        
        // Botón de editar
        if (cita.puedeReprogramar)
          TextButton.icon(
            onPressed: onEdit,
            icon: Icon(Icons.edit, size: 16.sp),
            label: Text(
              'Editar',
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        
        // Botón de eliminar (solo si está agendada)
        if (cita.estado == EstadoCita.agendada && !cita.esPasada)
          TextButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete, size: 16.sp),
            label: Text(
              'Eliminar',
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  void _showCitaDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event, color: cita.estado.color),
            SizedBox(width: 8.w),
            Text('Detalles de la Cita'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Estado:', cita.estado.displayName),
              _buildDetailRow('Fecha:', cita.fechaFormateada),
              _buildDetailRow('Hora:', cita.horaFormateada),
              _buildDetailRow('Duración:', cita.duracionFormateada),
              _buildDetailRow('Tipo:', cita.tipo.displayName),
              _buildDetailRow('Paciente ID:', cita.pacienteId),
              _buildDetailRow('Psicólogo ID:', cita.psicologoId),
              _buildDetailRow('Modalidad:', cita.esOnline ? 'Online' : 'Presencial'),
              if (cita.costo != null)
                _buildDetailRow('Costo:', '\$${cita.costo!.toStringAsFixed(2)}'),
              if (cita.motivoConsulta != null && cita.motivoConsulta!.isNotEmpty)
                _buildDetailRow('Motivo:', cita.motivoConsulta!),
              if (cita.notas != null && cita.notas!.isNotEmpty)
                _buildDetailRow('Notas:', cita.notas!),
              if (cita.linkSesion != null)
                _buildDetailRow('Link Sesión:', cita.linkSesion!),
              _buildDetailRow('Creada:', _formatDateTime(cita.fechaCreacion)),
              if (cita.fechaConfirmacion != null)
                _buildDetailRow('Confirmada:', _formatDateTime(cita.fechaConfirmacion!)),
              if (cita.fechaCancelacion != null) ...[
                _buildDetailRow('Cancelada:', _formatDateTime(cita.fechaCancelacion!)),
                if (cita.motivoCancelacion != null)
                  _buildDetailRow('Motivo Cancelación:', cita.motivoCancelacion!),
              ],
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
