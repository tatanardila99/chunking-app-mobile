import '../../domain/entities/pattern.dart';
import '../../domain/entities/stats.dart';

final mockPatterns = [
  Pattern(
    id: '1',
    title: "I'm allowed to drive",
    subtitle: "Tengo permiso para conducir",
    state: PatternState.mastered,
    progress: 1.0,
  ),
  Pattern(
    id: '2',
    title: "I'm allowed to go out",
    subtitle: "Tengo permiso para salir",
    state: PatternState.active,
    progress: 0.45,
  ),
  Pattern(
    id: '3',
    title: "I'm allowed to stay up",
    subtitle: "Tengo permiso para trasnochar",
    state: PatternState.locked,
    progress: 0.0,
  ),
  Pattern(
    id: '4',
    title: "I'm allowed to use the car",
    subtitle: "Tengo permiso para usar el carro",
    state: PatternState.locked,
    progress: 0.0,
  ),
];

final mockStats = UserStats(
  dailyGoalPercent: 85,
  currentStreak: 14,
  weeklyProgress: {
    'MON': 0.3,
    'TUE': 0.5,
    'WED': 0.4,
    'THU': 0.7,
    'FRI': 0.9,
    'SAT': 0.6,
    'SUN': 0.2,
  },
  listeningTime: "12h 30m",
  chunksCollected: 142,
  fluencyScore: "B2",
  accuracyPercent: 94,
);
