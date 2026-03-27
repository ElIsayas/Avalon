import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/evaluacion.dart';
import '../providers/evaluaciones_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class EvaluacionFormScreen extends ConsumerStatefulWidget {
  final String? pacienteIdInicial;
  final String? pacienteNombreInicial;

  const EvaluacionFormScreen({
    super.key,
    this.pacienteIdInicial,
    this.pacienteNombreInicial,
  });

  @override
  ConsumerState<EvaluacionFormScreen> createState() =>
      _EvaluacionFormScreenState();
}

class _EvaluacionFormScreenState extends ConsumerState<EvaluacionFormScreen> {
  // Paso 1: seleccionar paciente + escala
  // Paso 2: responder Ã­tems
  // Paso 3: revisar resultado y guardar
  int _paso = 0;

  String? _pacienteId;
  String? _pacienteNombre;
  EscalaEvaluacion _escala = EscalaEvaluacion.phq9;
  List<ItemEscala> _items = [];
  int _itemActual = 0;
  final _obsCtrl = TextEditingController();
  final _puntajeManualCtrl = TextEditingController();
  List<Map<String, dynamic>> _pacientes = [];
  bool _cargandoPacientes = true;

  @override
  void initState() {
    super.initState();
    _pacienteId = widget.pacienteIdInicial;
    _pacienteNombre = widget.pacienteNombreInicial;
    if (_pacienteId != null) _cargandoPacientes = false;
    _cargarPacientes();
    _cargarItems();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    _puntajeManualCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPacientes() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .rpc('get_pacientes', params: {'p_token': user.sessionToken});
      setState(() {
        _pacientes = (res as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _cargandoPacientes = false;
      });
    } catch (_) {
      setState(() => _cargandoPacientes = false);
    }
  }

  void _cargarItems() {
    final raw = kItemsEscalas[_escala.value];
    setState(() {
      _items = raw != null
          ? List<ItemEscala>.from(raw)
          : []; // escala personalizada: sin Ã­tems pre-definidos
      _itemActual = 0;
    });
  }

  int get _puntuacionTotal =>
      _items.fold(0, (s, i) => s + (i.valor >= 0 ? i.valor : 0));

  bool get _esPersonalizada => _escala == EscalaEvaluacion.personalizada;

  int? get _puntajeManual => int.tryParse(_puntajeManualCtrl.text.trim());

  bool get _puntajeManualValido =>
      !_esPersonalizada || ((_puntajeManual ?? 0) > 0);

  int get _puntuacionTotalFinal =>
      _esPersonalizada ? (_puntajeManual ?? 0) : _puntuacionTotal;

  String get _instruccionEscala =>
      kInstruccionesEscalas[_escala.value] ??
      'Responda cada item segun corresponda.';

  bool get _todoRespondido => _items.every((i) => i.respondida);

  Map<int, int> get _respuestasMap =>
      {for (final i in _items) i.numero: i.valor >= 0 ? i.valor : 0};

  void _responder(int valor) {
    setState(() {
      _items[_itemActual] = _items[_itemActual].conValor(valor);
      // Avanzar al siguiente sin responder
      if (_itemActual < _items.length - 1) {
        _itemActual = _items.indexWhere((i) => !i.respondida, _itemActual + 1);
        if (_itemActual == -1) _itemActual = _items.length - 1;
      }
    });
  }

