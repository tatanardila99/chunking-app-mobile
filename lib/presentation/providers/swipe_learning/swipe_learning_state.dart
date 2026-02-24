import 'package:slotch/domain/entities/phrase_with_progress.dart';

/// State class for Swipe Learning Mode
///
/// Manages the queue of phrases, progress tracking, and completion status
/// for a swipe learning session.
class SwipeLearningState {
  final List<PhraseWithProgress> queue;
  final int totalPhrases;
  final int completedCount;
  final bool isCompleted;
  final String? errorMessage;

  const SwipeLearningState({
    required this.queue,
    required this.totalPhrases,
    required this.completedCount,
    required this.isCompleted,
    this.errorMessage,
  });

  /// Initial state with empty queue
  factory SwipeLearningState.initial() {
    return const SwipeLearningState(
      queue: [],
      totalPhrases: 0,
      completedCount: 0,
      isCompleted: false,
      errorMessage: null,
    );
  }

  /// Computed property: Number of phrases remaining in queue
  int get remainingCount => queue.length;

  /// Computed property: Current position (1-indexed)
  int get currentPosition => completedCount + 1;

  /// Computed property: Progress text for display (e.g., "5 / 20")
  String get progressText => "$currentPosition / $totalPhrases";

  /// Computed property: Progress percentage (0.0 to 1.0)
  double get progressPercentage =>
      totalPhrases > 0 ? completedCount / totalPhrases : 0.0;

  /// Creates a copy with updated fields
  SwipeLearningState copyWith({
    List<PhraseWithProgress>? queue,
    int? totalPhrases,
    int? completedCount,
    bool? isCompleted,
    String? errorMessage,
  }) {
    return SwipeLearningState(
      queue: queue ?? this.queue,
      totalPhrases: totalPhrases ?? this.totalPhrases,
      completedCount: completedCount ?? this.completedCount,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwipeLearningState &&
        other.queue == queue &&
        other.totalPhrases == totalPhrases &&
        other.completedCount == completedCount &&
        other.isCompleted == isCompleted &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    queue,
    totalPhrases,
    completedCount,
    isCompleted,
    errorMessage,
  );

  @override
  String toString() {
    return 'SwipeLearningState(queue: ${queue.length}, totalPhrases: $totalPhrases, '
        'completedCount: $completedCount, isCompleted: $isCompleted)';
  }
}
