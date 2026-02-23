import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para obtener el nombre del usuario
/// TODO: Integrar con AuthService cuando esté listo
final userNameProvider = FutureProvider<String>((ref) async {
  // Por ahora retornamos un valor hardcodeado
  // En el futuro, esto vendrá de AuthService o SharedPreferences

  // Simulamos una llamada async
  await Future.delayed(const Duration(milliseconds: 100));

  // TODO: Reemplazar con:
  // final authService = ref.watch(authServiceProvider);
  // return await authService.getUserName();

  return "Tatan Ardila"; // Valor por defecto en dev
});

/// Provider para verificar si estamos en modo dev
final isDevModeProvider = Provider<bool>((ref) {
  // TODO: Leer de environment o config
  return true; // Por ahora siempre dev
});
