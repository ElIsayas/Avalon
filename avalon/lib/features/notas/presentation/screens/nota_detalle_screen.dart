import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../domain/nota_terapia.dart';
import '../providers/notas_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'nota_editor_screen.dart';

class NotaDetalleScreen extends ConsumerWidget {
  final NotaTerapia nota;

  const NotaDetalleScreen({super.key, required this.nota});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user           = ref.watch(currentUserProvider);
    final puedeEscribir  = user?.puedeEscribirNotas ?? false;
    final state          = ref.watch(notasProvider);

    // Buscar la nota actualizada en el estado (puede haberse modificado)
    final notaActual = state.notas.firstWhere(
      (n) => n.id == nota.id,
      orElse: () => nota,
    );

    Color tipoColor;
    switch (notaActual.tipo) {
      case TipoNota.sesion:         tipoColor = AppTheme.primary;   break;
      case TipoNota.seguimiento:    tipoColor = AppTheme.secondary;  break;
      case TipoNota.evaluacion:     tipoColor = AppTheme.warning;    break;
      case TipoNota.interconsulta:  tipoColor = AppTheme.accent;     break;
      case TipoNota.administrativa: tipoColor = AppTheme.textGrey;   break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(notaActual.tipo.label),
        actions: [
          if (puedeEscribir && !notaActual.firmada)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'editar') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NotaEditorScreen(nota: notaActual)),
                  );
                } else if (v == 'firmar') {
                  _confirmarFirma(context, ref, notaActual.id);
                } else if (v == 'eliminar') {
                  _confirmarEliminar(context, ref, notaActual.id);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar nota'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'firmar',
                  child: ListTile(
                    leading: Icon(Icons.verified_outlined,
                        color: Colors.green),
                    title: Text('Firmar nota',
                        style: TextStyle(color: Colors.green)),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Eliminar',
                        style: TextStyle(color: Colors.red)),
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ResponsiveBody(
        maxWidth: 720,
        child: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: tipoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    notaActual.tipo.label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      color: tipoColor,
                    ),
                  ),
                ),
                if (notaActual.firmada) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified,
                            size: 12.sp, color: AppTheme.accent),
                        SizedBox(width: 4.w),
                        Text('Firmada',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16.h),

            // ── Metadatos ─────────────────────────────────────────────────
            _MetaRow(
              icon: Iconsax.user,
              label: 'Paciente',
              value: notaActual.pacienteNombre ?? notaActual.pacienteId,
            ),
            SizedBox(height: 8.h),
            _MetaRow(
              icon: Iconsax.calendar_2,
              label: 'Creada',
              value: DateFormat('dd/MM/yyyy HH:mm').format(notaActual.fechaCreacion),
            ),
            if (notaActual.fechaCreacion != notaActual.fechaActualizacion) ...[
              SizedBox(height: 8.h),
              _MetaRow(
                icon: Iconsax.edit,
                label: 'Modificada',
                value: DateFormat('dd/MM/yyyy HH:mm')
                    .format(notaActual.fechaActualizacion),
              ),
            ],
            if (notaActual.firmadaEn != null) ...[
              SizedBox(height: 8.h),
              _MetaRow(
                icon: Icons.verified_outlined,
                label: 'Firmada el',
                value: DateFormat('dd/MM/yyyy HH:mm')
                    .format(notaActual.firmadaEn!),
                valueColor: AppTheme.accent,
              ),
            ],
            SizedBox(height: 20.h),

            // ── Divider ───────────────────────────────────────────────────
            Divider(color: AppTheme.divider),
            SizedBox(height: 16.h),

            // ── Contenido ─────────────────────────────────────────────────
            SelectableText(
              notaActual.contenido,
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                height: 1.7,
                color: AppTheme.textDark,
              ),
            ),

            // ── Aviso nota firmada ─────────────────────────────────────────
            if (notaActual.firmada) ...[
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline,
                        size: 16.sp, color: AppTheme.accent),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Esta nota ha sido firmada y no puede modificarse.',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 32.h),
          ],
        ),
      ),
      ),
    );
  }

  void _confirmarFirma(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Firmar nota'),
        content: const Text(
          'Una vez firmada, la nota quedará bloqueada y no podrá modificarse. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(notasProvider.notifier).firmar(id);
            },
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Firmar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text(
            'Esta acción es irreversible. ¿Eliminar la nota?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // Volver a la lista
              await ref.read(notasProvider.notifier).eliminar(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppTheme.textGrey),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
              fontSize: 13.sp, color: AppTheme.textGrey),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