  Future<void> _guardar() async {
    if (_pacienteId == null) return;
    if (_esPersonalizada && !_puntajeManualValido) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('Ingrese un puntaje manual mayor a 0.')),
      );
      return;
    }

    final ev = Evaluacion(
      id: '',
      pacienteId: _pacienteId!,
      psicologoId: '',
      escala: _escala.value,
      puntuacionTotal: _puntuacionTotalFinal,
      respuestas: {for (final e in _respuestasMap.entries) '${e.key}': e.value},
      fechaCreacion: DateTime.now(),
      pacienteNombre: _pacienteNombre,
    );

    final ok = await ref.read(evaluacionesProvider.notifier).crear(
          pacienteId: _pacienteId!,
          escala: _escala.value,
          puntuacionTotal: _puntuacionTotalFinal,
          respuestas: _respuestasMap,
          observaciones:
              _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
          interpretacion: ev.nivelSeveridad != 'â€”' ? ev.nivelSeveridad : null,
        );

    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['Seleccionar', 'Aplicar escala', 'Resultado'][_paso]),
        bottom: _paso == 1 && _items.isNotEmpty
            ? PreferredSize(
                preferredSize: Size.fromHeight(6.h),
                child: LinearProgressIndicator(
                  value:
                      _items.where((i) => i.respondida).length / _items.length,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 4.h,
                ),
              )
            : null,
      ),
      body: [
        _buildPasoSeleccion(),
        _buildPasoItems(),
        _buildPasoResultado(),
      ][_paso],
    );
  }

  // â”€â”€ PASO 0: Seleccionar paciente y escala â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPasoSeleccion() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Paciente'),
          if (_pacienteId != null)
            _PacienteSeleccionado(
              nombre: _pacienteNombre ?? _pacienteId!,
              onCambiar: () => setState(() {
                _pacienteId = null;
                _pacienteNombre = null;
              }),
            )
          else
            _cargandoPacientes
                ? const CircularProgressIndicator()
                : _SelectorPacienteFiltro(
                    pacientes: _pacientes,
                    onSeleccionar: (p) => setState(() {
                      _pacienteId = p['id'].toString();
                      _pacienteNombre = p['nombre'].toString();
                    }),
                  ),
          SizedBox(height: 20.h),
          const _Label('Escala de evaluaciÃ³n'),
          ...EscalaEvaluacion.values.map((e) {
            final sel = _escala == e;
            final disponible = e == EscalaEvaluacion.personalizada ||
                (kItemsEscalas[e.value]?.isNotEmpty ?? false);
            return GestureDetector(
              onTap: !disponible
                  ? null
                  : () {
                      _escala = e;
                      _cargarItems();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: sel
                      ? AppTheme.accent.withValues(alpha: 0.08)
                      : !disponible
                          ? Theme.of(context).cardColor.withValues(alpha: 0.55)
                          : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: sel ? AppTheme.accent : AppTheme.divider,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.nombre,
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    sel ? AppTheme.accent : AppTheme.textDark)),
                        SizedBox(height: 2.h),
                        Text(e.descripcion,
                            style: GoogleFonts.inter(
                                fontSize: 12.sp, color: AppTheme.textGrey)),
                        if (e.puntuacionMax < 999)
                          Text('Puntaje mÃ¡x: ${e.puntuacionMax}',
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp, color: AppTheme.textGrey)),
                        if (!disponible)
                          Text(
                            'Proximamente',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warning,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (sel)
                    Icon(Icons.check_circle,
                        color: AppTheme.accent, size: 20.sp),
                ]),
              ),
            );
          }),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed:
                  _pacienteId == null ? null : () => setState(() => _paso = 1),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: const Text('Comenzar evaluaciÃ³n'),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ PASO 1: Responder Ã­tems â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPasoItems() {
    if (_items.isEmpty) {
      // Escala sin items predefinidos (flujo de puntaje manual).
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_escala.nombre, style: GoogleFonts.inter(fontSize: 16.sp)),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                _instruccionEscala,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textGrey,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => setState(() => _paso = 2),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }

    final item = _items[_itemActual];
    final totalR = _items.where((i) => i.respondida).length;

    return Column(
      children: [
        // NavegaciÃ³n de Ã­tems
        Container(
          color: Theme.of(context).cardColor,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Text('$totalR / ${_items.length} respondidas',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: AppTheme.textGrey)),
              const Spacer(),
              Text('Puntaje parcial: $_puntuacionTotal',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NÃºmero de pregunta
                Row(children: [
                  Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${item.numero}',
                          style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Pregunta ${item.numero} de ${_items.length}',
                      style: GoogleFonts.inter(
                          fontSize: 13.sp, color: AppTheme.textGrey)),
                ]),
                SizedBox(height: 16.h),

                // Pregunta
                Text(
                  _instruccionEscala,
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: AppTheme.textGrey),
                ),
                SizedBox(height: 8.h),
                Text(
                  item.pregunta,
                  style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4),
                ),
                SizedBox(height: 24.h),

                // Opciones
                ...List.generate(item.opciones.length, (i) {
                  final sel = item.valor == i;
                  return GestureDetector(
                    onTap: () => _responder(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color:
                            sel ? AppTheme.accent : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: sel ? AppTheme.accent : AppTheme.divider,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 24.w,
                          height: 24.h,
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppTheme.divider,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$i',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: sel
                                        ? Colors.white
                                        : AppTheme.textGrey)),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(item.opciones[i],
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: sel ? Colors.white : AppTheme.textDark,
                                  fontWeight:
                                      sel ? FontWeight.w500 : FontWeight.w400)),
                        ),
                        if (sel)
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 18.sp),
                      ]),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Barra inferior de navegaciÃ³n
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: const Border(top: BorderSide(color: AppTheme.divider)),
          ),
          child: Row(children: [
            if (_itemActual > 0)
              OutlinedButton.icon(
                onPressed: () => setState(() => _itemActual--),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
              ),
            const Spacer(),
            if (_todoRespondido)
              ElevatedButton.icon(
                onPressed: () => setState(() => _paso = 2),
                icon: const Icon(Icons.check),
                label: const Text('Ver resultado'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              )
            else if (_itemActual < _items.length - 1)
              ElevatedButton.icon(
                onPressed: item.respondida
                    ? () => setState(() {
                          final next = _items.indexWhere(
                              (i) => !i.respondida, _itemActual + 1);
                          _itemActual = next == -1 ? _itemActual + 1 : next;
                        })
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Siguiente'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
          ]),
        ),
      ],
    );
  }

  // â”€â”€ PASO 2: Resultado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPasoResultado() {
    final dummy = Evaluacion(
      id: '',
      pacienteId: _pacienteId ?? '',
      psicologoId: '',
      escala: _escala.value,
      puntuacionTotal: _puntuacionTotalFinal,
      respuestas: {},
      fechaCreacion: DateTime.now(),
    );
    final severidad = dummy.nivelSeveridad;
    final Color sevColor;
    switch (severidad) {
      case 'MÃ­nima':
      case 'Minima':
      case 'Leve':
        sevColor = AppTheme.accent;
        break;
      case 'Moderada':
      case 'Moderadamente severa':
        sevColor = AppTheme.warning;
        break;
      default:
        sevColor = severidad == 'â€”' ? AppTheme.textGrey : AppTheme.error;
    }
    final state = ref.watch(evaluacionesProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 16.h),
          // Resultado circular
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: sevColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: sevColor, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$_puntuacionTotalFinal',
                    style: GoogleFonts.inter(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: sevColor)),
                Text(
                    '/ ${_escala.puntuacionMax < 999 ? _escala.puntuacionMax : "â€”"}',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: AppTheme.textGrey)),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(_escala.nombre,
              style: GoogleFonts.inter(
                  fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 6.h),
          Text(_escala.descripcion,
              style:
                  GoogleFonts.inter(fontSize: 13.sp, color: AppTheme.textGrey),
              textAlign: TextAlign.center),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: sevColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(severidad,
                style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: sevColor)),
          ),
          SizedBox(height: 24.h),
          if (_pacienteNombre != null)
            Text('Paciente: $_pacienteNombre',
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: AppTheme.textGrey)),
          SizedBox(height: 20.h),

          if (_esPersonalizada) ...[
            TextField(
              controller: _puntajeManualCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Puntaje total manual',
                hintText: 'Ejemplo: 18',
                prefixIcon: Icon(Icons.calculate_outlined),
              ),
            ),
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ingrese un valor mayor a 0.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color:
                      _puntajeManualValido ? AppTheme.textGrey : AppTheme.error,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Resumen de respuestas
          if (_items.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Respuestas',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
            SizedBox(height: 8.h),
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              final opcion =
                  item.valor >= 0 ? item.opciones[item.valor] : 'Sin respuesta';
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22.w,
                      height: 22.h,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${item.numero}',
                            style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.pregunta,
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp, color: AppTheme.textGrey)),
                          Text(
                              '$opcion (${item.valor >= 0 ? item.valor : "â€”"})',
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 16.h),
          ],

          // Observaciones
          TextField(
            controller: _obsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observaciones clÃ­nicas (opcional)',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 24.h),

          // Botones
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _paso = 1),
                child: Text(_items.isEmpty ? 'Volver' : 'Revisar respuestas'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    state.isSaving || !_puntajeManualValido ? null : _guardar,
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                child: state.isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar'),
              ),
            ),
          ]),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

