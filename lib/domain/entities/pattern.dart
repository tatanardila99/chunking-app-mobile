/// Entity: Pattern (Patrón gramatical)
///
/// Representa un patrón gramatical en el dominio de la aplicación.
/// Esta es una clase pura de Dart sin dependencias de frameworks.
class Pattern {
  final int id;
  final String title;
  final String subtitle;
  final String grammarRule;
  final String level;
  final int sortOrder;
  final bool isActive;
  final int totalPhrases;
  final int masteredCount;

  const Pattern({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.grammarRule,
    required this.level,
    required this.sortOrder,
    this.isActive = true,
    this.totalPhrases = 0,
    this.masteredCount = 0,
  });

  /// Calcula el progreso del patrón (0.0 a 1.0)
  double get progress {
    if (totalPhrases == 0) return 0.0;
    return (masteredCount / totalPhrases).clamp(0.0, 1.0);
  }

  /// Verifica si el patrón está completado
  bool get isCompleted => totalPhrases > 0 && masteredCount >= totalPhrases;

  /// Verifica si el patrón está en progreso
  bool get isInProgress => masteredCount > 0 && !isCompleted;

  /// Copia el patrón con nuevos valores
  Pattern copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? grammarRule,
    String? level,
    int? sortOrder,
    bool? isActive,
    int? totalPhrases,
    int? masteredCount,
  }) {
    return Pattern(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      grammarRule: grammarRule ?? this.grammarRule,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      totalPhrases: totalPhrases ?? this.totalPhrases,
      masteredCount: masteredCount ?? this.masteredCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pattern && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Pattern(id: $id, title: $title, progress: ${(progress * 100).toStringAsFixed(0)}%)';
  }
}
