import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/paciente.dart';
import '../providers/paciente_provider.dart';
import '../../../../core/theme/app_theme.dart';

class PacienteForm extends ConsumerStatefulWidget {
  final Paciente? paciente; // null = crear, not null = editar

  const PacienteForm({super.key, this.paciente});

  @override
  ConsumerState<PacienteForm> createState() => _PacienteFormState();
}

class _PacienteFormState extends ConsumerState<PacienteForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController();
  late final _email = TextEditingController();
  late final _doc = TextEditingController();
  late final _tel = TextEditingController();
  late final _dir = TextEditingController();
  late final _hist = TextEditingController();
  DateTime? _fechaNac;

  bool get _esEdicion => widget.paciente != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final p = widget.paciente!;
      _nombre.text = p.nombre;
      _email.text = p.email;
      _doc.text = p.numeroDocumento;
      _tel.text = p.telefono ?? '';
      _dir.text = p.direccion ?? '';
      _hist.text = p.historialMedico ?? '';
      _fechaNac = p.fechaNacimiento;
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _email, _doc, _tel, _dir, _hist]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim().toLowerCase();
    final emailDuplicado = ref.read(pacientesProvider).pacientes.any((p) {
      if (_esEdicion && p.id == widget.paciente!.id) return false;
      return p.email.trim().toLowerCase() == email;
    });
    if (emailDuplicado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              duration: Duration(seconds: 5),
              content: Text('Ese email ya estÃ¡ registrado en pacientes')),
        );
      }
      return;
    }
    final notifier = ref.read(pacientesProvider.notifier);
    bool ok;
    if (_esEdicion) {
      ok = await notifier.actualizar(
        id: widget.paciente!.id,
        nombre: _nombre.text.trim(),
        email: email,
        numeroDocumento: _doc.text.trim(),
        telefono: _tel.text.trim().isEmpty ? null : _tel.text.trim(),
        direccion: _dir.text.trim().isEmpty ? null : _dir.text.trim(),
        historialMedico: _hist.text.trim().isEmpty ? null : _hist.text.trim(),
        fechaNacimiento: _fechaNac,
      );
    } else {
      ok = await notifier.crear(
        nombre: _nombre.text.trim(),
        email: email,
        numeroDocumento: _doc.text.trim(),
        telefono: _tel.text.trim().isEmpty ? null : _tel.text.trim(),
        direccion: _dir.text.trim().isEmpty ? null : _dir.text.trim(),
        historialMedico: _hist.text.trim().isEmpty ? null : _hist.text.trim(),
        fechaNacimiento: _fechaNac,
      );
    }
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pacientesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar paciente' : 'Nuevo paciente'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_nombre, 'Nombre completo', Icons.person_outline,
                  required: true),
              SizedBox(height: 14.h),
              _field(_email, 'Email', Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  required: true,
                  validator: (v) => (v != null && !v.contains('@'))
                      ? 'Email invÃ¡lido'
                      : null),
              SizedBox(height: 14.h),
              _field(_doc, 'NÃºmero de documento', Icons.badge_outlined,
                  required: true,
                  keyboard: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ]),
              SizedBox(height: 14.h),
              _field(_tel, 'TelÃ©fono', Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  inputFormatters: [
                    _ColombiaPhoneFormatter(),
                  ]),
              SizedBox(height: 14.h),
              _field(_dir, 'DirecciÃ³n', Icons.location_on_outlined),
              SizedBox(height: 14.h),

              // Fecha de nacimiento
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaNac ??
                        DateTime.now().subtract(const Duration(days: 365 * 25)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _fechaNac = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de nacimiento (opcional)',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    _fechaNac != null
                        ? DateFormat('dd/MM/yyyy').format(_fechaNac!)
                        : 'Seleccionar fecha',
                    style: GoogleFonts.inter(
                      color: _fechaNac != null
                          ? AppTheme.textDark
                          : AppTheme.textGrey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              _field(
                  _hist, 'Historial mÃ©dico', Icons.medical_services_outlined,
                  maxLines: 3),
              SizedBox(height: 24.h),

              // Error
              if (state.error != null)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(state.error!,
                      style: TextStyle(color: AppTheme.error, fontSize: 13.sp)),
                ),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_esEdicion ? 'Guardar cambios' : 'Crear paciente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool required = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
              : null),
    );
  }
}

class _ColombiaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digits.length > 10 ? digits.substring(0, 10) : digits;
    if (trimmed.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final withPrefix = '+57 $trimmed';
    return TextEditingValue(
      text: withPrefix,
      selection: TextSelection.collapsed(offset: withPrefix.length),
    );
  }
}
