import '../entities/phrase.dart';
import '../entities/phrase_with_progress.dart';

/// Repository Interface: PhraseRepository
///
/// Define el contrato para operaciones relacionadas con frases.
abstract class PhraseRepository {
  /// Obtiene todas las frases de un patrón con su progreso
  Future<List<PhraseWithProgress>> getPhrasesByPatternId(int patternId);

  /// Obtiene una frase por su ID
  Future<Phrase?> getPhraseById(int id);

  /// Obtiene frases vencidas para revisión SRS
  Future<List<PhraseWithProgress>> getDuePhrases({int limit = 10});

  /// Obtiene un mix inteligente de frases de patrones desbloqueados
  Future<List<PhraseWithProgress>> getSmartMixPhrases({int limit = 20});

  /// Sincroniza frases desde el servidor
  Future<void> syncPhrases(List<Map<String, dynamic>> phrasesData);
}
