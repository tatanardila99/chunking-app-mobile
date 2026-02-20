import '../entities/pattern.dart';
import '../repositories/pattern_repository.dart';

/// UseCase: GetPatternsUseCase
///
/// Obtiene todos los patrones gramaticales con su progreso.
///
/// Ejemplo de uso:
/// ```dart
/// final patterns = await getPatternsUseCase();
/// ```
class GetPatternsUseCase {
  final PatternRepository repository;

  GetPatternsUseCase(this.repository);

  Future<List<Pattern>> call() async {
    return await repository.getPatterns();
  }
}
