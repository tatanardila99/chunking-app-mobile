import '../entities/phrase_with_progress.dart';
import '../repositories/phrase_repository.dart';

/// UseCase: GetPhrasesByPatternUseCase
///
/// Obtiene todas las frases de un patrón con su progreso.
class GetPhrasesByPatternUseCase {
  final PhraseRepository repository;

  GetPhrasesByPatternUseCase(this.repository);

  Future<List<PhraseWithProgress>> call(int patternId) async {
    return await repository.getPhrasesByPatternId(patternId);
  }
}
