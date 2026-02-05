import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';
import '../../../core/utils/snackbar_utils.dart';
// Asegúrate de que esta sea la ruta correcta a tu nueva pantalla de juego
import 'slot_machine_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  List<Map<String, dynamic>> _randomPhrases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRandomMix();
  }

  // Carga el mix de frases (Legacy P1/P2)
  Future<void> _loadRandomMix() async {
    setState(() => _isLoading = true);
    final phrases = await DatabaseHelper.instance.getSmartMixPhrases(20);
    if (mounted) {
      setState(() {
        _randomPhrases = phrases;
        _isLoading = false;
      });
    }
  }

  // --- LÓGICA PARA INICIAR EL JUEGO (SLOT MACHINE) ---
  Future<void> _startSlotMachine() async {
    // 1. Obtener frases que tocan hoy por SRS
    final duePhrases = await DatabaseHelper.instance.getDuePhrasesForSRS(10);

    if (duePhrases.isEmpty) {
      if (mounted) {
        SnackbarUtils.show(
          context,
          "You're all caught up! No phrases due for review today. 🔥",
          isError: false,
        );
      }
      return;
    }

    // 2. Navegar a la pantalla de la Tragamonedas
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SlotMachineScreen(phrases: duePhrases),
        ),
      ).then((_) => _loadRandomMix()); // Recargar al volver por si hubo cambios
    }
  }

  // Marcar progreso individual (P1/P2)
  Future<void> _toggleProgress(int index, String field) async {
    final phrase = _randomPhrases[index];
    final int phraseId = phrase['id'];
    final bool currentValue = (phrase[field] == 1);
    final bool newValue = !currentValue;

    await DatabaseHelper.instance.updateProgress(phraseId, field, newValue);

    setState(() {
      _randomPhrases[index][field] = newValue ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      )
                      : _randomPhrases.isEmpty && _isLoading == false
                      ? _buildEmptyState()
                      : RefreshIndicator(
                        onRefresh: _loadRandomMix,
                        color: AppTheme.primaryGreen,
                        backgroundColor: AppTheme.cardDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          // +1 para incluir la tarjeta de Slot Machine arriba
                          itemCount: _randomPhrases.length + 1,
                          itemBuilder: (context, index) {
                            // ÍNDICE 0: La tarjeta especial del modo juego
                            if (index == 0) {
                              return _buildSlotMachineHeroCard();
                            }

                            // RESTO: Las tarjetas de la lista (ajustamos index - 1)
                            final phraseIndex = index - 1;
                            return _MixedPhraseCard(
                              phrase: _randomPhrases[phraseIndex],
                              onToggleP1:
                                  () => _toggleProgress(phraseIndex, 'p1'),
                              onToggleP2:
                                  () => _toggleProgress(phraseIndex, 'p2'),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 92.0),
        child: FloatingActionButton.extended(
          onPressed: _loadRandomMix,
          backgroundColor: const Color.fromARGB(255, 213, 24, 147),
          icon: const Icon(Icons.shuffle, color: Colors.white),
          label: const Text(
            "Remix List",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: TARJETA HERO PARA EL JUEGO ---
  Widget _buildSlotMachineHeroCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)], // Gradiente Neón
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startSlotMachine,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.casino_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "THE SLOT MACHINE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "Master Chunks with Visual Anchors",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Mix",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "Your Spaced Repetition Practice",
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.yellow),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "No phrases to review.\nKeep learning in the Library!",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}

// --- WIDGETS DE SOPORTE (TARJETAS Y BOTONES) ---

class _MixedPhraseCard extends StatelessWidget {
  final Map<String, dynamic> phrase;
  final VoidCallback onToggleP1;
  final VoidCallback onToggleP2;

  const _MixedPhraseCard({
    required this.phrase,
    required this.onToggleP1,
    required this.onToggleP2,
  });

  @override
  Widget build(BuildContext context) {
    final bool p1Active = (phrase['p1'] == 1);
    final bool p2Active = (phrase['p2'] == 1);
    final bool isMastered = p1Active && p2Active;
    final String patternTitle = phrase['pattern_title'] ?? "Unknown Pattern";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isMastered
                ? AppTheme.primaryGreen.withValues(alpha: 0.05)
                : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isMastered
                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                  : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(96, 0, 0, 0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              patternTitle.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phrase['text_en'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TapToReveal(
                      hiddenText: phrase['text_es'],
                      isMastered: isMastered,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    if (widget.isMastered) {
      return Text(
        widget.hiddenText,
        style: TextStyle(
          color: AppTheme.primaryGreen.withValues(alpha: 0.8),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _isRevealed = !_isRevealed),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        firstChild: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                "Tap to reveal",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        secondChild: Text(
          widget.hiddenText,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
        crossFadeState:
            _isRevealed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
                    : Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
