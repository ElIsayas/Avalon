import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/pacientes/domain/paciente.dart';
import '../../../../features/pacientes/presentation/providers/paciente_provider.dart';
import '../../../../features/pacientes/presentation/screens/paciente_detalle_screen.dart';
import '../../../../features/notas/domain/nota_terapia.dart';
import '../../../../features/notas/presentation/providers/notas_provider.dart';
import '../../../../features/notas/presentation/screens/nota_detalle_screen.dart';
import '../../../../features/citas/domain/cita.dart';
import '../../../../features/citas/presentation/providers/citas_provider.dart';
import '../../../../features/citas/presentation/screens/cita_detalle_screen.dart';

// Resultado unificado de búsqueda
class _Resultado {
  final String tipo;      // 'paciente' | 'cita' | 'nota'
  final String titulo;
  final String subtitulo;
  final String? metadato; // fecha, estado, etc.
  final dynamic objeto;   // Paciente | Cita | NotaTerapia

  const _Resultado({
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    this.metadato,
    required this.objeto,
  });
}

class BusquedaGlobalScreen extends ConsumerStatefulWidget {
  const BusquedaGlobalScreen({super.key});

  @override
  ConsumerState<BusquedaGlobalScreen> createState() =>
      _BusquedaGlobalScreenState();
}

class _BusquedaGlobalScreenState extends ConsumerState<BusquedaGlobalScreen> {
  final _ctrl    = TextEditingController();
  final _focus   = FocusNode();
  String _query  = '';
  String _filtro = 'todo'; // 'todo' | 'pacientes' | 'citas' | 'notas'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<_Resultado> _buscar() {
    final q = _query.toLowerCase().trim();
    if (q.length < 2) return [];

    final resultados = <_Resultado>[];

    // ── Pacientes ──────────────────────────────────────────────────────
    if (_filtro == 'todo' || _filtro == 'pacientes') {
      final pacientes = ref.read(pacientesProvider).pacientes;
      for (final p in pacientes) {
        if (p.nombre.toLowerCase().contains(q) ||
            p.email.toLowerCase().contains(q) ||
            p.numeroDocumento.toLowerCase().contains(q) ||
            (p.telefono?.toLowerCase().contains(q) ?? false)) {
          resultados.add(_Resultado(
            tipo: 'paciente',
            titulo: p.nombre,
            subtitulo: p.email,
            metadato: p.activo ? 'Activo' : 'Inactivo',
            objeto: p,
          ));
        }
      }
    }

    // ── Citas ──────────────────────────────────────────────────────────
    if (_filtro == 'todo' || _filtro == 'citas') {
      final citasState = ref.read(citasProvider);
      final todasCitas = [
        ...citasState.citasHoy,
        ...citasState.citasSemana,
        ...citasState.citas,
      ].toSet().toList(); // eliminar duplicados

      for (final c in todasCitas) {
        final nombre = (c.pacienteNombre ?? c.pacienteId).toLowerCase();
        final psi    = (c.psicologoNombre ?? c.psicologoId).toLowerCase();
        if (nombre.contains(q) || psi.contains(q) ||
            c.tipoSesion.label.toLowerCase().contains(q)) {
          resultados.add(_Resultado(
            tipo: 'cita',
            titulo: c.pacienteNombre ?? c.pacienteId,
            subtitulo: '${c.tipoSesion.label} · ${c.psicologoNombre ?? c.psicologoId}',
            metadato: DateFormat('dd/MM/yy HH:mm').format(c.fechaHora),
            objeto: c,
          ));
        }
      }
    }

    // ── Notas ──────────────────────────────────────────────────────────
    if (_filtro == 'todo' || _filtro == 'notas') {
      final notas = ref.read(notasProvider).notas;
      for (final n in notas) {
        if (n.contenido.toLowerCase().contains(q) ||
            (n.pacienteNombre?.toLowerCase().contains(q) ?? false)) {
          resultados.add(_Resultado(
            tipo: 'nota',
            titulo: n.pacienteNombre ?? n.pacienteId,
            subtitulo: n.contenido.length > 80
                ? '${n.contenido.substring(0, 80)}…'
                : n.contenido,
            metadato: n.tipo.label,
            objeto: n,
          ));
        }
      }
    }

