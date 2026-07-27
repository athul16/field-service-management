import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Thrown for any non-2xx response; [message] is the backend's `error`
/// field when present, otherwise a generic fallback.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Talks to the Java Spring Boot backend — replaces the old direct
/// Supabase client. Holds the JWT (persisted in secure storage) and
/// exposes it as [isAuthenticated] so [AuthGate] can react to login/logout
/// without any Supabase auth-state stream.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'auth_token';
  final _storage = const FlutterSecureStorage();

  late final String baseUrl;
  String? _token;

  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _token = await _storage.read(key: _tokenKey);
    isAuthenticated.value = _token != null;
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
    isAuthenticated.value = true;
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
    isAuthenticated.value = false;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await http.get(_uri(path, query), headers: _headers);
    return _handle(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await http.post(
      _uri(path),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(_uri(path), headers: _headers);
    return _handle(response);
  }

  /// Multipart POST for the clock-out photo upload.
  Future<dynamic> postMultipart(String path, {required String fieldName, required File file}) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    final extension = file.path.split('.').last.toLowerCase();
    final contentType = extension == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path, contentType: contentType));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    String message = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        message = decoded['error'] as String;
      }
    } catch (_) {
      // Non-JSON error body — keep the generic message.
    }
    throw ApiException(response.statusCode, message);
  }
}
