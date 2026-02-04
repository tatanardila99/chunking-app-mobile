// Lógica de intervalos SRS
DateTime calculateNextReview(int currentLevel, bool isCorrect) {
  if (!isCorrect) return DateTime.now(); // Nivel 0: Repetir hoy

  switch (currentLevel + 1) {
    case 1:
      return DateTime.now().add(const Duration(days: 1));
    case 2:
      return DateTime.now().add(const Duration(days: 4));
    case 3:
      return DateTime.now().add(const Duration(days: 14));
    default:
      return DateTime.now().add(const Duration(days: 1));
  }
}
