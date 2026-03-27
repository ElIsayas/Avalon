import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/citas/domain/cita.dart';
import '../../../../features/citas/presentation/providers/citas_provider.dart';
import '../../../../features/citas/presentation/screens/cita_detalle_screen.dart';
import '../../../../features/evaluaciones/domain/evaluacion.dart';
import '../../../../features/evaluaciones/presentation/providers/evaluaciones_provider.dart';
import '../../../../features/evaluaciones/presentation/screens/evaluacion_detalle_screen.dart';
import '../../../../features/notas/domain/nota_terapia.dart';
import '../../../../features/notas/presentation/providers/notas_provider.dart';
import '../../../../features/notas/presentation/screens/nota_detalle_screen.dart';
import '../../../../features/pacientes/domain/paciente.dart';
import '../../../../features/pacientes/presentation/providers/paciente_provider.dart';
import '../../../../features/pacientes/presentation/screens/paciente_detalle_screen.dart';
import '../../../../features/recordatorios/domain/recordatorio_ex.dart';
import '../../../../features/recordatorios/presentation/providers/recordatorios_provider.dart';
import '../../../../features/recordatorios/presentation/screens/recordatorios_screen.dart';

class _Resultado {
  final String tipo;
  final String titulo;
  final String subtitulo;
  final String? metadato;
  final dynamic objeto;

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
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  String _query = '';
  String _filtro = 'todo';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _cargarDatosIniciales());
  }

  Future<void> _cargarDatosIniciales() async {
    final tareas = <Future<void>>[];

    if (ref.read(pacientesProvider).pacientes.isEmpty) {
      tareas.add(ref.read(pacientesProvider.notifier).cargar());
    }

    final citas = ref.read(citasProvider);
    if (citas.citas.isEmpty &&
        citas.citasHoy.isEmpty &&
        citas.citasSemana.isEmpty) {
      tareas.add(ref.read(citasProvider.notifier).cargarTodo());
    }

    if (ref.read(notasProvider).notas.isEmpty) {
      tareas.add(ref.read(notasProvider.notifier).cargarTodas());
    }

    if (ref.read(recordatoriosExProvider).recordatorios.isEmpty) {
      tareas.add(ref.read(recordatoriosExProvider.notifier).cargar());
    }

    if (ref.read(evaluacionesProvider).evaluaciones.isEmpty) {
      tareas.add(ref.read(evaluacionesProvider.notifier).cargar());
    }

    if (tareas.isNotEmpty) {
      await Future.wait(tareas);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  List<_Resultado> _buscar({
    required List<Paciente> pacientes,
    required CitasState citasState,
    required List<NotaTerapia> notas,
    required List<RecordatorioEx> recordatorios,
    required List<Evaluacion> evaluaciones,
  }) {
    final q = _query.toLowerCase().trim();
    if (q.length < 2) return [];

    final resultados = <_Resultado>[];

    if (_filtro == 'todo' || _filtro == 'pacientes') {
      for (final p in pacientes) {
        if (p.nombre.toLowerCase().contains(q) ||
            p.email.toLowerCase().contains(q) ||
            p.numeroDocumento.toLowerCase().contains(q) ||
            (p.telefono?.toLowerCase().contains(q) ?? false)) {
          resultados.add(
            _Resultado(
              tipo: 'paciente',
              titulo: p.nombre,
              subtitulo: p.email,
              metadato: p.activo ? 'Activo' : 'Inactivo',
              objeto: p,
            ),
          );
        }
      }
    }

    if (_filtro == 'todo' || _filtro == 'citas') {
      final todasCitas = <Cita>{
        ...citasState.citasHoy,
        ...citasState.citasSemana,
        ...citasState.citas,
      }.toList();

      for (final c in todasCitas) {
        final paciente = (c.pacienteNombre ?? c.pacienteId).toLowerCase();
        final psicologo = (c.psicologoNombre ?? c.psicologoId).toLowerCase();
        final tipo = c.tipoSesion.label.toLowerCase();
        final estado = c.estadoLabel.toLowerCase();

        if (paciente.contains(q) ||
            psicologo.contains(q) ||
            tipo.contains(q) ||
            estado.contains(q)) {
          resultados.add(
            _Resultado(
              tipo: 'cita',
              titulo: c.pacienteNombre ?? c.pacienteId,
              subtitulo:
                  '${c.tipoSesion.label} · ${c.psicologoNombre ?? c.psicologoId}',
              metadato: DateFormat('dd/MM/yy HH:mm').format(c.fechaHora),
              objeto: c,
            ),
          );
        }
      }
    }

    if (_filtro == 'todo' || _filtro == 'notas') {
      for (final n in notas) {
        if (n.contenido.toLowerCase().contains(q) ||
            (n.pacienteNombre?.toLowerCase().contains(q) ?? false)) {
          resultados.add(
            _Resultado(
              tipo: 'nota',
              titulo: n.pacienteNombre ?? n.pacienteId,
              subtitulo: n.contenido.length > 80
                  ? '${n.contenido.substring(0, 80)}...'
                  : n.contenido,
              metadato: n.tipo.label,
              objeto: n,
            ),
          );
        }
      }
    }

    if (_filtro == 'todo' || _filtro == 'recordatorios') {
      for (final r in recordatorios) {
        final texto =
            '${r.titulo} ${r.descripcion ?? ""} ${r.creadoPorNombre ?? ""} '
                    '${r.asignadoANombre ?? ""} ${r.categoria.label} ${r.prioridadLabel}'
                .toLowerCase();
        if (texto.contains(q)) {
          resultados.add(
            _Resultado(
              tipo: 'recordatorio',
              titulo: r.titulo,
              subtitulo: r.descripcion?.trim().isNotEmpty == true
                  ? r.descripcion!
                  : (r.asignadoANombre != null
                      ? 'Asignado a ${r.asignadoANombre}'
                      : 'Recordatorio general'),
              metadato: r.resuelto ? 'Resuelto' : r.prioridadLabel,
              objeto: r,
            ),
          );
        }
      }
    }

    if (_filtro == 'todo' || _filtro == 'evaluaciones') {
      for (final e in evaluaciones) {
        final texto = '${e.pacienteNombre ?? e.pacienteId} ${e.escalaEnum.nombre} '
                '${e.interpretacion ?? ""} ${e.observaciones ?? ""} ${e.nivelSeveridad}'
            .toLowerCase();
        if (texto.contains(q)) {
          resultados.add(
            _Resultado(
              tipo: 'evaluacion',
              titulo: e.pacienteNombre ?? e.pacienteId,
              subtitulo:
                  '${e.escalaEnum.nombre} · Puntaje ${e.puntuacionTotal}',
              metadato: DateFormat('dd/MM/yy').format(e.fechaCreacion),
              objeto: e,
            ),
          );
        }
      }
    }

    return resultados;
  }

  void _abrir(_Resultado r) {
    if (r.objeto is Paciente) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                PacienteDetalleScreen(paciente: r.objeto as Paciente)),
      );
      return;
    }
    if (r.objeto is Cita) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CitaDetalleScreen(cita: r.objeto as Cita)),
      );
      return;
    }
    if (r.objeto is NotaTerapia) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => NotaDetalleScreen(nota: r.objeto as NotaTerapia)),
      );
      return;
    }
    if (r.objeto is Evaluacion) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                EvaluacionDetalleScreen(evaluacion: r.objeto as Evaluacion)),
      );
      return;
    }
    if (r.objeto is RecordatorioEx) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RecordatoriosScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pacientes = ref.watch(pacientesProvider).pacientes;
    final citasState = ref.watch(citasProvider);
    final notas = ref.watch(notasProvider).notas;
    final recordatorios = ref.watch(recordatoriosExProvider).recordatorios;
    final evaluaciones = ref.watch(evaluacionesProvider).evaluaciones;
    final resultados = _buscar(
      pacientes: pacientes,
      citasState: citasState,
      notas: notas,
      recordatorios: recordatorios,
      evaluaciones: evaluaciones,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: const TextStyle(color: Colors.white),
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText:
                'Buscar pacientes, citas, notas, recordatorios, evaluaciones...',
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
                _debounce?.cancel();
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: desktopWrap(
        context,
        Column(
          children: [
            Container(
              color: Theme.of(context).cardColor,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FiltroChip('Todo', 'todo', _filtro,
                        (v) => setState(() => _filtro = v)),
                    _FiltroChip(
                      'Pacientes',
                      'pacientes',
                      _filtro,
                      (v) => setState(() => _filtro = v),
                    ),
                    _FiltroChip('Citas', 'citas', _filtro,
                        (v) => setState(() => _filtro = v)),
                    _FiltroChip('Notas', 'notas', _filtro,
                        (v) => setState(() => _filtro = v)),
                    _FiltroChip(
                      'Recordatorios',
                      'recordatorios',
                      _filtro,
                      (v) => setState(() => _filtro = v),
                    ),
                    _FiltroChip(
                      'Evaluaciones',
                      'evaluaciones',
                      _filtro,
                      (v) => setState(() => _filtro = v),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.divider),
            Expanded(
              child: _query.length < 2
                  ? const _Sugerencias()
                  : resultados.isEmpty
                      ? _SinResultados(query: _query)
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          itemCount: resultados.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AppTheme.divider),
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

class _FiltroChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
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

  const _ResultadoTile({
    required this.resultado,
    required this.query,
    required this.onTap,
  });

  IconData get _icon {
    switch (resultado.tipo) {
      case 'paciente':
        return Iconsax.user;
      case 'cita':
        return Iconsax.calendar_2;
      case 'nota':
        return Iconsax.note;
      case 'recordatorio':
        return Iconsax.notification;
      case 'evaluacion':
        return Iconsax.chart_1;
      default:
        return Icons.search;
    }
  }

  Color get _color {
    switch (resultado.tipo) {
      case 'paciente':
        return AppTheme.primary;
      case 'cita':
        return AppTheme.secondary;
      case 'nota':
        return AppTheme.warning;
      case 'recordatorio':
        return AppTheme.accent;
      case 'evaluacion':
        return const Color(0xFF7C3AED);
      default:
        return AppTheme.textGrey;
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
          _TextoResaltado(
            resultado.subtitulo,
            query,
            style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.textGrey),
            maxLines: 2,
          ),
        ],
      ),
      trailing: resultado.metadato != null
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
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

class _TextoResaltado extends StatelessWidget {
  final String texto;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  const _TextoResaltado(
    this.texto,
    this.query, {
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ??
        GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500);
    final q = query.toLowerCase();
    final t = texto.toLowerCase();
    final idx = t.indexOf(q);

    if (idx == -1 || q.isEmpty) {
      return Text(texto,
          style: base, maxLines: maxLines, overflow: TextOverflow.ellipsis);
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
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            ),
          ),
          TextSpan(text: texto.substring(idx + q.length)),
        ],
      ),
    );
  }
}

class _Sugerencias extends StatelessWidget {
  const _Sugerencias();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search,
              size: 64.sp, color: AppTheme.textGrey.withValues(alpha: 0.3)),
          SizedBox(height: 12.h),
          Text(
            'Escribe al menos 2 caracteres',
            style: GoogleFonts.inter(fontSize: 15.sp, color: AppTheme.textGrey),
          ),
          SizedBox(height: 4.h),
          Text(
            'Busca por nombre, email, documento, contenido y mas',
            style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  final String query;
  const _SinResultados({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 64.sp, color: AppTheme.textGrey.withValues(alpha: 0.3)),
          SizedBox(height: 12.h),
          Text(
            'Sin resultados para "$query"',
            style: GoogleFonts.inter(fontSize: 15.sp, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}
