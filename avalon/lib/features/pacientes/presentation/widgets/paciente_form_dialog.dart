import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/paciente_model.dart';

typedef PacienteSaveCallback = void Function(
  String nombre,
  String email,
  String numeroDocumento,
  String? telefono,
  String? direccion,
  DateTime? fechaNacimiento,
  String? historialMedico,
);

class PacienteFormDialog extends StatefulWidget {
  final Paciente? paciente;
  final PacienteSaveCallback onSave;

  const PacienteFormDialog({
    super.key,
    this.paciente,
    required this.onSave,
  });

  @override
  State<PacienteFormDialog> createState() => _PacienteFormDialogState();
}

class _PacienteFormDialogState extends State<PacienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _historialMedicoController = TextEditingController();
  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();
    if (widget.paciente != null) {
      _nombreController.text = widget.paciente!.nombre;
      _emailController.text = widget.paciente!.email;
      _numeroDocumentoController.text = widget.paciente!.numeroDocumento;
      _telefonoController.text = widget.paciente!.telefono ?? '';
      _direccionController.text = widget.paciente!.direccion ?? '';
      _historialMedicoController.text = widget.paciente!.historialMedico ?? '';
      _fechaNacimiento = widget.paciente!.fechaNacimiento;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _numeroDocumentoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _historialMedicoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.paciente != null;

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
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.person_add,
                      color: Color(0xFF3498DB),
                      size: 28.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      isEditing ? 'Editar Paciente' : 'Nuevo Paciente',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    hintText: 'Ingrese el nombre del paciente',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el nombre del paciente';
                    }
                    if (value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'paciente@ejemplo.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el email';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Por favor ingrese un email válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _numeroDocumentoController,
                  decoration: InputDecoration(
                    labelText: 'Número de documento',
                    hintText: 'Ingrese el número de documento',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el número de documento';
                    }
                    if (value.trim().length < 3) {
                      return 'El documento debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _telefonoController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    hintText: '+1234567890',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Por favor ingrese un número de teléfono válido';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _direccionController,
                  decoration: InputDecoration(
                    labelText: 'Dirección (opcional)',
                    hintText: 'Ingrese la dirección del paciente',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),
                InkWell(
                  onTap: _selectFechaNacimiento,
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
                            _fechaNacimiento != null
                                ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                                : 'Seleccionar fecha de nacimiento (opcional)',
                            style: GoogleFonts.inter(
                              color: _fechaNacimiento != null
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
                TextFormField(
                  controller: _historialMedicoController,
                  decoration: InputDecoration(
                    labelText: 'Historial Médico (opcional)',
                    hintText: 'Ingrese información médica relevante',
                    prefixIcon: Icon(Icons.medical_services),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 24.h),
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

  Future<void> _selectFechaNacimiento() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nombreController.text.trim(),
        _emailController.text.trim(),
        _numeroDocumentoController.text.trim(),
        _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        _fechaNacimiento,
        _historialMedicoController.text.trim().isEmpty ? null : _historialMedicoController.text.trim(),
      );
      Navigator.pop(context);
    }
  }
}
