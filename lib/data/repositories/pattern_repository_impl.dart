import '../../domain/entities/pattern.dart';
import '../../domain/repositories/pattern_repository.dart';
import '../datasources/local_datasource.dart';
import '../local/database_helper.dart';

class PatternRepositoryImpl implements PatternRepository {
  final LocalDataSource _localDataSource;

  PatternRepositoryImpl(this._localDataSource);

  @override
  Future<List<Pattern>> getPatterns() async {
    final data = await _localDataSource.getPatterns();
    return data.map((map) => _mapToPattern(map)).toList();
  }

  @override
  Future<Pattern?> getPatternById(int id) async {
    final data = await _localDataSource.getPatternById(id);
    if (data == null) return null;
    return _mapToPattern(data);
  }

  @override
  Future<List<Pattern>> getUnlockedPatterns() async {
    final allPatterns = await getPatterns();
    final List<Pattern> unlocked = [];

    for (final pattern in allPatterns) {
      unlocked.add(pattern);

      // Si el patrón actual no está 100% masterizado, detenemos
      if (!pattern.isCompleted) {
        break;
      }
    }

    return unlocked;
  }

  @override
  Future<void> recalculatePatternCounts() async {
    await DatabaseHelper.instance.recalculateAllPatternCounts();
  }

  @override
  Future<void> syncPatterns(List<Map<String, dynamic>> patternsData) async {
    // TODO: Implementar sincronización con servidor
    throw UnimplementedError('Sync not implemented yet');
  }

  Pattern _mapToPattern(Map<String, dynamic> map) {
    return Pattern(
      id: map['id'] as int,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      grammarRule: map['grammar_rule'] as String? ?? '',
      level: map['level'] as String? ?? 'A1',
      sortOrder: map['sort_order'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      totalPhrases: map['total_phrases'] as int? ?? 0,
      masteredCount: map['mastered_count'] as int? ?? 0,
    );
  }
}
