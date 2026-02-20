import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pattern.dart';
import 'dependency_injection.dart';

/// Provider para obtener todos los patrones
final patternsProvider = FutureProvider<List<Pattern>>((ref) async {
  final useCase = ref.watch(getPatternsUseCaseProvider);
  return await useCase();
});

/// Provider para obtener un patrón específico por ID
final patternByIdProvider = FutureProvider.family<Pattern?, int>((
  ref,
  id,
) async {
  final useCase = ref.watch(getPatternByIdUseCaseProvider);
  return await useCase(id);
});

/// Provider para obtener patrones desbloqueados
final unlockedPatternsProvider = FutureProvider<List<Pattern>>((ref) async {
  final repository = ref.watch(patternRepositoryProvider);
  return await repository.getUnlockedPatterns();
});
