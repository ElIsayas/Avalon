import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/app_prefs_provider.dart';
import '../../../../core/notifications/notifications_service.dart';
import '../../../../features/usuarios/presentation/screens/usuarios_screen.dart';
import '../../../../features/recordatorios/presentation/screens/recordatorios_screen.dart';
import '../../../../features/pagos/presentation/screens/pagos_screen.dart';

class ConfiguracionScreen extends ConsumerWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final prefs = ref.watch(appPrefsProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.configuracion),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveBody(
        maxWidth: 720,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _SectionLabel(context.t.miPerfil),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: Text(user?.iniciales ?? '??',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 18.sp)),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.displayName ?? '',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp)),
                          SizedBox(height: 2.h),
                          Text(user?.email ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 13.sp, color: AppTheme.textGrey)),
                          SizedBox(height: 4.h),
                          Row(children: [
                            _Badge(
                                '${user?.rolEmoji ?? ''} ${user?.rolLabel ?? ''}',
                                AppTheme.primary),
                            if (user?.plan != null) ...[
                              SizedBox(width: 6.w),
                              _Badge(user!.planLabel, AppTheme.secondary),
                            ],
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (user?.especialidad != null || user?.diasRestantes != null) ...[
              SizedBox(height: 8.h),
              Card(
                child: Column(children: [
                  if (user?.especialidad != null)
                    _InfoTile(
                        Iconsax.medal, 'Especialidad', user!.especialidad!),
                  if (user?.diasRestantes != null)
                    _InfoTile(Iconsax.calendar_tick, 'Plan vence en',
                        '${user!.diasRestantes} dÃƒÂ­as',
                        valueColor: user.diasRestantes! <= 7
                            ? AppTheme.error
                            : AppTheme.accent),
                ]),
              ),
            ],
            SizedBox(height: 20.h),
            _SectionLabel(context.t.apariencia),
            Card(
              child: Column(children: [
                _ToggleTile(
                  icon: Iconsax.moon,
                  title: context.t.modoOscuro,
                  subtitle: isDark ? context.t.activado : context.t.desactivado,
                  value: isDark,
                  onChanged: (v) => ref
                      .read(themeProvider.notifier)
                      .setMode(v ? ThemeMode.dark : ThemeMode.light),
                ),
                const Divider(height: 1, color: AppTheme.divider),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Iconsax.text,
                              size: 20.sp, color: AppTheme.primary),
                          SizedBox(width: 12.w),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(context.t.tamanoTexto,
                                    style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500)),
                                Text(_textScaleLabel(prefs.textScale),
                                    style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: AppTheme.textGrey)),
                              ])),
                        ]),
                        Slider(
                          value: prefs.textScale,
                          min: 0.8,
                          max: 1.3,
                          divisions: 5,
                          activeColor: AppTheme.primary,
                          onChanged: (v) => ref
                              .read(appPrefsProvider.notifier)
                              .setTextScale(v),
                        ),
                      ]),
                ),
              ]),
            ),
            SizedBox(height: 20.h),
            _SectionLabel(context.t.idioma),
            Card(
              child: Column(
                children: soportedLocales.map((locale) {
                  final selected =
                      prefs.locale.languageCode == locale.languageCode;
                  return _LocaleTile(
                    label: localeLabels[locale.languageCode] ??
                        locale.languageCode,
                    selected: selected,
                    onTap: () =>
                        ref.read(appPrefsProvider.notifier).setLocale(locale),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20.h),
            _SectionLabel(context.t.notificaciones),
            Card(
              child: Column(children: [
                _ToggleTile(
                  icon: Iconsax.calendar_tick,
                  title: context.t.recordatoriosCitas,
                  subtitle: context.t.antesDeCardaCita,
                  value: prefs.notifCitas,
                  onChanged: (v) => _onToggleNotif(
                    context,
                    ref,
                    value: v,
                    persist: (nv) =>
                        ref.read(appPrefsProvider.notifier).setNotifCitas(nv),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.divider),
                _ToggleTile(
                  icon: Iconsax.notification,
                  title: context.t.recordatorios,
                  subtitle: context.t.alertasTareas,
                  value: prefs.notifRecordatorios,
                  onChanged: (v) => _onToggleNotif(
                    context,
                    ref,
                    value: v,
                    persist: (nv) => ref
                        .read(appPrefsProvider.notifier)
                        .setNotifRecordatorios(nv),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.divider),
                _ToggleTile(
                  icon: Iconsax.info_circle,
                  title: context.t.notifSistema,
                  subtitle: context.t.actualizacionesYAvisos,
                  value: prefs.notifSistema,
                  onChanged: (v) => _onToggleNotif(
                    context,
                    ref,
                    value: v,
                    persist: (nv) =>
                        ref.read(appPrefsProvider.notifier).setNotifSistema(nv),
                  ),
                ),
              ]),
            ),
            SizedBox(height: 20.h),
            _SectionLabel(context.t.herramientas),
            Card(
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.credit_card_outlined,
                    title: 'Pagos y suscripciones',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PagosScreen()),
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.divider),
                  _ActionTile(
                    icon: Iconsax.notification,
                    title: context.t.recordatorios,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RecordatoriosScreen()),
                    ),
                  ),
                ],
              ),
            ),
            if (user?.puedeGestionarUsuarios == true) ...[
              SizedBox(height: 20.h),
              _SectionLabel(context.t.miEquipo),
              Card(
                child: _ActionTile(
                  icon: Iconsax.people,
                  title: context.t.gestionarUsuarios,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UsuariosScreen())),
                ),
              ),
            ],
            SizedBox(height: 20.h),
            _SectionLabel(context.t.acercaDe),
            Card(
              child: Column(children: [
                _ActionTile(
                  icon: Iconsax.info_circle,
                  title: context.t.versionApp,
                  trailing: const _VersionText(),
                ),
                const Divider(height: 1, color: AppTheme.divider),
                _ActionTile(
                  icon: Iconsax.shield_tick,
                  title: context.t.politicaPrivacidad,
                  onTap: () => _openExternal(
                      context, 'https://avalonpsicologia.com/privacy'),
                ),
                const Divider(height: 1, color: AppTheme.divider),
                _ActionTile(
                  icon: Iconsax.document_text,
                  title: context.t.terminosUso,
                  onTap: () => _openExternal(
                      context, 'https://avalonpsicologia.com/terms'),
                ),
              ]),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmarLogout(context, ref),
                icon: Icon(Iconsax.logout, color: AppTheme.error, size: 18.sp),
                label: Text(context.t.cerrarSesion,
                    style: GoogleFonts.inter(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp)),
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Center(
                child: Text(context.t.taglineApp,
                    style: GoogleFonts.inter(
                        fontSize: 11.sp, color: AppTheme.textGrey))),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  String _textScaleLabel(double v) {
    if (v <= 0.8) return 'Muy pequeÃƒÂ±o';
    if (v <= 0.9) return 'PequeÃƒÂ±o';
    if (v <= 1.0) return 'Normal';
    if (v <= 1.15) return 'Grande';
    return 'Muy grande';
  }

  void _confirmarLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t.cerrarSesion),
        content: Text(context.t.cerrarSesionConf),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(context.t.cerrarSesion),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternal(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 5),
        content: Text('No se pudo abrir el enlace'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onToggleNotif(
    BuildContext context,
    WidgetRef ref, {
    required bool value,
    required Future<void> Function(bool) persist,
  }) async {
    if (!value) {
      await persist(false);
      return;
    }
    final ok = await ref
        .read(notificationsServiceProvider)
        .requestPermissionIfNeeded();
    if (!ok) {
      await persist(false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 5),
          content: Text('Permiso de notificaciones denegado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await persist(true);
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Widgets auxiliares Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: 4.w, bottom: 8.h, top: 4.h),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGrey,
                letterSpacing: 0.5)),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r)),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 11.sp, color: color, fontWeight: FontWeight.w500)),
      );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 20.sp),
        title: Text(title,
            style: GoogleFonts.inter(
                fontSize: 14.sp, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style:
                GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.textGrey)),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primary,
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color? valueColor;
  const _InfoTile(this.icon, this.title, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 20.sp),
        title: Text(title,
            style: GoogleFonts.inter(
                fontSize: 14.sp, fontWeight: FontWeight.w500)),
        trailing: Text(value,
            style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: valueColor ?? AppTheme.textGrey,
                fontWeight: FontWeight.w500)),
      );
}

class _LocaleTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LocaleTile(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        title: Text(label,
            style: GoogleFonts.inter(
                fontSize: 14.sp, fontWeight: FontWeight.w500)),
        trailing: selected
            ? Icon(Icons.check_circle, color: AppTheme.primary, size: 20.sp)
            : Icon(Icons.circle_outlined,
                color: AppTheme.textGrey, size: 20.sp),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ActionTile(
      {required this.icon, required this.title, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 20.sp),
        title: Text(title,
            style: GoogleFonts.inter(
                fontSize: 14.sp, fontWeight: FontWeight.w500)),
        trailing: trailing ??
            Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 18.sp),
        onTap: onTap,
      );
}

class _VersionText extends StatelessWidget {
  const _VersionText();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (_, snapshot) {
        final version = snapshot.data?.version ?? '...';
        return Text(
          version,
          style: GoogleFonts.inter(fontSize: 13.sp, color: AppTheme.textGrey),
        );
      },
    );
  }
}
