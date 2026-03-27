import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../domain/nota_terapia.dart';
import '../providers/notas_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'nota_editor_screen.dart';
import 'nota_detalle_screen.dart';

class NotasScreen extends ConsumerStatefulWidget {
  const NotasScreen({super.key});

  @override
  ConsumerState<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends ConsumerState<NotasScreen> {
  final _searchCtrl = TextEditingController();
  TipoNota? _filtroTipo;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notasProvider.notifier).cargarTodas();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<NotaTerapia> _aplicarFiltros(List<NotaTerapia> notas) {
    var lista = notas;
    if (_filtroTipo != null) {
      lista = lista.where((n) => n.tipo == _filtroTipo).toList();
    }
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista
          .where(
            (n) =>
                n.contenido.toLowerCase().contains(q) ||
                (n.pacienteNombre?.toLowerCase().contains(q) ?? false) ||
                (n.psicologoNombre?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notasProvider);
    final user = ref.watch(currentUserProvider);
    final notas = _aplicarFiltros(state.notas);
    final puedeEscribir = user?.puedeEscribirNotas ?? false;

    // Snackbars
    ref.listen(notasProvider, (_, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(next.successMessage!),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(notasProvider.notifier).clearMessages();
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(next.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(notasProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.notas),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(notasProvider.notifier).cargarTodas(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
            child: Column(
              children: [
                // Buscador
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _busqueda = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar en notas, paciente...',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.white.withValues(alpha: 0.8)),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _busqueda = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
                SizedBox(height: 8.h),
                // Filtro por tipo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FiltroChip(
                        label: context.t.todas,
                        selected: _filtroTipo == null,
                        onTap: () => setState(() => _filtroTipo = null),
                      ),
                      ...TipoNota.values.map((t) => _FiltroChip(
                            label: t.label,
                            selected: _filtroTipo == t,
                            onTap: () => setState(
                              () => _filtroTipo = _filtroTipo == t ? null : t,
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: desktopWrap(
        context,
        state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notas.isEmpty
                ? _Empty(
                    hayFiltro: _busqueda.isNotEmpty || _filtroTipo != null,
                    onCrear: puedeEscribir ? _crearNota : null,
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(notasProvider.notifier).cargarTodas(),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.r),
                      itemCount: notas.length,
                      itemBuilder: (_, i) => _NotaCard(
                        nota: notas[i],
                        onTap: () => _verDetalle(notas[i]),
                        onEditar: !notas[i].firmada && puedeEscribir
                            ? () => _editarNota(notas[i])
                            : null,
                        onEliminar: !notas[i].firmada && puedeEscribir
                            ? () => _confirmarEliminar(notas[i])
                            : null,
                      ),
                    ),
                  ),
      ),
      floatingActionButton: puedeEscribir
          ? FloatingActionButton.extended(
              onPressed: _crearNota,
              icon: const Icon(Icons.add),
              label: Text(context.t.nuevaNota),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _crearNota() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotaEditorScreen()),
    ).then((_) => ref.read(notasProvider.notifier).cargarTodas());
  }

  void _editarNota(NotaTerapia nota) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotaEditorScreen(nota: nota)),
    ).then((_) => ref.read(notasProvider.notifier).cargarTodas());
  }

  void _verDetalle(NotaTerapia nota) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NotaDetalleScreen(nota: nota)),
    ).then((_) => ref.read(notasProvider.notifier).cargarTodas());
  }

  void _confirmarEliminar(NotaTerapia nota) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text(
            'Â¿EstÃ¡s seguro de que deseas eliminar esta nota? Esta acciÃ³n no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(notasProvider.notifier).eliminar(nota.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ WIDGETS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _NotaCard extends StatelessWidget {
  final NotaTerapia nota;
  final VoidCallback onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  const _NotaCard({
    required this.nota,
    required this.onTap,
    this.onEditar,
    this.onEliminar,
  });

  Color get _tipoColor {
    switch (nota.tipo) {
      case TipoNota.sesion:
        return AppTheme.primary;
      case TipoNota.seguimiento:
        return AppTheme.secondary;
      case TipoNota.evaluacion:
        return AppTheme.warning;
      case TipoNota.interconsulta:
        return AppTheme.accent;
      case TipoNota.administrativa:
        return AppTheme.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Tipo badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: _tipoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      nota.tipo.label,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _tipoColor,
                      ),
                    ),
                  ),
                  if (nota.firmada) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              size: 10.sp, color: AppTheme.accent),
                          SizedBox(width: 3.w),
                          Text('Firmada',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (onEditar != null || onEliminar != null)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'editar' && onEditar != null) {
                          onEditar!();
                        }
                        if (v == 'eliminar' && onEliminar != null) {
                          onEliminar!();
                        }
                      },
                      itemBuilder: (_) => [
                        if (onEditar != null)
                          const PopupMenuItem(
                            value: 'editar',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Editar'),
                              dense: true,
                            ),
                          ),
                        if (onEliminar != null)
                          const PopupMenuItem(
                            value: 'eliminar',
                            child: ListTile(
                              leading:
                                  Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Eliminar',
                                  style: TextStyle(color: Colors.red)),
                              dense: true,
                            ),
                          ),
                      ],
                      child: Icon(Icons.more_vert,
                          size: 18.sp, color: AppTheme.textGrey),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              // Contenido (preview)
              Text(
                nota.contenido,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 10.h),
              // Footer
              Row(
                children: [
                  Icon(Iconsax.user, size: 12.sp, color: AppTheme.textGrey),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      nota.pacienteNombre ?? nota.pacienteId,
                      style: GoogleFonts.inter(
                          fontSize: 11.sp, color: AppTheme.textGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Iconsax.clock, size: 12.sp, color: AppTheme.textGrey),
                  SizedBox(width: 4.w),
                  Text(
                    _formatFecha(nota.fechaCreacion),
                    style: GoogleFonts.inter(
                        fontSize: 11.sp, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inDays == 0) return 'Hoy ${DateFormat('HH:mm').format(fecha)}';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} dÃ­as';
    return DateFormat('dd/MM/yy').format(fecha);
  }
}

class _Empty extends StatelessWidget {
  final bool hayFiltro;
  final VoidCallback? onCrear;

  const _Empty({required this.hayFiltro, this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hayFiltro ? Icons.search_off : Iconsax.note,
            size: 72.sp,
            color: AppTheme.textGrey.withValues(alpha: 0.35),
          ),
          SizedBox(height: 16.h),
          Text(
            hayFiltro ? 'Sin resultados' : context.t.sinNotas,
            style: GoogleFonts.inter(fontSize: 18.sp, color: AppTheme.textGrey),
          ),
          SizedBox(height: 8.h),
          Text(
            hayFiltro
                ? 'Intenta con otro filtro o bÃºsqueda'
                : context.t.crearNota,
            style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}
