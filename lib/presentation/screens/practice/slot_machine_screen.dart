import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';

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

  // --- LÓGICA DE APRENDIZAJE (EL MOTOR) ---

  // Extrae la parte que el usuario DEBE escribir (ej: de "I need to buy an apple" saca "an apple")
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

    final current = widget.phrases[_currentIndex];
    final String pattern = current['pattern_title'].toString();
    final String fullPhrase = current['text_en'].toString();

    final expectedPart = _getVariablePart(fullPhrase, pattern);
    final userAnswer = _controller.text.trim().toLowerCase();

    setState(() {
      // Es correcto si escribe la parte que falta o la frase completa
      _isCorrect =
          (userAnswer == expectedPart) ||
          (userAnswer == fullPhrase.toLowerCase());
      _isAnswered = true;
    });

    _processSRSUpdate(current);
  }

  Future<void> _processSRSUpdate(Map<String, dynamic> current) async {
    final int currentLevel = current['srs_level'] ?? 0;

    // Regla de Fallo: Si falla vuelve a 0. Si acierta, sube nivel (max 3).
    int newLevel = _isCorrect ? (currentLevel + 1).clamp(0, 3) : 0;

    // Intervalos SRS: N0=Hoy, N1=1 día, N2=4 días, N3=14 días
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
          // Fondo con gradiente radial neón
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.08),
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

                  // 1. EL CHUNK FIJO (MOLDE)
                  _buildPatternHeader(current['pattern_title']),

                  const SizedBox(height: 30),

                  // 2. EL SLOT MACHINE (VISUAL ANCHOR)
                  _buildVisualSlot(current['image_url']),

                  const SizedBox(height: 40),

                  // 3. INPUT MODERNO
                  _buildModernInput(),

                  // 4. FEEDBACK "BONITO" (Mensaje de éxito/error solicitado)
                  if (_isAnswered) _buildFeedbackArea(current),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  // --- COMPONENTES DE UI ---

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
                  color: AppTheme.primaryGreen.withOpacity(0.5),
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
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
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
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _isAnswered
                    ? (_isCorrect
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1))
                    : Colors.white.withOpacity(0.02),
            boxShadow: [
              if (_isAnswered)
                BoxShadow(
                  color:
                      _isCorrect
                          ? AppTheme.primaryGreen.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                  blurRadius: 60,
                ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
                          : Colors.red.withOpacity(0.5))
                      : Colors.white.withOpacity(0.05),
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
                    : Container(
                      color: Colors.black26,
                      child: const Icon(
                        Icons.image_search_rounded,
                        size: 60,
                        color: Colors.white12,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isAnswered ? Colors.transparent : Colors.white10,
        ),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_isAnswered,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          hintText: "Complete the sentence...",
          hintStyle: TextStyle(color: Colors.white12, fontSize: 20),
          border: InputBorder.none,
        ),
        onSubmitted: (_) => _isAnswered ? null : _checkAnswer(),
      ),
    );
  }

  // --- AREA DE FEEDBACK (LA CAJA BONITA) ---
  Widget _buildFeedbackArea(Map<String, dynamic> current) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            _isCorrect
                ? AppTheme.primaryGreen.withOpacity(0.1)
                : Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              _isCorrect
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : Colors.redAccent.withOpacity(0.3),
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
              const SizedBox(width: 8),
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
          if (!_isCorrect) ...[
            const SizedBox(height: 5),
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
                      ? (_isCorrect
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : Colors.white)
                      : const Color.fromARGB(255, 253, 254, 254),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 10,
              shadowColor:
                  (_isAnswered && _isCorrect)
                      ? const Color.fromARGB(
                        255,
                        255,
                        255,
                        255,
                      ).withOpacity(0.5)
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
