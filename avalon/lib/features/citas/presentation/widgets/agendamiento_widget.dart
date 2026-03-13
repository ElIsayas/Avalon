import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/cita.dart';
import '../providers/cita_provider.dart';

class AgendamientoWidget extends ConsumerStatefulWidget {
  final String psicologoId;
  final Function(Cita) onCitaAgendada;

  const AgendamientoWidget({
    super.key,
    required this.psicologoId,
    required this.onCitaAgendada,
  });

  @override
  ConsumerState<AgendamientoWidget> createState() => _AgendamientoWidgetState();
}

class _AgendamientoWidgetState extends ConsumerState<AgendamientoWidget> {
  DateTime? _fechaSeleccionada;
  DateTime? _horaSeleccionada;
  Duration _duracionSeleccionada = const Duration(minutes: 60);
  TipoCita _tipoSeleccionado = TipoCita.inicial;
  bool _esOnline = false;
  String _pacienteId = '';
  String _motivoConsulta = '';
  double? _costo;

  final _pacienteController = TextEditingController();
  final _motivoController = TextEditingController();
  final _costoController = TextEditingController();

  @override
  void dispose() {
    _pacienteController.dispose();
    _motivoController.dispose();
    _costoController.dispose();
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
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
                Icon(Icons.schedule, color: Color(0xFF3498DB), size: 28.sp),
                SizedBox(width: 12.w),
                Text(
                  'Agendar Nueva Cita',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Formulario de agendamiento
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Paciente
                    _buildSectionTitle('Paciente'),
                    _buildPacienteSelector(),
                    SizedBox(height: 20.h),

                    // Fecha y Hora
                    _buildSectionTitle('Fecha y Hora'),
                    _buildFechaHoraSelector(),
                    SizedBox(height: 20.h),

                    // Configuración de la cita
                    _buildSectionTitle('Configuración'),
                    _buildConfiguracionCita(),
                    SizedBox(height: 20.h),

                    // Detalles adicionales
                    _buildSectionTitle('Detalles Adicionales'),
                    _buildDetallesAdicionales(),
                    SizedBox(height: 24.h),

                    // Botón de agendar
                    _buildAgendarButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildPacienteSelector() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID del Paciente',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _pacienteController,
            decoration: InputDecoration(
              hintText: 'Ingrese el ID del paciente',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (value) {
              _pacienteId = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFechaHoraSelector() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Selector de fecha
          InkWell(
            onTap: _selectFecha,
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Color(0xFF3498DB)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _fechaSeleccionada != null
                          ? _formatFecha(_fechaSeleccionada!)
                          : 'Seleccionar fecha',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: _fechaSeleccionada != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Selector de hora
          InkWell(
            onTap: _selectHora,
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Color(0xFF3498DB)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _horaSeleccionada != null
                          ? _formatHora(_horaSeleccionada!)
                          : 'Seleccionar hora',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: _horaSeleccionada != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracionCita() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Duración
          DropdownButtonFormField<Duration>(
            value: _duracionSeleccionada,
            decoration: InputDecoration(
              labelText: 'Duración',
              prefixIcon: Icon(Icons.timer),
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: Duration(minutes: 30), child: Text('30 minutos')),
              DropdownMenuItem(value: Duration(minutes: 45), child: Text('45 minutos')),
              DropdownMenuItem(value: Duration(minutes: 60), child: Text('1 hora')),
              DropdownMenuItem(value: Duration(minutes: 90), child: Text('1.5 horas')),
              DropdownMenuItem(value: Duration(minutes: 120), child: Text('2 horas')),
            ],
            onChanged: (value) {
              setState(() {
                _duracionSeleccionada = value!;
              });
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Tipo de cita
          DropdownButtonFormField<TipoCita>(
            value: _tipoSeleccionado,
            decoration: InputDecoration(
              labelText: 'Tipo de Cita',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: TipoCita.values.map((tipo) {
              return DropdownMenuItem(
                value: tipo,
                child: Text(tipo.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _tipoSeleccionado = value!;
              });
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Modalidad
          SwitchListTile(
            title: Text(
              'Consulta Online',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('Habilitar videoconferencia'),
            value: _esOnline,
            activeColor: Color(0xFF3498DB),
            onChanged: (value) {
              setState(() {
                _esOnline = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesAdicionales() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Motivo de consulta
          TextField(
            controller: _motivoController,
            decoration: InputDecoration(
              labelText: 'Motivo de Consulta (opcional)',
              hintText: 'Describa el motivo de la consulta',
              prefixIcon: Icon(Icons.help_outline),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              _motivoConsulta = value;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Costo
          TextField(
            controller: _costoController,
            decoration: InputDecoration(
              labelText: 'Costo (opcional)',
              hintText: '0.00',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              _costo = value.isNotEmpty ? double.tryParse(value) : null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgendarButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _validarYAgendar,
        icon: const Icon(Icons.event_available),
        label: Text(
          'Agendar Cita',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF3498DB),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Future<void> _selectFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _selectHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _horaSeleccionada = DateTime(
          _fechaSeleccionada?.year ?? DateTime.now().year,
          _fechaSeleccionada?.month ?? DateTime.now().month,
          _fechaSeleccionada?.day ?? DateTime.now().day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _validarYAgendar() {
    // Validaciones
    if (_pacienteId.trim().isEmpty) {
      _mostrarError('Por favor ingrese el ID del paciente');
      return;
    }

    if (_fechaSeleccionada == null) {
      _mostrarError('Por favor seleccione una fecha');
      return;
    }

    if (_horaSeleccionada == null) {
      _mostrarError('Por favor seleccione una hora');
      return;
    }

    // Combinar fecha y hora
    final fechaHora = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    // Verificar que la fecha no sea en el pasado
    if (fechaHora.isBefore(DateTime.now())) {
      _mostrarError('No se pueden agendar citas en el pasado');
      return;
    }

    // Crear la cita
    final nuevaCita = Cita(
      id: '', // Se generará en el backend
      pacienteId: _pacienteId.trim(),
      psicologoId: widget.psicologoId,
      fechaHora: fechaHora,
      duracion: _duracionSeleccionada,
      tipo: _tipoSeleccionado,
      estado: EstadoCita.agendada,
      motivoConsulta: _motivoConsulta.trim().isEmpty ? null : _motivoConsulta.trim(),
      esOnline: _esOnline,
      costo: _costo,
      fechaCreacion: DateTime.now(),
    );

    widget.onCitaAgendada(nuevaCita);
    
    // Limpiar formulario
    _limpiarFormulario();
    
    _mostrarExito('Cita agendada exitosamente');
  }

  void _limpiarFormulario() {
    setState(() {
      _fechaSeleccionada = null;
      _horaSeleccionada = null;
      _duracionSeleccionada = const Duration(minutes: 60);
      _tipoSeleccionado = TipoCita.inicial;
      _esOnline = false;
      _pacienteId = '';
      _motivoConsulta = '';
      _costo = null;
    });
    
    _pacienteController.clear();
    _motivoController.clear();
    _costoController.clear();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  String _formatHora(DateTime hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }
}
