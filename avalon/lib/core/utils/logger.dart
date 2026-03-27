import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

const bool kShowInAppLogs = false;

enum InAppLogType { error, success, warning, info }

class InAppLogEntry {
  final String id;
  final InAppLogType type;
  final String title;
  final String message;
  final String? location;

  const InAppLogEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.location,
  });
}

class InAppLogController {
  InAppLogController._();

  static final InAppLogController instance = InAppLogController._();

  final ValueNotifier<List<InAppLogEntry>> entries =
      ValueNotifier<List<InAppLogEntry>>(const []);

  void push(InAppLogEntry entry) {
    final next = <InAppLogEntry>[entry, ...entries.value].take(4).toList();
    entries.value = next;
  }
}

class AppLogger {
  static const String _tag = 'AVALON';

  static bool get _showInAppLogs =>
      kShowInAppLogs &&
      !kIsWeb &&
      !const bool.fromEnvironment('FLUTTER_TEST') &&
      defaultTargetPlatform == TargetPlatform.android;

  static void debug(String message, {String? tag}) {
    developer.log(
      'DEBUG: $message',
      name: tag ?? _tag,
      level: 500,
    );
  }

  static void info(String message, {String? tag}) {
    developer.log(
      'INFO: $message',
      name: tag ?? _tag,
      level: 800,
    );
  }

  static void success(
    String message, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    developer.log(
      'SUCCESS: $message',
      name: tag ?? _tag,
      level: 800,
    );
    _emitInApp(
      type: InAppLogType.success,
      title: 'Proceso completado',
      message: message,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }

  static void warning(
    String message, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    developer.log(
      'WARNING: $message',
      name: tag ?? _tag,
      level: 900,
    );
    _emitInApp(
      type: InAppLogType.warning,
      title: 'Advertencia',
      message: message,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    final trace = stackTrace ?? StackTrace.current;
    developer.log(
      'ERROR: $message',
      name: tag ?? _tag,
      error: error,
      stackTrace: trace,
      level: 1000,
    );
    _emitInApp(
      type: InAppLogType.error,
      title: error?.runtimeType.toString() ?? 'Error',
      message: message,
      stackTrace: trace,
    );
  }

  static void auth(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      'AUTH: $message',
      name: '$_tag-AUTH',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
    _maybeEmitSuccess(message, stackTrace: stackTrace);
  }

  static void database(String message,
      {Object? error, StackTrace? stackTrace}) {
    developer.log(
      'DATABASE: $message',
      name: '$_tag-DB',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
    _maybeEmitSuccess(message, stackTrace: stackTrace);
  }

  static void api(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      'API: $message',
      name: '$_tag-API',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
    _maybeEmitSuccess(message, stackTrace: stackTrace);
  }

  static void ui(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      'UI: $message',
      name: '$_tag-UI',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
    _maybeEmitSuccess(message, stackTrace: stackTrace);
  }

  static void _maybeEmitSuccess(
    String message, {
    StackTrace? stackTrace,
  }) {
    final normalized = message.toLowerCase();
    const successKeywords = [
      'exitos',
      'completad',
      'guardad',
      'actualizad',
      'cread',
      'cargad',
      'inicializado correctamente',
    ];
    final isSuccess = successKeywords.any(normalized.contains);
    if (!isSuccess) return;
    _emitInApp(
      type: InAppLogType.success,
      title: 'Proceso completado',
      message: message,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }

  static void _emitInApp({
    required InAppLogType type,
    required String title,
    required String message,
    required StackTrace stackTrace,
  }) {
    if (!_showInAppLogs) return;
    InAppLogController.instance.push(
      InAppLogEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        location: _extractLocation(stackTrace),
      ),
    );
  }

  static String? _extractLocation(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    final regex = RegExp(
      r'(package:[^)]+\.dart:\d+:\d+|file:[^)]+\.dart:\d+:\d+|[A-Za-z]:\\[^:]+\.dart:\d+:\d+)',
    );
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.contains('logger.dart')) continue;
      final match = regex.firstMatch(line);
      if (match != null) return match.group(0);
    }
    return null;
  }
}
