import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';

class LessonScreen extends StatefulWidget {
  final String patternId;

  const LessonScreen({super.key, required this.patternId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Map<String, dynamic>? _patternData;
  List<Map<String, dynamic>> _phrases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    final db = DatabaseHelper.instance;
    final pattern = await db.getPatternById(widget.patternId);
    final phrases = await db.getPhrasesByPatternId(widget.patternId);

    if (mounted) {
      setState(() {
        _patternData = pattern;
        _phrases = phrases;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleProgress(int index, String field) async {
    final phrase = _phrases[index];
    final int phraseId = phrase['id'];

    final bool currentValue = (phrase[field] == 1);
    final bool newValue = !currentValue;

    await DatabaseHelper.instance.updateProgress(phraseId, field, newValue);

    // Si el usuario MARCÓ (newValue == true), contamos como actividad
    if (newValue) {
      // Sumamos 1 frase a la estadística del día
      await DatabaseHelper.instance.addPhraseCount(1);
    }

    setState(() {
      _phrases[index][field] = newValue ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Practice Mode",
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _patternData?['title'] ?? "Loading...",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
              : Column(
                children: [
                  // 1. Tarjeta de Regla
                  if (_patternData != null)
                    _GrammarCard(
                      rule:
                          _patternData!['grammar_rule'] ?? "No rule available",
                      subtitle: _patternData!['subtitle'] ?? "",
                    ),

                  // 2. Lista de Frases
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: _phrases.length,
                      itemBuilder: (context, index) {
                        final phrase = _phrases[index];
                        return _PhrasePracticeCard(
                          phrase: phrase,
                          onToggleP1: () => _toggleProgress(index, 'p1'),
                          onToggleP2: () => _toggleProgress(index, 'p2'),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _GrammarCard extends StatelessWidget {
  final String rule;
  final String subtitle;

  const _GrammarCard({required this.rule, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rule,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhrasePracticeCard extends StatelessWidget {
  final Map<String, dynamic> phrase;
  final VoidCallback onToggleP1;
  final VoidCallback onToggleP2;

  const _PhrasePracticeCard({
    required this.phrase,
    required this.onToggleP1,
    required this.onToggleP2,
  });

  @override
  Widget build(BuildContext context) {
    final bool p1Active = (phrase['p1'] == 1);
    final bool p2Active = (phrase['p2'] == 1);
    final bool isMastered = p1Active && p2Active;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isMastered
                ? AppTheme.primaryGreen.withOpacity(0.05)
                : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isMastered
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto (Inglés y Tap to Reveal Español)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Frase en Inglés (Chunk)
                Text(
                  phrase['text_en'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Tap to Reveal (Español)
                _TapToReveal(
                  hiddenText: phrase['text_es'],
                  isMastered: isMastered,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Botones P1 y P2 (Alineados arriba)
          Column(
            children: [
              _CircularCheckButton(
                label: "P1",
                isActive: p1Active,
                onTap: onToggleP1,
              ),
              const SizedBox(height: 12),
              _CircularCheckButton(
                label: "P2",
                isActive: p2Active,
                onTap: onToggleP2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGET TAP TO REVEAL (Aquí está la magia) ---
class _TapToReveal extends StatefulWidget {
  final String hiddenText;
  final bool isMastered;

  const _TapToReveal({required this.hiddenText, required this.isMastered});

  @override
  State<_TapToReveal> createState() => _TapToRevealState();
}

class _TapToRevealState extends State<_TapToReveal> {
  bool _isRevealed = false;

  @override
  void didUpdateWidget(covariant _TapToReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia la frase (reciclaje de lista), ocultar de nuevo
    if (widget.hiddenText != oldWidget.hiddenText) {
      _isRevealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si ya dominaste la frase (Mastered), mostramos el texto siempre
    if (widget.isMastered) {
      return Text(
        widget.hiddenText,
        style: TextStyle(
          color: AppTheme.primaryGreen.withOpacity(0.8),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isRevealed = !_isRevealed; // Toggle al tocar
        });
      },
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        firstChild: _buildHiddenState(),
        secondChild: _buildRevealedState(),
        crossFadeState:
            _isRevealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      ),
    );
  }

  Widget _buildHiddenState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            "Tap to reveal",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        widget.hiddenText,
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
      ),
    );
  }
}

class _CircularCheckButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CircularCheckButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isActive
                    ? AppTheme.primaryGreen
                    : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                  : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
