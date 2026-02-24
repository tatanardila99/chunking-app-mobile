import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:slotch/core/services/audio_service.dart';
import 'package:slotch/domain/entities/phrase_with_progress.dart';
import 'package:slotch/domain/repositories/progress_repository.dart';
import '../dependency_injection.dart';
import 'swipe_learning_provider.dart';
import 'swipe_learning_state.dart';

/// Controller for Swipe Learning Mode
///
/// Manages the session state, queue operations, and integrates with
/// ProgressRepository for P1 updates and AudioService for TTS playback.
class SwipeLearningController extends StateNotifier<SwipeLearningState> {
  final ProgressRepository _progressRepository;
  final AudioService _audioService;

  SwipeLearningController({
    required ProgressRepository progressRepository,
    required AudioService audioService,
  }) : _progressRepository = progressRepository,
       _audioService = audioService,
       super(SwipeLearningState.initial());

  /// Initialize the session with a list of phrases
  void initialize(List<PhraseWithProgress> phrases) {
    if (phrases.isEmpty) {
      state = state.copyWith(
        queue: [],
        totalPhrases: 0,
        completedCount: 0,
        isCompleted: true,
        errorMessage: 'No phrases available for practice',
      );
      return;
    }

    state = state.copyWith(
      queue: List.from(phrases),
      totalPhrases: phrases.length,
      completedCount: 0,
      isCompleted: false,
      errorMessage: null,
    );
  }

  /// Handle right swipe: mark P1 as true, remove from queue
  Future<void> swipeRight(int phraseId) async {
    try {
      // Stop any playing audio
      await _audioService.stopTts();

      // Update P1 in database with retry logic
      bool success = false;
      int attempts = 0;
      const maxAttempts = 2;

      while (!success && attempts < maxAttempts) {
        try {
          await _progressRepository.updateLegacyProgress(
            phraseId: phraseId,
            field: 'p1',
            value: true,
          );
          success = true;
        } catch (e) {
          attempts++;
          if (attempts >= maxAttempts) {
            debugPrint('Failed to update P1 after $maxAttempts attempts: $e');
            // Show error and keep phrase in queue
            state = state.copyWith(
              errorMessage: 'Failed to save progress. Please try again.',
            );
            return;
          }
          // Wait a bit before retrying
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Remove phrase from queue
      final updatedQueue = List<PhraseWithProgress>.from(state.queue);
      updatedQueue.removeWhere((p) => p.id == phraseId);

      // Update state
      final newCompletedCount = state.completedCount + 1;
      final isCompleted = updatedQueue.isEmpty;

      state = state.copyWith(
        queue: updatedQueue,
        completedCount: newCompletedCount,
        isCompleted: isCompleted,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('Error in swipeRight: $e');
      state = state.copyWith(
        errorMessage: 'An error occurred. Please try again.',
      );
    }
  }

  /// Handle left swipe: add to back of queue, no progress update
  Future<void> swipeLeft(int phraseId) async {
    try {
      // Stop any playing audio
      await _audioService.stopTts();

      // Find the phrase in the queue
      final phraseIndex = state.queue.indexWhere((p) => p.id == phraseId);
      if (phraseIndex == -1) {
        debugPrint('Phrase $phraseId not found in queue');
        return;
      }

      // Remove from current position and add to back
      final updatedQueue = List<PhraseWithProgress>.from(state.queue);
      final phrase = updatedQueue.removeAt(phraseIndex);
      updatedQueue.add(phrase);

      // Update state (total phrases increases as we re-queue)
      state = state.copyWith(
        queue: updatedQueue,
        totalPhrases: state.totalPhrases + 1,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('Error in swipeLeft: $e');
      state = state.copyWith(
        errorMessage: 'An error occurred. Please try again.',
      );
    }
  }

  /// Get the current phrase (first in queue)
  PhraseWithProgress? getCurrentPhrase() {
    if (state.queue.isEmpty) return null;
    return state.queue.first;
  }

  /// Get progress information
  String getProgress() {
    return state.progressText;
  }

  /// Clear any error message
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Reset the controller state
  void reset() {
    state = SwipeLearningState.initial();
  }
}

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
