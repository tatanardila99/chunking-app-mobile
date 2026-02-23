import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../domain/entities/phrase_with_progress.dart';
import '../../providers/dependency_injection.dart';

class SlotMachineScreen extends ConsumerStatefulWidget {
  final List<PhraseWithProgress> phrases;

  const SlotMachineScreen({super.key, required this.phrases});

  @override
  ConsumerState<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends ConsumerState<SlotMachineScreen> {
  int _currentIndex = 0;
  final _controller = TextEditingController();
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    AudioService.instance.stopTts();
    super.dispose();
  }

  // --- LÓGICA DE AUDIO INTELIGENTE ---
  void _toggleListening() async {
    if (_isListening) {
      await AudioService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _controller.clear();

      await AudioService.instance.startListening(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() => _controller.text = text);

          if (isFinal) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted && !_isAnswered && _controller.text.isNotEmpty) {
                _checkAnswer();
                setState(() => _isListening = false);
              }
            });
          }
        },
        onError: (errorMsg) {
          if (!mounted) return;
          setState(() => _isListening = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Your internet connection is slow. Try downloading offline language pack.",
              ),
              backgroundColor: const Color.fromARGB(255, 16, 148, 148),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }
  }

  // --- LÓGICA DEL JUEGO ---
  void _checkAnswer() {
    if (_controller.text.trim().isEmpty) return;

    // Asegurar que el micro se apague si validamos manual
    if (_isListening) {
      AudioService.instance.stopListening();
      setState(() => _isListening = false);
    }

    final current = widget.phrases[_currentIndex];
    // Aquí necesitamos el pattern_title - lo obtendremos del contexto
    // Por ahora usamos una aproximación
    final String fullPhrase = current.textEn;

    // Limpieza de strings para evitar errores tontos (puntos, espacios extra)
    final cleanFull = fullPhrase.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    final cleanUser = _controller.text.trim().toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    setState(() {
      _isCorrect = cleanUser == cleanFull;
      _isAnswered = true;
    });

    // FEEDBACK AUDITIVO
    if (_isCorrect) {
      AudioService.instance.speak(current.textEn);
    }

    _processSRSUpdate(current);
  }

  Future<void> _processSRSUpdate(PhraseWithProgress current) async {
    final progressRepo = ref.read(progressRepositoryProvider);

    await progressRepo.updateSRSProgress(
      phraseId: current.id,
      isCorrect: _isCorrect,
      mode: 'slot_machine',
    );
  }

  void _nextPhrase() {
    if (_currentIndex < widget.phrases.length - 1) {
      setState(() {
        _currentIndex++;
        _controller.clear();
        _isAnswered = false;
        _isCorrect = false;
        _isListening = false;
      });
    } else {
      context.pop();
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final current = widget.phrases[_currentIndex];
    final progress = (_currentIndex + 1) / widget.phrases.length;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: _buildStepIndicator(progress),
        centerTitle: true,
      ),
      body: Stack(
        children: [
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildPatternHeader(
                    widget.phrases[_currentIndex].patternTitle ?? "PRACTICE",
                  ),
                  const SizedBox(height: 30),
                  _buildVisualSlot(current.imageUrl),
                  const SizedBox(height: 40),
                  _buildModernInput(),
                  if (_isAnswered) _buildFeedbackArea(current),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildStepIndicator(double progress) {
    return Column(
      children: [
        Text(
          "PHRASE ${_currentIndex + 1} OF ${widget.phrases.length}",
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 100,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(color: AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            "PATTERN",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualSlot(String? imageUrl) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color:
              _isListening
                  ? AppTheme.primaryGreen
                  : (_isAnswered
                      ? (_isCorrect ? AppTheme.primaryGreen : Colors.red)
                      : Colors.white10),
          width: _isListening ? 4 : 2,
        ),
        boxShadow:
            _isListening
                ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ]
                : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child:
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.white24,
                      ),
                )
                : const Icon(Icons.psychology, size: 80, color: Colors.white12),
      ),
    );
  }

  Widget _buildModernInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isListening ? AppTheme.primaryGreen : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isAnswered,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: _isListening ? "Listening..." : "Type or Speak...",
                hintStyle: TextStyle(
                  color: _isListening ? AppTheme.primaryGreen : Colors.white24,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
          ),
          GestureDetector(
            onTap: _isAnswered ? null : _toggleListening,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    _isListening ? AppTheme.primaryGreen : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.black : Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackArea(PhraseWithProgress current) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _isAnswered ? 1.0 : 0.0,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                _isCorrect
                    ? [
                      AppTheme.primaryGreen.withValues(alpha: 0.15),
                      AppTheme.primaryGreen.withValues(alpha: 0.05),
                    ]
                    : [
                      Colors.redAccent.withValues(alpha: 0.15),
                      Colors.redAccent.withValues(alpha: 0.05),
                    ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                _isCorrect
                    ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                    : Colors.redAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _isCorrect
                      ? AppTheme.primaryGreen.withValues(alpha: 0.05)
                      : Colors.redAccent.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: _isCorrect ? AppTheme.primaryGreen : Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  _isCorrect ? "EXCELLENT!" : "ALMOST THERE!",
                  style: TextStyle(
                    color:
                        _isCorrect ? AppTheme.primaryGreen : Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),

            if (!_isCorrect) ...[
              const Text(
                "THE CORRECT PHRASE IS:",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
            ],

            Text(
              current.textEn,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () => AudioService.instance.speak(current.textEn),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "LISTEN AGAIN",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isAnswered
                    ? (_isCorrect ? AppTheme.primaryGreen : Colors.white)
                    : AppTheme.primaryGreen,
            fixedSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: _isAnswered ? _nextPhrase : _checkAnswer,
          child: Text(
            _isAnswered ? "NEXT" : "CHECK",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
