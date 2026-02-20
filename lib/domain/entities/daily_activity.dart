/// Entity: DailyActivity (Actividad diaria)
///
/// Representa la actividad del usuario en un día específico.
class DailyActivity {
  final DateTime date;
  final int xp;
  final int phrasesCount;
  final int listeningSeconds;

  const DailyActivity({
    required this.date,
    this.xp = 0,
    this.phrasesCount = 0,
    this.listeningSeconds = 0,
  });

  /// Obtiene las horas de escucha
  double get listeningHours => listeningSeconds / 3600.0;

  /// Verifica si hubo actividad en este día
  bool get hasActivity => phrasesCount > 0 || listeningSeconds > 0;

  /// Copia la actividad con nuevos valores
  DailyActivity copyWith({
    DateTime? date,
    int? xp,
    int? phrasesCount,
    int? listeningSeconds,
  }) {
    return DailyActivity(
      date: date ?? this.date,
      xp: xp ?? this.xp,
      phrasesCount: phrasesCount ?? this.phrasesCount,
      listeningSeconds: listeningSeconds ?? this.listeningSeconds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyActivity &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day;
  }

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() {
    return 'DailyActivity(date: ${date.toIso8601String().split('T')[0]}, xp: $xp, phrases: $phrasesCount)';
  }
}
