import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';
import '../../../core/services/audio_service.dart'; // Importa tu nuevo servicio

class SlotMachineScreen extends StatefulWidget {
  final List<Map<String, dynamic>> phrases;

  const SlotMachineScreen({super.key, required this.phrases});

  @override
  State<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends State<SlotMachineScreen> {
  int _currentIndex = 0;
  final _controller = TextEditingController();
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isListening = false; // Estado del micrófono

  @override
  void dispose() {
    _controller.dispose();
    AudioService.instance.stopTts(); // Detener audio al salir
    super.dispose();
  }

  // --- LÓGICA DE AUDIO (STT) ---
  void _toggleListening() async {
    if (_isListening) {
      await AudioService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      // Limpiamos el campo para nueva entrada de voz
      _controller.clear();

      await AudioService.instance.startListening(
        onResult: (text) {
          setState(() {
            _controller.text = text;
            // Si el texto es lo suficientemente largo, asumimos que terminó
            // OJO: SpeechToText a veces envía parciales, actualizamos el UI en tiempo real
          });
        },
      );

      // Escuchamos cambios de estado del servicio para apagar el icono cuando termine solo
      // (Esta es una implementación simple, en prod podrías usar un Listener más complejo)
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !AudioService.instance.isListening) {
          setState(() => _isListening = false);
        }
      });
    }
  }

  // --- LÓGICA DE APRENDIZAJE ---

  String _getVariablePart(String fullPhrase, String pattern) {
    if (fullPhrase.toLowerCase().contains(pattern.toLowerCase())) {
      return fullPhrase
          .toLowerCase()
          .replaceAll(pattern.toLowerCase(), "")
          .trim();
    }
    return fullPhrase.toLowerCase().trim();
  }

  void _checkAnswer() {
    if (_controller.text.trim().isEmpty) return;

    // Detenemos el micro si estaba activo
    if (_isListening) {
      AudioService.instance.stopListening();
      setState(() => _isListening = false);
    }

    final current = widget.phrases[_currentIndex];
    final String pattern = current['pattern_title'].toString();
    final String fullPhrase = current['text_en'].toString();

    // Normalizamos para comparar mejor (quitamos puntos finales, etc)
    final expectedPart = _getVariablePart(
      fullPhrase,
      pattern,
    ).replaceAll('.', '');
    final userAnswer = _controller.text.trim().toLowerCase().replaceAll(
      '.',
      '',
    );
    final fullPhraseClean = fullPhrase.toLowerCase().replaceAll('.', '');

    setState(() {
      _isCorrect =
          (userAnswer == expectedPart) || (userAnswer == fullPhraseClean);
      _isAnswered = true;
    });

    // --- REFUERZO AUDITIVO (TTS) ---
    if (_isCorrect) {
      // Si acierta, la app lee la frase completa para reforzar
      AudioService.instance.speak(current['text_en']);
    }

    _processSRSUpdate(current);
  }

  Future<void> _processSRSUpdate(Map<String, dynamic> current) async {
    final int currentLevel = current['srs_level'] ?? 0;
    int newLevel = _isCorrect ? (currentLevel + 1).clamp(0, 3) : 0;

    int daysToAdd = 0;
    if (_isCorrect) {
      if (newLevel == 1) daysToAdd = 1;
      if (newLevel == 2) daysToAdd = 4;
      if (newLevel == 3) daysToAdd = 14;
    }

    final nextReview =
        DateTime.now().add(Duration(days: daysToAdd)).millisecondsSinceEpoch;

    final db = await DatabaseHelper.instance.database;
    await db.update(
      'user_progress',
      {
        'srs_level': newLevel,
        'next_review_date': nextReview,
        'last_reviewed_date': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'phrase_id = ?',
      whereArgs: [current['id']],
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

  @override
  Widget build(BuildContext context) {
    final current = widget.phrases[_currentIndex];
    final progress = (_currentIndex + 1) / widget.phrases.length;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true, // Importante para el teclado
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
                  _buildPatternHeader(current['pattern_title']),
                  const SizedBox(height: 30),
                  _buildVisualSlot(current['image_url']),
                  const SizedBox(height: 40),

                  // INPUT CON MICRÓFONO INTEGRADO
                  _buildModernInput(),

                  if (_isAnswered) _buildFeedbackArea(current),
                  const SizedBox(height: 100), // Espacio extra para scroll
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  // --- WIDGETS ---

  Widget _buildStepIndicator(double progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "PHRASE ${_currentIndex + 1} OF ${widget.phrases.length}",
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 120 * progress,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, Color(0xFF00E676)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternHeader(String title) {
    return Column(
      children: [
        const Text(
          "STRUCTURE",
          style: TextStyle(
            color: Colors.white24,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualSlot(String? imageUrl) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _isAnswered
                    ? (_isCorrect
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1))
                    : (_isListening
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : Colors.white.withValues(
                          alpha: 0.02,
                        )), // Glow al escuchar
            boxShadow: [
              if (_isAnswered || _isListening)
                BoxShadow(
                  color:
                      _isCorrect || _isListening
                          ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                  blurRadius: 60,
                ),
            ],
          ),
        ),
        Container(
          width: 280,
          height: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color:
                  _isAnswered
                      ? (_isCorrect
                          ? AppTheme.primaryGreen
                          : Colors.red.withValues(alpha: 0.5))
                      : (_isListening
                          ? AppTheme.primaryGreen
                          : Colors.white.withValues(alpha: 0.05)),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child:
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stack) => const Icon(
                            Icons.broken_image,
                            color: Colors.white12,
                            size: 50,
                          ),
                    )
                    : const Center(
                      child: Icon(
                        Icons.psychology_outlined,
                        size: 60,
                        color: Colors.white12,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  // --- INPUT HÍBRIDO (TECLADO + VOZ) ---
  Widget _buildModernInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color:
              _isListening
                  ? AppTheme
                      .primaryGreen // Borde verde si está escuchando
                  : (_isAnswered ? Colors.transparent : Colors.white10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: false, // Quitamos autofocus para no tapar el micro
              enabled: !_isAnswered,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: _isListening ? "Listening..." : "Type or speak...",
                hintStyle: TextStyle(
                  color: _isListening ? AppTheme.primaryGreen : Colors.white12,
                  fontSize: 18,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _isAnswered ? null : _checkAnswer(),
            ),
          ),

          // BOTÓN DE MICRÓFONO
          GestureDetector(
            onTap: _isAnswered ? null : _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _isListening
                        ? AppTheme.primaryGreen
                        : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackArea(Map<String, dynamic> current) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            _isCorrect
                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                : Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              _isCorrect
                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                  : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? AppTheme.primaryGreen : Colors.redAccent,
              ),
              const SizedBox(width: 10),
              Text(
                _isCorrect ? "EXCELLENT!" : "KEEP TRYING!",
                style: TextStyle(
                  color: _isCorrect ? AppTheme.primaryGreen : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          // BOTÓN PARA REPETIR AUDIO (SI FALLÓ O QUIERE ESCUCHAR DE NUEVO)
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white70),
            onPressed: () => AudioService.instance.speak(current['text_en']),
          ),

          if (!_isCorrect) ...[
            const SizedBox(height: 10),
            const Text(
              "THE CORRECT PHRASE IS:",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              current['text_en'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          height: 65,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isAnswered
                      ? (_isCorrect ? AppTheme.primaryGreen : Colors.white)
                      : AppTheme.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 10,
              shadowColor:
                  (_isAnswered && _isCorrect)
                      ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                      : Colors.black,
            ),
            onPressed: _isAnswered ? _nextPhrase : _checkAnswer,
            child: Text(
              _isAnswered
                  ? (_currentIndex == widget.phrases.length - 1
                      ? "FINISH SESSION"
                      : "NEXT PHRASE")
                  : "CHECK ANSWER",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
