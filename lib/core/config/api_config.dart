import 'package:flutter/foundation.dart'; // Necesario para kReleaseMode

class ApiConfig {
  // --- TUS SERVIDORES ---

  // 1. URL LOCAL (Android Emulator usa 10.0.2.2, iOS usa localhost)
  static const String _devUrl = 'http://192.168.1.5:3000/api';

  // 2. URL PRODUCCIÓN (Tu servidor en Render/AWS/etc)
  static const String _prodUrl =
      'https://tu-backend-en-render.onrender.com/api';

  // --- SELECTOR INTELIGENTE ---
  static String get baseUrl {
    if (kReleaseMode) {
      return _prodUrl;   // Si corres 'flutter build apk' (Release) -> Usa Prod
    } else {
      return _devUrl; // Si corres 'flutter run' (Debug) -> Usa Local
    }
  }

  // --- ENDPOINTS (Para no equivocarnos escribiendo rutas) ---
  static String get authLogin => '$baseUrl/auth/login';
  static String get authRegister => '$baseUrl/auth/register';
  static String get syncData => '$baseUrl/sync'; // Para cuando hagamos la sync
}
