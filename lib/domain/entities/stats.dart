class UserStats {
  final int dailyGoalPercent;
  final int currentStreak;
  final Map<String, double> weeklyProgress; // e.g., {'MON': 0.4, 'TUE': 0.6}
  final String listeningTime;
  final int chunksCollected;
  final String fluencyScore;
  final int accuracyPercent;

  UserStats({
    required this.dailyGoalPercent,
    required this.currentStreak,
    required this.weeklyProgress,
    required this.listeningTime,
    required this.chunksCollected,
    required this.fluencyScore,
    required this.accuracyPercent,
  });
}
