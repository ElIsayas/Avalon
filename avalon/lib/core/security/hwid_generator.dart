import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Generador de Hardware ID (HWID) para identificación única de dispositivos
class HWIDGenerator {
  /// Genera un HWID único basado en características del hardware y sistema
  static Future<String> generateHWID() async {
    try {
      final base = await _getHardwareBase();
      final hwid = sha256.convert(utf8.encode(base)).toString();
      return hwid;
    } catch (e) {
      // Fallback a un ID basado en timestamp si no se puede obtener HWID
      final fallback = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      return sha256.convert(utf8.encode(fallback)).toString();
    }
  }

  /// Obtiene la cadena base para generar el HWID
  static Future<String> _getHardwareBase() async {
    final parts = <String>[];
    
    try {
      // 1. MAC Address (primera disponible)
      final macAddress = await _getMacAddress();
      if (macAddress.isNotEmpty) {
        parts.add(macAddress);
      }
    } catch (e) {
      print('Error obteniendo MAC address: $e');
    }

    try {
      // 2. Hostname
      final hostname = Platform.localHostname;
      if (hostname.isNotEmpty) {
        parts.add(hostname);
      }
    } catch (e) {
      print('Error obteniendo hostname: $e');
    }

    try {
      // 3. Información del SO
      final osInfo = _getOSInfo();
      parts.add(osInfo);
    } catch (e) {
      print('Error obteniendo info del SO: $e');
    }

    try {
      // 4. Modelo de dispositivo
      final deviceModel = _getDeviceModel();
      if (deviceModel.isNotEmpty) {
        parts.add(deviceModel);
      }
    } catch (e) {
      print('Error obteniendo modelo del dispositivo: $e');
    }

    // Si no se obtuvo ninguna información, usar fallback
    if (parts.isEmpty) {
      parts.add('unknown_device_${DateTime.now().millisecondsSinceEpoch}');
    }

    // Concatenar todas las partes
    return parts.join('|');
  }

  /// Obtiene la MAC address del dispositivo
  static Future<String> _getMacAddress() async {
    try {
      if (Platform.isWindows) {
        return await _getWindowsMacAddress();
      } else if (Platform.isLinux || Platform.isMacOS) {
        return await _getUnixMacAddress();
      } else {
        // Para otras plataformas, usar un identificador único
        return 'mobile_${Platform.operatingSystem}_${Platform.operatingSystemVersion}';
      }
    } catch (e) {
      return '';
    }
  }

  /// Obtiene MAC address en Windows
  static Future<String> _getWindowsMacAddress() async {
    try {
      final result = await Process.run('getmac', ['/fo', 'csv', '/nh']);
      final output = result.stdout.toString();
      
      final lines = output.split('\n');
      for (final line in lines) {
        if (line.contains('"')) {
          final parts = line.split(',');
          if (parts.length >= 4) {
            var mac = parts[0].replaceAll('"', '').trim();
            if (mac.isNotEmpty && mac != 'N/A') {
              return mac;
            }
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene MAC address en sistemas Unix (Linux/Mac)
  static Future<String> _getUnixMacAddress() async {
    try {
      // Intentar con ifconfig primero
      final result = await Process.run('ifconfig', []);
      final output = result.stdout.toString();
      
      // Buscar patrones de MAC address
      final macPattern = RegExp(r'([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})');
      final match = macPattern.firstMatch(output);
      
      if (match != null) {
        return match.group(0)!.replaceAll(':', '').toUpperCase();
      }
      
      // Fallback a ip link
      final ipResult = await Process.run('ip', ['link', 'show']);
      final ipOutput = ipResult.stdout.toString();
      final ipMatch = macPattern.firstMatch(ipOutput);
      
      if (ipMatch != null) {
        return ipMatch.group(0)!.replaceAll(':', '').toUpperCase();
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Obtiene información del sistema operativo
  static String _getOSInfo() {
    final os = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    return '$os $version';
  }

  /// Obtiene el modelo del dispositivo
  static String _getDeviceModel() {
    try {
      if (Platform.isWindows) {
        return 'Windows_${Platform.operatingSystemVersion}';
      } else if (Platform.isLinux) {
        return 'Linux_${Platform.operatingSystemVersion}';
      } else if (Platform.isMacOS) {
        return 'macOS_${Platform.operatingSystemVersion}';
      } else {
        return '${Platform.operatingSystem}_${Platform.operatingSystemVersion}';
      }
    } catch (e) {
      return 'unknown_device';
    }
  }

  /// Genera una licencia con formato XXXX-XXXX-XXXX-XXXX
  static String generateLicenseKey() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final parts = <String>[];
    
    for (int i = 0; i < 4; i++) {
      final start = i * 8;
      final part = sha256
          .convert(utf8.encode('$random$i'))
          .toString()
          .substring(0, 4)
          .toUpperCase();
      parts.add(part);
    }
    
    return parts.join('-');
  }

  /// Función SHA256 genérica
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Valida formato de licencia
  static bool isValidLicenseFormat(String license) {
    final pattern = RegExp(r'^[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}$');
    return pattern.hasMatch(license);
  }
}
