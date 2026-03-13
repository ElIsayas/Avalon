import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/cita.dart';

class CalendarioWidget extends StatefulWidget {
  final DateTime fechaSeleccionada;
  final List<Cita> citas;
  final Function(DateTime) onFechaSeleccionada;

  const CalendarioWidget({
    super.key,
    required this.fechaSeleccionada,
    required this.citas,
    required this.onFechaSeleccionada,
  });

  @override
  State<CalendarioWidget> createState() => _CalendarioWidgetState();
}

class _CalendarioWidgetState extends State<CalendarioWidget> {
  late DateTime _mesActual;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _mesActual = DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month, 1);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del calendario
          _buildHeader(),
          
          // Días de la semana
          _buildDiasSemana(),
          
          // Calendario
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _mesActual = DateTime(
                    widget.fechaSeleccionada.year,
                    widget.fechaSeleccionada.month + index,
                    1,
                  );
                });
              },
              itemBuilder: (context, index) {
                final mes = DateTime(
                  widget.fechaSeleccionada.year,
                  widget.fechaSeleccionada.month + index,
                  1,
                );
                return _buildCalendarioMes(mes);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Color(0xFF3498DB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _mesAnterior,
            icon: Icon(Icons.chevron_left, color: Colors.white),
          ),
          Text(
            _formatMes(_mesActual),
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: _mesSiguiente,
            icon: Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDiasSemana() {
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: dias.map((dia) {
          return Container(
            width: 40.w,
            alignment: Alignment.center,
            child: Text(
              dia,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarioMes(DateTime mes) {
    final primerDia = DateTime(mes.year, mes.month, 1);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0);
    final diasEnMes = ultimoDia.day;
    final primerDiaSemana = primerDia.weekday % 7;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.2,
        ),
        itemCount: 42, // 6 semanas * 7 días
        itemBuilder: (context, index) {
          final diaIndex = index - primerDiaSemana + 1;
          
          if (diaIndex < 1 || diaIndex > diasEnMes) {
            return Container(); // Días vacíos
          }
          
          final dia = DateTime(mes.year, mes.month, diaIndex);
          final citasDelDia = _getCitasDelDia(dia);
          final esHoy = _esHoy(dia);
          final esSeleccionado = _esSeleccionado(dia);
          
          return _buildDiaCalendario(dia, citasDelDia, esHoy, esSeleccionado);
        },
      ),
    );
  }

  Widget _buildDiaCalendario(DateTime dia, List<Cita> citas, bool esHoy, bool esSeleccionado) {
    return InkWell(
      onTap: () => widget.onFechaSeleccionada(dia),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        margin: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          color: esSeleccionado ? Color(0xFF3498DB).withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(8.r),
          border: esHoy
              ? Border.all(color: Color(0xFF3498DB), width: 2)
              : esSeleccionado
                  ? Border.all(color: Color(0xFF3498DB))
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dia.day.toString(),
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: esHoy ? FontWeight.bold : FontWeight.w600,
                color: esHoy ? Color(0xFF3498DB) : Colors.black87,
              ),
            ),
            
            // Indicadores de citas
            if (citas.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (citas.length <= 3) ...[
                    ...citas.map((cita) => Container(
                      width: 4.w,
                      height: 4.h,
                      margin: EdgeInsets.symmetric(horizontal: 1.w),
                      decoration: BoxDecoration(
                        color: cita.estado.color,
                        shape: BoxShape.circle,
                      ),
                    )),
                  ] else ...[
                    // Más de 3 citas, mostrar contador
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '+${citas.length}',
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Cita> _getCitasDelDia(DateTime dia) {
    return widget.citas.where((cita) {
      return cita.fechaHora.year == dia.year &&
             cita.fechaHora.month == dia.month &&
             cita.fechaHora.day == dia.day;
    }).toList();
  }

  bool _esHoy(DateTime dia) {
    final ahora = DateTime.now();
    return dia.year == ahora.year &&
           dia.month == ahora.month &&
           dia.day == ahora.day;
  }

  bool _esSeleccionado(DateTime dia) {
    return dia.year == widget.fechaSeleccionada.year &&
           dia.month == widget.fechaSeleccionada.month &&
           dia.day == widget.fechaSeleccionada.day;
  }

  void _mesAnterior() {
    if (_mesActual.month == 1) {
      _mesActual = DateTime(_mesActual.year - 1, 12, 1);
    } else {
      _mesActual = DateTime(_mesActual.year, _mesActual.month - 1, 1);
    }
    setState(() {});
  }

  void _mesSiguiente() {
    if (_mesActual.month == 12) {
      _mesActual = DateTime(_mesActual.year + 1, 1, 1);
    } else {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + 1, 1);
    }
    setState(() {});
  }

  String _formatMes(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }
}
