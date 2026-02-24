import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/feedback_service.dart';
import '../../providers/dependency_injection.dart';
import '../../providers/pattern_provider.dart';
import '../../providers/phrase_provider.dart';
import '../swipe_learning/widgets/completion_overlay.dart';

class SimpleSwipeScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> phrases;
  final String patternTitle;

  const SimpleSwipeScreen({
    super.key,
    required this.phrases,
    required this.patternTitle,
  });

  @override
  ConsumerState<SimpleSwipeScreen> createState() => _SimpleSwipeScreenState();
}

class _SimpleSwipeScreenState extends ConsumerState<SimpleSwipeScreen> {
  int _currentIndex = 0;
  bool _isRevealed = false;
  final FeedbackService _feedbackService = FeedbackService();
  int _completedCount = 0;
  bool _isCompleted = false;

  @override
  void dispose() {
    _feedbackService.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    final phrase = widget.phrases[_currentIndex];
    await AudioService.instance.speak(phrase['text_en'] as String);
  }

  Future<void> _handleSwipeRight() async {
    final phrase = widget.phrases[_currentIndex];
    final phraseId = phrase['id'] as int;
    final bool currentP1 = (phrase['p1'] as int? ?? 0) == 1;
    final bool currentP2 = (phrase['p2'] as int? ?? 0) == 1;

    // Feedback
    await _feedbackService.triggerHaptic(HapticType.medium);
    await _feedbackService.playSuccessSound();
    if (mounted) {
      _feedbackService.showSwipeAnimation(context, SwipeDirection.right);
    }

    // Actualizar progreso en base de datos de forma inteligente
    try {
      final progressRepo = ref.read(progressRepositoryProvider);

      // Si P1 no está marcado, marcar P1 (primera vez)
      if (!currentP1) {
        await progressRepo.updateLegacyProgress(
          phraseId: phraseId,
          field: 'p1',
          value: true,
        );
      }
      // Si P1 está marcado pero P2 no, marcar P2 (segundo repaso)
      else if (currentP1 && !currentP2) {
        await progressRepo.updateLegacyProgress(
          phraseId: phraseId,
          field: 'p2',
          value: true,
        );
      }
      // Si ambos están marcados, no hacer nada (ya masterizado)

      setState(() {
        _completedCount++;
        _isRevealed = false;
      });

      // Esperar animación
      await Future.delayed(const Duration(milliseconds: 400));

      // Siguiente frase o completar
      if (_currentIndex < widget.phrases.length - 1) {
        setState(() {
          _currentIndex++;
        });
      } else {
        setState(() {
          _isCompleted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving progress')));
      }
    }
  }

  Future<void> _handleSwipeLeft() async {
    // Feedback
    await _feedbackService.triggerHaptic(HapticType.light);
    if (mounted) {
      _feedbackService.showSwipeAnimation(context, SwipeDirection.left);
    }

    setState(() {
      _isRevealed = false;
    });

    // Esperar animación
    await Future.delayed(const Duration(milliseconds: 400));

    // Siguiente frase
    if (_currentIndex < widget.phrases.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Si es la última, volver al inicio
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  void _handleBackToList() {
    // Invalidar providers para refrescar todas las pantallas
    ref.invalidate(patternsProvider);
    ref.invalidate(smartMixPhrasesProvider);
    ref.invalidate(phrasesByPatternProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: CompletionOverlay(
          completedCount: _completedCount,
          onBackToList: _handleBackToList,
        ),
      );
    }

    final phrase = widget.phrases[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: _handleBackToList,
        ),
        title: Column(
          children: [
            Text(
              widget.patternTitle.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              "${_currentIndex + 1} / ${widget.phrases.length} remaining",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Card
                  _buildPhraseCard(phrase),

                  const SizedBox(height: 50),

                  // Botones de acción (estilo de la app)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        // Botón SKIP
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A2A2A),
                              fixedSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _handleSwipeLeft,
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.red.shade400,
                              size: 24,
                            ),
                            label: Text(
                              "SKIP",
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Botón GOT IT
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              fixedSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: _handleSwipeRight,
                            icon: const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 24,
                            ),
                            label: const Text(
                              "GOT IT",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón de SONIDO (centro, abajo)
                  _buildSoundButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseCard(Map<String, dynamic> phrase) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isRevealed = !_isRevealed;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A2332), const Color(0xFF0F1419)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              blurRadius: 25,
              spreadRadius: -5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge "NEW PHRASE"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "NEW PHRASE",
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Imagen (si existe)
            if (phrase['image_url'] != null && phrase['image_url'] != '')
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    phrase['image_url'] as String,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Icon(
                            Icons.image_outlined,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                  ),
                ),
              )
            else
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 70,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                ),
              ),

            const SizedBox(height: 28),

            // English text con parte destacada
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                children: _buildHighlightedText(phrase['text_en'] as String),
              ),
            ),

            const SizedBox(height: 20),

            // Spanish translation (tap to reveal)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState:
                  _isRevealed
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Tap to reveal",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  phrase['text_es'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para destacar parte del texto en verde
  List<TextSpan> _buildHighlightedText(String text) {
    final words = text.split(' ');
    if (words.length <= 3) {
      return [
        TextSpan(
          text: text,
          style: const TextStyle(color: AppTheme.primaryGreen),
        ),
      ];
    }

    final highlighted = words.take(2).join(' ');
    final rest = words.skip(2).join(' ');

    return [
      TextSpan(
        text: highlighted,
        style: const TextStyle(color: AppTheme.primaryGreen),
      ),
      TextSpan(text: ' $rest'),
    ];
  }

  Widget _buildSoundButton() {
    return GestureDetector(
      onTap: _playAudio,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
