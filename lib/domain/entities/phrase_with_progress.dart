import 'phrase.dart';
import 'user_progress.dart';

/// Entity: PhraseWithProgress
///
/// Combina una frase con su progreso de usuario.
/// Útil para mostrar frases en la UI con su estado de aprendizaje.
class PhraseWithProgress {
  final Phrase phrase;
  final UserProgress progress;
  final String? patternTitle; // Título del patrón (opcional, para UI)

  const PhraseWithProgress({
    required this.phrase,
    required this.progress,
    this.patternTitle,
  });

  /// Acceso rápido a propiedades de la frase
  int get id => phrase.id;
  int get patternId => phrase.patternId;
  String get textEn => phrase.textEn;
  String get textEs => phrase.textEs;
  String? get audioUrl => phrase.audioUrl;
  String? get imageUrl => phrase.imageUrl;

  /// Acceso rápido a propiedades del progreso
  bool get p1 => progress.p1;
  bool get p2 => progress.p2;
  int get srsLevel => progress.srsLevel;
  bool get isMastered => progress.isMastered;
  bool get isDue => progress.isDue;
  DateTime? get nextReviewDate => progress.nextReviewDate;

  /// Copia con nuevos valores
  PhraseWithProgress copyWith({
    Phrase? phrase,
    UserProgress? progress,
    String? patternTitle,
  }) {
    return PhraseWithProgress(
      phrase: phrase ?? this.phrase,
      progress: progress ?? this.progress,
      patternTitle: patternTitle ?? this.patternTitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhraseWithProgress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PhraseWithProgress(id: $id, textEn: $textEn, isMastered: $isMastered)';
  }
}
