class PatternEntity {
  final String id;
  final String title; // Ej: "I'm allowed to..."
  final String description; // Ej: "Permisos y reglas"
  final double progress; // 0.0 a 1.0 (Para la barra)
  final bool isNew; // Para mostrar un puntito de notificación

  PatternEntity({
    required this.id,
    required this.title,
    required this.description,
    this.progress = 0.0,
    this.isNew = false,
  });
}