// â”€â”€ Widgets auxiliares â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGrey)),
      );
}

class _PacienteSeleccionado extends StatelessWidget {
  final String nombre;
  final VoidCallback onCambiar;
  const _PacienteSeleccionado({required this.nombre, required this.onCambiar});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.person_outline, color: AppTheme.accent, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(nombre,
                style: GoogleFonts.inter(
                    fontSize: 14.sp, fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: onCambiar,
            child: Text('Cambiar',
                style:
                    GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.accent)),
          ),
        ]),
      );
}

class _SelectorPacienteFiltro extends StatefulWidget {
  final List<Map<String, dynamic>> pacientes;
  final ValueChanged<Map<String, dynamic>> onSeleccionar;
  const _SelectorPacienteFiltro(
      {required this.pacientes, required this.onSeleccionar});

  @override
  State<_SelectorPacienteFiltro> createState() =>
      _SelectorPacienteFiltroState();
}

class _SelectorPacienteFiltroState extends State<_SelectorPacienteFiltro> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _filtrados = widget.pacientes;
    _ctrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _ctrl.text.toLowerCase().trim();
    setState(() {
      _filtrados = q.isEmpty
          ? widget.pacientes
          : widget.pacientes.where((p) {
              final n = p['nombre']?.toString().toLowerCase() ?? '';
              return n.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            labelText: 'Buscar paciente...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 180.h,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.divider),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: ListView.builder(
            itemCount: _filtrados.length,
            itemBuilder: (_, i) {
              final p = _filtrados[i];
              return ListTile(
                dense: true,
                title: Text(p['nombre']?.toString() ?? '',
                    style: GoogleFonts.inter(fontSize: 13.sp)),
                subtitle: Text(p['numero_documento']?.toString() ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 11.sp, color: AppTheme.textGrey)),
                onTap: () => widget.onSeleccionar(p),
              );
            },
          ),
        ),
      ],
    );
  }
}
