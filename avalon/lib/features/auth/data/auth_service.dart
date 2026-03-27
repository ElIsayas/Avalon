import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/logger.dart';

class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([this.message = 'Tu sesión ha vencido']);
  @override
  String toString() => message;
}

class NetworkAuthException implements Exception {
  final String message;
  const NetworkAuthException([this.message = 'Sin conexión a internet']);
  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _client;
  final FlutterSecureStorage _storage;

  AuthService(this._client)
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const _tokenKey = AppConstants.keySessionToken;

  Future<AppUser> signIn(String email, String password) async {
    AppLogger.auth('Intentando login para email: $email');

    try {
      final res = await _client.rpc('login', params: {
        'p_email': email,
        'p_password': password,
      });

      final data = Map<String, dynamic>.from(res as Map);
      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      final token =
          data['token']?.toString() ?? data['session_token']?.toString();
      if (token == null || token.isEmpty) {
        throw Exception('No se recibió token de sesión');
      }

      await _storage.write(key: _tokenKey, value: token);
      data['token'] = token;
      return AppUser.fromJson(data);
    } on SocketException {
      throw const NetworkAuthException();
    } catch (e, stackTrace) {
      AppLogger.auth('Error en signIn: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<AppUser?> getSessionUser() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        return null;
      }

      final res =
          await _client.rpc('validate_session', params: {'p_token': token});
      final data = Map<String, dynamic>.from(res as Map);
      final valid = data['valid'] == true;
      if (!valid) {
        await _storage.delete(key: _tokenKey);
        throw const SessionExpiredException();
      }

      data['token'] = token;
      return AppUser.fromJson(data);
    } on SocketException {
      throw const NetworkAuthException();
    } catch (e) {
      if (e is SessionExpiredException || e is NetworkAuthException) {
        rethrow;
      }
      await _storage.delete(key: _tokenKey);
      return null;
    }
  }

  Future<void> signOut(String token) async {
    try {
      await _client.rpc('logout', params: {'p_token': token});
    } catch (_) {
      // Si falla el RPC igual se limpia almacenamiento local.
    } finally {
      await _storage.delete(key: _tokenKey);
    }
  }

  Future<String?> getStoredToken() => _storage.read(key: _tokenKey);

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
