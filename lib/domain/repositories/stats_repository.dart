import '../entities/daily_activity.dart';

/// Repository Interface: StatsRepository
///
/// Define el contrato para operaciones relacionadas con estadísticas.
abstract class StatsRepository {
  /// Obtiene el XP del día actual
  Future<int> getDailyXP();

  /// Obtiene la racha actual de días consecutivos
  Future<int> getCurrentStreak();

  /// Obtiene la actividad de la última semana
  Future<List<DailyActivity>> getWeeklyActivity();

  /// Obtiene el total de frases masterizadas
  Future<int> getTotalMasteredPhrases();

  /// Obtiene el total de horas de escucha
  Future<double> getTotalListeningHours();

  /// Obtiene el nivel actual del usuario (basado en patrones completados)
  Future<String> getUserLevel();

  /// Registra actividad del día (XP, frases, tiempo de escucha)
  Future<void> addDailyActivity({
    int? xp,
    int? phrasesCount,
    int? listeningSeconds,
  });
}
