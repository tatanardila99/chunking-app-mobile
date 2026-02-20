import '../../domain/entities/daily_activity.dart';
import '../../domain/repositories/stats_repository.dart';
import '../datasources/local_datasource.dart';

class StatsRepositoryImpl implements StatsRepository {
  final LocalDataSource _localDataSource;

  StatsRepositoryImpl(this._localDataSource);

  @override
  Future<int> getDailyXP() async {
    return await _localDataSource.getDailyXP();
  }

  @override
  Future<int> getCurrentStreak() async {
    return await _localDataSource.getCurrentStreak();
  }

  @override
  Future<List<DailyActivity>> getWeeklyActivity() async {
    final data = await _localDataSource.getWeeklyStats();
    return data.map((map) => _mapToDailyActivity(map)).toList();
  }

  @override
  Future<int> getTotalMasteredPhrases() async {
    final stats = await _localDataSource.getGlobalStats();
    return stats['chunks_collected'] ?? 0;
  }

  @override
  Future<double> getTotalListeningHours() async {
    return await _localDataSource.getTotalListeningHours();
  }

  @override
  Future<String> getUserLevel() async {
    return await _localDataSource.getUserLevel();
  }

  @override
  Future<void> addDailyActivity({
    int? xp,
    int? phrasesCount,
    int? listeningSeconds,
  }) async {
    if (phrasesCount != null) {
      await _localDataSource.addPhraseCount(phrasesCount);
    }
    // TODO: Implementar actualización de XP y listening seconds
  }

  DailyActivity _mapToDailyActivity(Map<String, dynamic> map) {
    // El formato de getWeeklyStats es diferente, tiene 'day' (letra) y 'value'
    // Necesitamos convertir esto a DailyActivity
    final now = DateTime.now();
    final dayIndex = _getDayIndex(map['day'] as String);
    final date = now.subtract(Duration(days: 6 - dayIndex));

    return DailyActivity(
      date: date,
      phrasesCount: map['value'] as int,
      xp: 0, // No disponible en este formato
      listeningSeconds: 0, // No disponible en este formato
    );
  }

  int _getDayIndex(String dayLetter) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days.indexOf(dayLetter);
  }
}
