import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/local_datasource.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final LocalDataSource _localDataSource;

  ProgressRepositoryImpl(this._localDataSource);

  @override
  Future<UserProgress?> getProgressByPhraseId(int phraseId) async {
    final data = await _localDataSource.getProgressByPhraseId(phraseId);
    if (data == null) return null;

    return UserProgress(
      phraseId: data['phrase_id'] as int,
      p1: (data['p1'] as int? ?? 0) == 1,
      p2: (data['p2'] as int? ?? 0) == 1,
      srsLevel: data['srs_level'] as int? ?? 0,
      nextReviewDate:
          data['next_review_date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                data['next_review_date'] as int,
              )
              : null,
      lastReviewedDate:
          data['last_reviewed_date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                data['last_reviewed_date'] as int,
              )
              : null,
      failCount: data['fail_count'] as int? ?? 0,
    );
  }

  @override
  Future<void> updateLegacyProgress({
    required int phraseId,
    required String field,
    required bool value,
  }) async {
    await _localDataSource.updateProgress(phraseId, field, value);
  }

  @override
  Future<void> updateSRSProgress({
    required int phraseId,
    required bool isCorrect,
    String mode = 'standard',
    int? responseTimeMs,
  }) async {
    // Obtener progreso actual
    final currentProgress = await getProgressByPhraseId(phraseId);
    final int currentLevel = currentProgress?.srsLevel ?? 0;
    final int currentFailCount = currentProgress?.failCount ?? 0;
    final bool currentP1 = currentProgress?.p1 ?? false;
    final bool currentP2 = currentProgress?.p2 ?? false;

    final now = DateTime.now();

    int newLevel = currentLevel;
    int intervalDays = 1;
    int newFailCount = currentFailCount;

    if (isCorrect) {
      // Respuesta correcta: subir nivel
      newLevel = (currentLevel + 1).clamp(0, 3);

      // Marcar P1 automáticamente en el primer repaso correcto (si no está marcado)
      if (!currentP1) {
        await updateLegacyProgress(
          phraseId: phraseId,
          field: 'p1',
          value: true,
        );
      }
      // Marcar P2 automáticamente en el segundo repaso correcto (si P1 ya está marcado pero P2 no)
      else if (currentP1 && !currentP2) {
        await updateLegacyProgress(
          phraseId: phraseId,
          field: 'p2',
          value: true,
        );
      }

      // Intervalos: 1 día, 4 días, 14 días
      switch (newLevel) {
        case 1:
          intervalDays = 1;
          break;
        case 2:
          intervalDays = 4;
          break;
        case 3:
          intervalDays = 14;
          break;
        default:
          intervalDays = 1;
      }
    } else {
      // Respuesta incorrecta: resetear a nivel 0
      newLevel = 0;
      intervalDays = 1;
      newFailCount++;
    }

    final nextReview = now.add(Duration(days: intervalDays));

    await _localDataSource.updateSRSProgress(
      phraseId: phraseId,
      srsLevel: newLevel,
      nextReviewDate: nextReview.millisecondsSinceEpoch,
      lastReviewedDate: now.millisecondsSinceEpoch,
      failCount: newFailCount,
    );

    // Registrar sesión si se proporcionó responseTimeMs
    if (responseTimeMs != null) {
      await logSession(
        phraseId: phraseId,
        mode: mode,
        isCorrect: isCorrect,
        responseTimeMs: responseTimeMs,
      );
    }
  }

  @override
  Future<void> logSession({
    required int phraseId,
    required String mode,
    required bool isCorrect,
    int? responseTimeMs,
  }) async {
    await _localDataSource.logSession(
      phraseId: phraseId,
      mode: mode,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
    );
  }
}
