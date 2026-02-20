import '../entities/phrase_with_progress.dart';
import '../repositories/phrase_repository.dart';

/// UseCase: GetDuePhrasesUseCase
///
/// Obtiene las frases que están vencidas para revisión según el sistema SRS.
///
/// Parámetros:
/// - limit: Número máximo de frases a obtener (default: 10)
class GetDuePhrasesUseCase {
  final PhraseRepository repository;

  GetDuePhrasesUseCase(this.repository);

  Future<List<PhraseWithProgress>> call({int limit = 10}) async {
    return await repository.getDuePhrases(limit: limit);
  }
}
