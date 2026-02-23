import '../../domain/entities/phrase.dart';
import '../../domain/entities/phrase_with_progress.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/phrase_repository.dart';
import '../datasources/local_datasource.dart';

class PhraseRepositoryImpl implements PhraseRepository {
  final LocalDataSource _localDataSource;

  PhraseRepositoryImpl(this._localDataSource);

  @override
  Future<List<PhraseWithProgress>> getPhrasesByPatternId(int patternId) async {
    final data = await _localDataSource.getPhrasesByPatternId(patternId);
    return data.map((map) => _mapToPhraseWithProgress(map)).toList();
  }

  @override
  Future<Phrase?> getPhraseById(int id) async {
    // TODO: Implementar cuando sea necesario
    throw UnimplementedError('getPhraseById not implemented yet');
  }

  @override
  Future<List<PhraseWithProgress>> getDuePhrases({int limit = 10}) async {
    final data = await _localDataSource.getDuePhrases(limit);
    return data.map((map) => _mapToPhraseWithProgress(map)).toList();
  }

  @override
  Future<List<PhraseWithProgress>> getSmartMixPhrases({int limit = 20}) async {
    final data = await _localDataSource.getSmartMixPhrases(limit);
    return data.map((map) => _mapToPhraseWithProgress(map)).toList();
  }

  @override
  Future<void> syncPhrases(List<Map<String, dynamic>> phrasesData) async {
    // TODO: Implementar sincronización con servidor
    throw UnimplementedError('Sync not implemented yet');
  }

  PhraseWithProgress _mapToPhraseWithProgress(Map<String, dynamic> map) {
    final phrase = Phrase(
      id: map['id'] as int,
      patternId: map['pattern_id'] as int? ?? 0,
      textEn: map['text_en'] as String,
      textEs: map['text_es'] as String,
      audioUrl: map['audio_url'] as String?,
      imageUrl: map['image_url'] as String?,
    );

    final progress = UserProgress(
      phraseId: map['id'] as int,
      p1: (map['p1'] as int? ?? 0) == 1,
      p2: (map['p2'] as int? ?? 0) == 1,
      srsLevel: map['srs_level'] as int? ?? 0,
      nextReviewDate:
          map['next_review_date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                map['next_review_date'] as int,
              )
              : null,
      lastReviewedDate:
          map['last_reviewed_date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                map['last_reviewed_date'] as int,
              )
              : null,
      failCount: map['fail_count'] as int? ?? 0,
    );

    return PhraseWithProgress(
      phrase: phrase,
      progress: progress,
      patternTitle:
          map['pattern_title'] as String?, // Incluir pattern_title del Map
    );
  }
}
