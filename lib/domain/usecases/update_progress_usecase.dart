import '../repositories/progress_repository.dart';

/// UseCase: UpdateProgressUseCase
///
/// Actualiza el progreso de una frase usando el sistema SRS.
/// Este es el método principal para registrar práctica.
///
/// Parámetros:
/// - phraseId: ID de la frase practicada
/// - isCorrect: Si la respuesta fue correcta
/// - mode: Modo de práctica ('standard', 'speed_drill', 'passive')
/// - responseTimeMs: Tiempo de respuesta en milisegundos (opcional)
class UpdateProgressUseCase {
  final ProgressRepository repository;

  UpdateProgressUseCase(this.repository);

  Future<void> call({
    required int phraseId,
    required bool isCorrect,
    String mode = 'standard',
    int? responseTimeMs,
  }) async {
    await repository.updateSRSProgress(
      phraseId: phraseId,
      isCorrect: isCorrect,
      mode: mode,
      responseTimeMs: responseTimeMs,
    );
  }
}
