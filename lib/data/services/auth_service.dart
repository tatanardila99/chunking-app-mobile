import 'dart:convert';
import 'package:Slocth/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Ya no necesitamos definir baseUrl aquí
  final _storage = const FlutterSecureStorage();

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // USAMOS ApiConfig.authLogin
      final response = await http.post(
        Uri.parse(ApiConfig.authLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Guardar Token y Datos
        await _storage.write(key: 'jwt_token', value: data['token']);
        await _storage.write(key: 'user_name', value: data['user']['name']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // REGISTER
  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authRegister),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // CHECK SI ESTÁ LOGUEADO
  Future<bool> isLoggedIn() async {
    String? token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}
