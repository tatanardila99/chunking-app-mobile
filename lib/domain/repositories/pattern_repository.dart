import '../entities/pattern.dart';

/// Repository Interface: PatternRepository
///
/// Define el contrato para operaciones relacionadas con patrones gramaticales.
/// Las implementaciones concretas estarán en la capa de datos.
abstract class PatternRepository {
  /// Obtiene todos los patrones con su progreso
  Future<List<Pattern>> getPatterns();

  /// Obtiene un patrón por su ID
  Future<Pattern?> getPatternById(int id);

  /// Obtiene patrones desbloqueados (según progresión del usuario)
  Future<List<Pattern>> getUnlockedPatterns();

  /// Recalcula los contadores de progreso de todos los patrones
  Future<void> recalculatePatternCounts();

  /// Sincroniza patrones desde el servidor
  Future<void> syncPatterns(List<Map<String, dynamic>> patternsData);
}
