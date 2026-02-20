import '../entities/user_progress.dart';

/// Repository Interface: ProgressRepository
///
/// Define el contrato para operaciones relacionadas con el progreso del usuario.
abstract class ProgressRepository {
  /// Obtiene el progreso de una frase específica
  Future<UserProgress?> getProgressByPhraseId(int phraseId);

  /// Actualiza el progreso legacy (P1/P2)
  Future<void> updateLegacyProgress({
    required int phraseId,
    required String field, // 'p1' o 'p2'
    required bool value,
  });

  /// Actualiza el progreso SRS después de una práctica
  Future<void> updateSRSProgress({
    required int phraseId,
    required bool isCorrect,
    String mode = 'standard',
    int? responseTimeMs,
  });

  /// Registra una sesión de práctica en los logs
  Future<void> logSession({
    required int phraseId,
    required String mode,
    required bool isCorrect,
    int? responseTimeMs,
  });
}
