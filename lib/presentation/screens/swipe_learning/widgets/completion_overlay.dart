import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class CompletionOverlay extends StatefulWidget {
  final int completedCount;
  final VoidCallback onBackToList;

  const CompletionOverlay({
    super.key,
    required this.completedCount,
    required this.onBackToList,
  });

  @override
  State<CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<CompletionOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _messageAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Animation controller for fade-ins
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Message fade-in (500ms delay)
    _messageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.33, 0.66, curve: Curves.easeOut),
      ),
    );

    // Button fade-in (1000ms delay)
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _confettiController.play();
    _animationController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color kAccentGreen = Color(0xFF21E5A0);

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Color(0xFF21E5A0),
                Color(0xFF2E3192),
                Color(0xFF1BFFFF),
                Colors.yellow,
                Colors.pink,
              ],
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Completion icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kAccentGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: kAccentGreen, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: kAccentGreen,
                      size: 80,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Message with fade-in
                  FadeTransition(
                    opacity: _messageAnimation,
                    child: Column(
                      children: [
                        const Text(
                          "Great job! 🎉",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "You marked ${widget.completedCount} ${widget.completedCount == 1 ? 'phrase' : 'phrases'} as known",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Button with fade-in
                  FadeTransition(
                    opacity: _buttonAnimation,
                    child: ElevatedButton(
                      onPressed: widget.onBackToList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        "Back to List",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
