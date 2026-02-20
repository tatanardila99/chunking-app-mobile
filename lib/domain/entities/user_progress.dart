/// Entity: UserProgress (Progreso del usuario)
///
/// Representa el progreso de un usuario en una frase específica.
/// Combina el sistema legacy (P1/P2) con el sistema SRS.
class UserProgress {
  final int phraseId;
  final bool p1; // Legacy: Primera práctica
  final bool p2; // Legacy: Segunda práctica
  final int srsLevel; // 0=Nuevo, 1=Aprendido, 2=Retenido, 3=Maestro
  final DateTime? nextReviewDate;
  final DateTime? lastReviewedDate;
  final int failCount;

  const UserProgress({
    required this.phraseId,
    this.p1 = false,
    this.p2 = false,
    this.srsLevel = 0,
    this.nextReviewDate,
    this.lastReviewedDate,
    this.failCount = 0,
  });

  /// Verifica si la frase está masterizada (sistema legacy)
  bool get isMastered => p1 && p2;

  /// Verifica si la frase está vencida para revisión (SRS)
  bool get isDue {
    if (nextReviewDate == null) return true; // Nueva frase
    return DateTime.now().isAfter(nextReviewDate!);
  }

  /// Obtiene el nivel SRS como texto
  String get srsLevelText {
    switch (srsLevel) {
      case 0:
        return 'New';
      case 1:
        return 'Learning';
      case 2:
        return 'Retained';
      case 3:
        return 'Mastered';
      default:
        return 'Unknown';
    }
  }

  /// Copia el progreso con nuevos valores
  UserProgress copyWith({
    int? phraseId,
    bool? p1,
    bool? p2,
    int? srsLevel,
    DateTime? nextReviewDate,
    DateTime? lastReviewedDate,
    int? failCount,
  }) {
    return UserProgress(
      phraseId: phraseId ?? this.phraseId,
      p1: p1 ?? this.p1,
      p2: p2 ?? this.p2,
      srsLevel: srsLevel ?? this.srsLevel,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedDate: lastReviewedDate ?? this.lastReviewedDate,
      failCount: failCount ?? this.failCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress && other.phraseId == phraseId;
  }

  @override
  int get hashCode => phraseId.hashCode;

  @override
  String toString() {
    return 'UserProgress(phraseId: $phraseId, srsLevel: $srsLevel, isMastered: $isMastered)';
  }
}
