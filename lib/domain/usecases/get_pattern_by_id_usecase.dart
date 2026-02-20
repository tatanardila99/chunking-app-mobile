import '../entities/pattern.dart';
import '../repositories/pattern_repository.dart';

/// UseCase: GetPatternByIdUseCase
///
/// Obtiene un patrón específico por su ID.
class GetPatternByIdUseCase {
  final PatternRepository repository;

  GetPatternByIdUseCase(this.repository);

  Future<Pattern?> call(int id) async {
    return await repository.getPatternById(id);
  }
}
