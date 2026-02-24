import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

enum HapticType { medium, light }

enum SwipeDirection { right, left }

class FeedbackService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Play success sound for right swipe
  Future<void> playSuccessSound() async {
    try {
      // Using a simple beep sound - you can replace with custom sound file
      // For now, we'll use system sound
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('Error playing success sound: $e');
      // Gracefully continue without sound
    }
  }

  // Trigger haptic feedback
  Future<void> triggerHaptic(HapticType type) async {
    try {
      switch (type) {
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticType.light:
          await HapticFeedback.lightImpact();
          break;
      }
    } catch (e) {
      debugPrint('Error triggering haptic: $e');
      // Gracefully continue without haptic (device may not support it)
    }
  }

  // Show visual feedback animation overlay
  void showSwipeAnimation(BuildContext context, SwipeDirection direction) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => _SwipeAnimationOverlay(
            direction: direction,
            onComplete: () {
              overlayEntry.remove();
            },
          ),
    );

    overlay.insert(overlayEntry);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

class _SwipeAnimationOverlay extends StatefulWidget {
  final SwipeDirection direction;
  final VoidCallback onComplete;

  const _SwipeAnimationOverlay({
    required this.direction,
    required this.onComplete,
  });

  @override
  State<_SwipeAnimationOverlay> createState() => _SwipeAnimationOverlayState();
}

class _SwipeAnimationOverlayState extends State<_SwipeAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRight = widget.direction == SwipeDirection.right;
    final color = isRight ? const Color(0xFF21E5A0) : Colors.yellow.shade700;
    final icon = isRight ? Icons.check_circle_rounded : Icons.refresh_rounded;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                    ),
                    child: Icon(icon, color: color, size: 64),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
