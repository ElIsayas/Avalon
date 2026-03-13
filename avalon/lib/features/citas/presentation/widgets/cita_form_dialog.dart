import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/cita.dart';

class CitaFormDialog extends StatefulWidget {
  final Cita? cita;
  final Function(
    String pacienteId,
    String psicologoId,
    DateTime fechaHora,
    Duration duracion,
    TipoCita tipo,
    String? notas,
    String? motivoConsulta,
    bool esOnline,
    double? costo,
  ) onSave;

  const CitaFormDialog({
    super.key,
    this.cita,
    required this.onSave,
  });

  @override
  State<CitaFormDialog> createState() => _CitaFormDialogState();
}

class _CitaFormDialogState extends State<CitaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pacienteIdController = TextEditingController();
  final _psicologoIdController = TextEditingController();
  final _notasController = TextEditingController();
  final _motivoConsultaController = TextEditingController();
  final _costoController = TextEditingController();

  DateTime? _fechaHora;
  Duration _duracion = const Duration(minutes: 60);
  TipoCita _tipoSeleccionado = TipoCita.inicial;
  bool _esOnline = false;

  @override
  void initState() {
    super.initState();
    if (widget.cita != null) {
      _pacienteIdController.text = widget.cita!.pacienteId;
      _psicologoIdController.text = widget.cita!.psicologoId;
      _notasController.text = widget.cita!.notas ?? '';
      _motivoConsultaController.text = widget.cita!.motivoConsulta ?? '';
      _costoController.text = widget.cita!.costo?.toString() ?? '';
      _fechaHora = widget.cita!.fechaHora;
      _duracion = widget.cita!.duracion;
      _tipoSeleccionado = widget.cita!.tipo;
      _esOnline = widget.cita!.esOnline;
    }
  }

  @override
  void dispose() {
    _pacienteIdController.dispose();
    _psicologoIdController.dispose();
    _notasController.dispose();
    _motivoConsultaController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cita != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 600.h),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.event_available,
                      color: Color(0xFF3498DB),
                      size: 28.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      isEditing ? 'Editar Cita' : 'Nueva Cita',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Paciente ID
                TextFormField(
                  controller: _pacienteIdController,
                  decoration: InputDecoration(
                    labelText: 'ID del Paciente',
                    hintText: 'Ingrese el ID del paciente',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el ID del paciente';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Psicólogo ID
                TextFormField(
                  controller: _psicologoIdController,
                  decoration: InputDecoration(
                    labelText: 'ID del Psicólogo',
                    hintText: 'Ingrese el ID del psicólogo',
                    prefixIcon: Icon(Icons.psychology),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el ID del psicólogo';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Fecha y Hora
                InkWell(
                  onTap: _selectFechaHora,
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _fechaHora != null
                                ? _formatDateTime(_fechaHora!)
                                : 'Seleccionar fecha y hora',
                            style: GoogleFonts.inter(
                              color: _fechaHora != null
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

                // Duración
                DropdownButtonFormField<Duration>(
                  initialValue: _duracion,
                  decoration: InputDecoration(
                    labelText: 'Duración',
                    prefixIcon: Icon(Icons.timer),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
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
                      _duracion = value!;
                    });
                  },
                ),
                SizedBox(height: 16.h),

                // Tipo de Cita
                DropdownButtonFormField<TipoCita>(
                  initialValue: _tipoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Cita',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
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
                  activeThumbColor: Color(0xFF3498DB),
                  onChanged: (value) {
                    setState(() {
                      _esOnline = value;
                    });
                  },
                ),
                SizedBox(height: 16.h),

                // Costo
                TextFormField(
                  controller: _costoController,
                  decoration: InputDecoration(
                    labelText: 'Costo (opcional)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final costo = double.tryParse(value);
                      if (costo == null || costo < 0) {
                        return 'Ingrese un costo válido';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Motivo de Consulta
                TextFormField(
                  controller: _motivoConsultaController,
                  decoration: InputDecoration(
                    labelText: 'Motivo de Consulta (opcional)',
                    hintText: 'Describa el motivo de la consulta',
                    prefixIcon: Icon(Icons.help_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),

                // Notas
                TextFormField(
                  controller: _notasController,
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Notas adicionales sobre la cita',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 24.h),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3498DB),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Actualizar' : 'Guardar',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectFechaHora() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaHora ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaHora ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _fechaHora = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_fechaHora == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor seleccione fecha y hora'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final double? costo = _costoController.text.trim().isNotEmpty
          ? double.tryParse(_costoController.text)
          : null;

      widget.onSave(
        _pacienteIdController.text.trim(),
        _psicologoIdController.text.trim(),
        _fechaHora!,
        _duracion,
        _tipoSeleccionado,
        _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        _motivoConsultaController.text.trim().isEmpty ? null : _motivoConsultaController.text.trim(),
        _esOnline,
        costo,
      );
      Navigator.pop(context);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
