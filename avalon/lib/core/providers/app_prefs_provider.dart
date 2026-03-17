import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  final Locale locale;
  final bool notifCitas;
  final bool notifRecordatorios;
  final bool notifSistema;
  final double textScale;

  const AppPrefs({
    this.locale           = const Locale('es'),
    this.notifCitas       = true,
    this.notifRecordatorios = true,
    this.notifSistema     = true,
    this.textScale        = 1.0,
  });

  AppPrefs copyWith({
    Locale? locale,
    bool? notifCitas,
    bool? notifRecordatorios,
    bool? notifSistema,
    double? textScale,
  }) =>
      AppPrefs(
        locale:              locale              ?? this.locale,
        notifCitas:          notifCitas          ?? this.notifCitas,
        notifRecordatorios:  notifRecordatorios  ?? this.notifRecordatorios,
        notifSistema:        notifSistema        ?? this.notifSistema,
        textScale:           textScale           ?? this.textScale,
      );
}

class AppPrefsNotifier extends StateNotifier<AppPrefs> {
  static const _kLocale    = 'avalon_locale';
  static const _kNotifC    = 'avalon_notif_citas';
  static const _kNotifR    = 'avalon_notif_rec';
  static const _kNotifS    = 'avalon_notif_sis';
  static const _kTextScale = 'avalon_text_scale';

  AppPrefsNotifier() : super(const AppPrefs()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppPrefs(
      locale:             Locale(p.getString(_kLocale) ?? 'es'),
      notifCitas:         p.getBool(_kNotifC)    ?? true,
      notifRecordatorios: p.getBool(_kNotifR)    ?? true,
      notifSistema:       p.getBool(_kNotifS)    ?? true,
      textScale:          p.getDouble(_kTextScale) ?? 1.0,
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, locale.languageCode);
  }

  Future<void> setNotifCitas(bool v) async {
    state = state.copyWith(notifCitas: v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifC, v);
  }

  Future<void> setNotifRecordatorios(bool v) async {
    state = state.copyWith(notifRecordatorios: v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifR, v);
  }

  Future<void> setNotifSistema(bool v) async {
    state = state.copyWith(notifSistema: v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotifS, v);
  }

  Future<void> setTextScale(double v) async {
    state = state.copyWith(textScale: v);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kTextScale, v);
  }
}

final appPrefsProvider = StateNotifierProvider<AppPrefsNotifier, AppPrefs>(
  (ref) => AppPrefsNotifier(),
);

// Idiomas soportados
const soportedLocales = [
  Locale('es'),
  Locale('en'),
];

const localeLabels = {
  'es': '🇨🇴  Español',
  'en': '🇺🇸  English',
};
