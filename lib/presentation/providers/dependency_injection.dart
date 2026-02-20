import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/local/database_helper.dart';
import '../../data/repositories/pattern_repository_impl.dart';
import '../../data/repositories/phrase_repository_impl.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/repositories/stats_repository_impl.dart';
import '../../domain/repositories/pattern_repository.dart';
import '../../domain/repositories/phrase_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/stats_repository.dart';
import '../../domain/usecases/get_patterns_usecase.dart';
import '../../domain/usecases/get_pattern_by_id_usecase.dart';
import '../../domain/usecases/get_phrases_by_pattern_usecase.dart';
import '../../domain/usecases/get_due_phrases_usecase.dart';
import '../../domain/usecases/update_progress_usecase.dart';
import '../../domain/usecases/get_stats_usecase.dart';

// ==================== DATA SOURCES ====================

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return LocalDataSource(dbHelper);
});

// ==================== REPOSITORIES ====================

final patternRepositoryProvider = Provider<PatternRepository>((ref) {
  final localDataSource = ref.watch(localDataSourceProvider);
  return PatternRepositoryImpl(localDataSource);
});

final phraseRepositoryProvider = Provider<PhraseRepository>((ref) {
  final localDataSource = ref.watch(localDataSourceProvider);
  return PhraseRepositoryImpl(localDataSource);
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final localDataSource = ref.watch(localDataSourceProvider);
  return ProgressRepositoryImpl(localDataSource);
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final localDataSource = ref.watch(localDataSourceProvider);
  return StatsRepositoryImpl(localDataSource);
});

// ==================== USE CASES ====================

final getPatternsUseCaseProvider = Provider<GetPatternsUseCase>((ref) {
  final repository = ref.watch(patternRepositoryProvider);
  return GetPatternsUseCase(repository);
});

final getPatternByIdUseCaseProvider = Provider<GetPatternByIdUseCase>((ref) {
  final repository = ref.watch(patternRepositoryProvider);
  return GetPatternByIdUseCase(repository);
});

final getPhrasesByPatternUseCaseProvider = Provider<GetPhrasesByPatternUseCase>(
  (ref) {
    final repository = ref.watch(phraseRepositoryProvider);
    return GetPhrasesByPatternUseCase(repository);
  },
);

final getDuePhrasesUseCaseProvider = Provider<GetDuePhrasesUseCase>((ref) {
  final repository = ref.watch(phraseRepositoryProvider);
  return GetDuePhrasesUseCase(repository);
});

final updateProgressUseCaseProvider = Provider<UpdateProgressUseCase>((ref) {
  final repository = ref.watch(progressRepositoryProvider);
  return UpdateProgressUseCase(repository);
});

final getStatsUseCaseProvider = Provider<GetStatsUseCase>((ref) {
  final repository = ref.watch(statsRepositoryProvider);
  return GetStatsUseCase(repository);
});
