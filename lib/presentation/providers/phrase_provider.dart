import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/phrase_with_progress.dart';
import 'dependency_injection.dart';

/// Provider para obtener frases de un patrón específico
final phrasesByPatternProvider =
    FutureProvider.family<List<PhraseWithProgress>, int>((
      ref,
      patternId,
    ) async {
      final useCase = ref.watch(getPhrasesByPatternUseCaseProvider);
      return await useCase(patternId);
    });

/// Provider para obtener frases vencidas (SRS)
final duePhrasesProvider = FutureProvider.family<List<PhraseWithProgress>, int>(
  (ref, limit) async {
    final useCase = ref.watch(getDuePhrasesUseCaseProvider);
    return await useCase(limit: limit);
  },
);

/// Provider para obtener Smart Mix de frases
final smartMixPhrasesProvider =
    FutureProvider.family<List<PhraseWithProgress>, int>((ref, limit) async {
      final repository = ref.watch(phraseRepositoryProvider);
      return await repository.getSmartMixPhrases(limit: limit);
    });
