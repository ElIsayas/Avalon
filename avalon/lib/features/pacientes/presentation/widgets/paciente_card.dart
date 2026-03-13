import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/paciente.dart';

class PacienteCard extends StatelessWidget {
  final Paciente paciente;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final VoidCallback onView;

  const PacienteCard({
    super.key,
    required this.paciente,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onView,
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: paciente.activo 
                        ? Colors.green.withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: paciente.activo ? Colors.green : Colors.grey,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                paciente.nombre,
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: paciente.activo 
                                    ? Colors.green.withOpacity(0.2) 
                                    : Colors.red.withOpacity(0.2),
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
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          paciente.email,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (paciente.telefono != null || paciente.direccion != null) ...[
                SizedBox(height: 12.h),
                Container(
                  height: 1.h,
                  color: Colors.grey[200],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    if (paciente.telefono != null) ...[
                      Icon(Icons.phone, size: 16.sp, color: Colors.grey[600]),
                      SizedBox(width: 6.w),
                      Text(
                        paciente.telefono!,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    if (paciente.telefono != null && paciente.direccion != null) ...[
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
                    if (paciente.direccion != null) ...[
                      Icon(Icons.location_on, size: 16.sp, color: Colors.grey[600]),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          paciente.direccion!,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onView,
                    icon: Icon(Icons.visibility, size: 16.sp),
                    label: Text(
                      'Ver',
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, size: 16.sp),
                    label: Text(
                      'Editar',
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TextButton.icon(
                    onPressed: onToggleStatus,
                    icon: Icon(
                      paciente.activo ? Icons.person_off : Icons.person,
                      size: 16.sp,
                    ),
                    label: Text(
                      paciente.activo ? 'Desactivar' : 'Activar',
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: paciente.activo ? Colors.red : Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete, size: 16.sp),
                    label: Text(
                      'Eliminar',
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
}
