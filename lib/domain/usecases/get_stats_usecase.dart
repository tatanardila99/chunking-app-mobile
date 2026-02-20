import '../repositories/stats_repository.dart';

/// UseCase: GetStatsUseCase
///
/// Obtiene todas las estadísticas del usuario en un solo llamado.
/// Retorna un mapa con todas las métricas principales.
class GetStatsUseCase {
  final StatsRepository repository;

  GetStatsUseCase(this.repository);

  Future<Map<String, dynamic>> call() async {
    final results = await Future.wait([
      repository.getDailyXP(),
      repository.getCurrentStreak(),
      repository.getTotalMasteredPhrases(),
      repository.getTotalListeningHours(),
      repository.getUserLevel(),
      repository.getWeeklyActivity(),
    ]);

    return {
      'dailyXP': results[0] as int,
      'currentStreak': results[1] as int,
      'totalMasteredPhrases': results[2] as int,
      'totalListeningHours': results[3] as double,
      'userLevel': results[4] as String,
      'weeklyActivity': results[5],
    };
  }
}
