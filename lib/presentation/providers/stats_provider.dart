import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_activity.dart';
import 'dependency_injection.dart';

/// Provider para obtener estadísticas completas
final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final useCase = ref.watch(getStatsUseCaseProvider);
  return await useCase();
});

/// Provider para obtener XP del día
final dailyXPProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getDailyXP();
});

/// Provider para obtener racha actual
final currentStreakProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getCurrentStreak();
});

/// Provider para obtener actividad semanal
final weeklyActivityProvider = FutureProvider<List<DailyActivity>>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getWeeklyActivity();
});

/// Provider para obtener nivel del usuario
final userLevelProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getUserLevel();
});

/// Provider para obtener total de frases masterizadas
final totalMasteredPhrasesProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getTotalMasteredPhrases();
});

/// Provider para obtener horas de escucha
final totalListeningHoursProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(statsRepositoryProvider);
  return await repository.getTotalListeningHours();
});
