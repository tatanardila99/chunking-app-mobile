import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:slotch/core/services/audio_service.dart';
import '../dependency_injection.dart';
import 'swipe_learning_controller.dart';
import 'swipe_learning_state.dart';

/// Provider for AudioService singleton
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService.instance;
});

/// Provider for SwipeLearningController
final swipeLearningControllerProvider =
    StateNotifierProvider<SwipeLearningController, SwipeLearningState>((ref) {
      final progressRepository = ref.watch(progressRepositoryProvider);
      final audioService = ref.watch(audioServiceProvider);

      return SwipeLearningController(
        progressRepository: progressRepository,
        audioService: audioService,
      );
    });
