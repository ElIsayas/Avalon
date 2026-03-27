import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/logger.dart';

class AvalonNotificationsService {
  AvalonNotificationsService._();

  static final AvalonNotificationsService instance =
      AvalonNotificationsService._();

  static const String citasChannelId = 'citas';
  static const String recordatoriosChannelId = 'recordatorios';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    await _configureTimezone();
    await _createAndroidChannels();

    _isInitialized = true;
  }

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (e) {
      AppLogger.warning(
        'No se pudo detectar zona horaria local, se usara UTC: $e',
      );
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const citasChannel = AndroidNotificationChannel(
      citasChannelId,
      'Citas',
      description: 'Recordatorios de citas programadas',
      importance: Importance.high,
    );
    const recordatoriosChannel = AndroidNotificationChannel(
      recordatoriosChannelId,
      'Recordatorios',
      description: 'Alertas de recordatorios y tareas',
      importance: Importance.defaultImportance,
    );

    await android.createNotificationChannel(citasChannel);
    await android.createNotificationChannel(recordatoriosChannel);
  }

  Future<bool> requestPermissionIfNeeded() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> scheduleCitaReminders({
    required String citaId,
    required DateTime fechaHora,
    required String pacienteLabel,
    required bool recordatorio24h,
    required bool recordatorio1h,
  }) async {
    await init();

    final now = DateTime.now();
    final reminders = <({String key, DateTime at, String subtitle})>[];

    if (recordatorio24h) {
      reminders.add((
        key: '24h',
        at: fechaHora.subtract(const Duration(hours: 24)),
        subtitle: 'en 24 horas',
      ));
    }
    if (recordatorio1h) {
      reminders.add((
        key: '1h',
        at: fechaHora.subtract(const Duration(hours: 1)),
        subtitle: 'en 1 hora',
      ));
    }

    for (final reminder in reminders) {
      if (!reminder.at.isAfter(now.add(const Duration(seconds: 5)))) {
        continue;
      }
      final id = _notificationId(citaId, reminder.key);
      final scheduled = tz.TZDateTime.from(reminder.at, tz.local);

      await _plugin.zonedSchedule(
        id,
        'Recordatorio de cita',
        'Tienes una cita con $pacienteLabel ${reminder.subtitle}.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            citasChannelId,
            'Citas',
            channelDescription: 'Recordatorios de citas programadas',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  int _notificationId(String citaId, String key) =>
      '${citaId}_$key'.hashCode & 0x7fffffff;
}

final notificationsServiceProvider = Provider<AvalonNotificationsService>(
  (ref) => AvalonNotificationsService.instance,
);