    return resultados;
  }

  void _abrir(_Resultado r) {
    if (r.objeto is Paciente) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => PacienteDetalleScreen(paciente: r.objeto as Paciente)));
    } else if (r.objeto is Cita) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => CitaDetalleScreen(cita: r.objeto as Cita)));
    } else if (r.objeto is NotaTerapia) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => NotaDetalleScreen(nota: r.objeto as NotaTerapia)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _buscar();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Buscar pacientes, citas, notas...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _desktopWrap(
        context,
        Column(
        children: [
          // Filtros
          Container(
            color: Theme.of(context).cardColor,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FiltroChip('Todo',       'todo',      _filtro, (v) => setState(() => _filtro = v)),
                  _FiltroChip('Pacientes',  'pacientes', _filtro, (v) => setState(() => _filtro = v)),
                  _FiltroChip('Citas',      'citas',     _filtro, (v) => setState(() => _filtro = v)),
                  _FiltroChip('Notas',      'notas',     _filtro, (v) => setState(() => _filtro = v)),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppTheme.divider),

          // Resultados
          Expanded(
            child: _query.length < 2
                ? _Sugerencias()
                : resultados.isEmpty
                    ? _SinResultados(query: _query)
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        itemCount: resultados.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppTheme.divider),
                        itemBuilder: (_, i) => _ResultadoTile(
                          resultado: resultados[i],
                          query: _query,
                          onTap: () => _abrir(resultados[i]),
                        ),
                      ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── WIDGETS ───────────────────────────────────────────────────────────────────

class _FiltroChip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;

  const _FiltroChip(this.label, this.value, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ResultadoTile extends StatelessWidget {
  final _Resultado resultado;
  final String query;
  final VoidCallback onTap;

  const _ResultadoTile(
      {required this.resultado, required this.query, required this.onTap});

  IconData get _icon {
    switch (resultado.tipo) {
      case 'paciente': return Iconsax.user;
      case 'cita':     return Iconsax.calendar_2;
      case 'nota':     return Iconsax.note;
      default:         return Icons.search;
    }
  }

  Color get _color {
    switch (resultado.tipo) {
      case 'paciente': return AppTheme.primary;
      case 'cita':     return AppTheme.secondary;
      case 'nota':     return AppTheme.warning;
      default:         return AppTheme.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(_icon, color: _color, size: 18.sp),
      ),
      title: _TextoResaltado(resultado.titulo, query),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TextoResaltado(resultado.subtitulo, query,
              style: GoogleFonts.inter(
                  fontSize: 12.sp, color: AppTheme.textGrey),
              maxLines: 2),
        ],
      ),
      trailing: resultado.metadato != null
          ? Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                resultado.metadato!,
                style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: _color,
                    fontWeight: FontWeight.w500),
              ),
            )
          : null,
    );
  }
}

// Resalta en negrita la parte que coincide con el query
class _TextoResaltado extends StatelessWidget {
  final String texto;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  const _TextoResaltado(this.texto, this.query,
      {this.style, this.maxLines});

  @override
  Widget build(BuildContext context) {
    final base = style ??
        GoogleFonts.inter(
            fontSize: 14.sp, fontWeight: FontWeight.w500);
    final q = query.toLowerCase();
    final t = texto.toLowerCase();
    final idx = t.indexOf(q);

    if (idx == -1 || q.isEmpty) {
      return Text(texto, style: base, maxLines: maxLines,
          overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: texto.substring(0, idx)),
          TextSpan(
            text: texto.substring(idx, idx + q.length),
            style: base.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.1)),
          ),
          TextSpan(text: texto.substring(idx + q.length)),
        ],
      ),
    );
  }
}

class _Sugerencias extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64.sp,
                color: AppTheme.textGrey.withValues(alpha: 0.3)),
            SizedBox(height: 12.h),
            Text('Escribe al menos 2 caracteres',
                style: GoogleFonts.inter(
                    fontSize: 15.sp, color: AppTheme.textGrey)),
            SizedBox(height: 4.h),
            Text('Busca por nombre, email, documento o contenido',
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: AppTheme.textGrey),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _SinResultados extends StatelessWidget {
  final String query;
  const _SinResultados({required this.query});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64.sp,
                color: AppTheme.textGrey.withValues(alpha: 0.3)),
            SizedBox(height: 12.h),
            Text('Sin resultados para "$query"',
                style: GoogleFonts.inter(
                    fontSize: 15.sp, color: AppTheme.textGrey)),
          ],
        ),
      );
}

Widget _desktopWrap(BuildContext context, Widget child) {
  if (!context.isDesktop) return child;
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: child,
    ),
  );
}
