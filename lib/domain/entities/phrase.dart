/// Entity: Phrase (Frase de práctica)
///
/// Representa una frase individual dentro de un patrón gramatical.
/// Esta es una clase pura de Dart sin dependencias de frameworks.
class Phrase {
  final int id;
  final int patternId;
  final String textEn;
  final String textEs;
  final String? audioUrl;
  final String? imageUrl;

  const Phrase({
    required this.id,
    required this.patternId,
    required this.textEn,
    required this.textEs,
    this.audioUrl,
    this.imageUrl,
  });

  /// Verifica si la frase tiene audio disponible
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  /// Verifica si la frase tiene imagen (visual anchor)
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Copia la frase con nuevos valores
  Phrase copyWith({
    int? id,
    int? patternId,
    String? textEn,
    String? textEs,
    String? audioUrl,
    String? imageUrl,
  }) {
    return Phrase(
      id: id ?? this.id,
      patternId: patternId ?? this.patternId,
      textEn: textEn ?? this.textEn,
      textEs: textEs ?? this.textEs,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Phrase && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Phrase(id: $id, textEn: $textEn)';
  }
}
