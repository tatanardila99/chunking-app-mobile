enum PatternState { locked, active, mastered }

class Pattern {
  final String id;
  final String title;
  final String subtitle;
  final PatternState state;
  final double progress; // 0.0 a 1.0

  Pattern({
    required this.id,
    required this.title,
    required this.subtitle,
    this.state = PatternState.locked,
    this.progress = 0.0,
  });
}
