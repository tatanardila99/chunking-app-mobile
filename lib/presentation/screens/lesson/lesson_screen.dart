import 'dart:ui';
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
  List<Map<String, dynamic>> _phrases = [];
  bool _isLoading = true;

  // Variables para guardar la info real del patrón
  String _patternTitle = "Loading...";
  String _grammarRule = "Loading rule...";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;

    // 1. Cargar INFO DEL PATRÓN (Título y Regla)
    final patternData = await db.getPatternById(widget.patternId);

    // 2. Cargar FRASES
    final phrases = await db.getPhrasesByPatternId(widget.patternId);

    if (mounted) {
      setState(() {
        if (patternData != null) {
          _patternTitle = patternData['title']; // "I'm allowed to..."
          _grammarRule = patternData['grammar_rule']; // "Used to express..."
        }
        _phrases = phrases;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleProgress(
    int index,
    String field,
    bool currentValue,
  ) async {
    setState(() {
      _phrases[index][field] = currentValue ? 0 : 1;
    });

    int phraseId = _phrases[index]['id'];
    bool newValue = _phrases[index][field] == 1;
    await DatabaseHelper.instance.updateProgress(phraseId, field, newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Importante para el diseño full screen
      backgroundColor: AppTheme.bgDark, // Fondo base por si falla el gradiente
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [AppTheme.bgDark.withOpacity(0.8), AppTheme.bgDark],
            center: Alignment.topCenter,
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          bottom: false, // Dejamos que el contenido baje hasta el fondo
          child: Stack(
            children: [
              // CAPA 1: Contenido (Header + Regla + Lista)
              Column(
                children: [
                  _buildHeader(context),

                  // Regla Gramatical Dinámica
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGrammarRule(),
                  ),

                  const SizedBox(height: 20),

                  // Lista de Frases
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen,
                              ),
                            )
                            : _phrases.isEmpty
                            ? const Center(
                              child: Text(
                                "No phrases found",
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                            : ListView.builder(
                              // PADDING INFERIOR GIGANTE PARA QUE EL REPRODUCTOR NO TAPE EL FINAL
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                150,
                              ),
                              itemCount: _phrases.length,
                              itemBuilder: (context, index) {
                                return _PhraseRow(
                                  phraseData: _phrases[index],
                                  onToggle:
                                      (field, value) =>
                                          _toggleProgress(index, field, value),
                                );
                              },
                            ),
                  ),
                ],
              ),

              // CAPA 2: Reproductor Flotante (Debe ser el ÚLTIMO hijo del Stack)
              Positioned(
                bottom: 30, // Separado del fondo
                left: 20,
                right: 20,
                child: _buildGlassPlayer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            // Expanded para evitar overflow si el título es largo
            child: Column(
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
                  _patternTitle, // AQUI USAMOS EL TITULO REAL
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarRule() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _grammarRule, // AQUI USAMOS LA REGLA REAL
              style: const TextStyle(
                color: AppTheme.textGrey,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPlayer() {
    // Usamos ClipRRect y BackdropFilter para asegurar el efecto visual
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(
              0xFF1E1E1E,
            ).withOpacity(0.85), // Fondo oscuro semitransparente
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Auto-Play",
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Listen & Repeat",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseRow extends StatefulWidget {
  final Map<String, dynamic> phraseData;
  final Function(String field, bool currentValue) onToggle;

  const _PhraseRow({required this.phraseData, required this.onToggle});

  @override
  State<_PhraseRow> createState() => _PhraseRowState();
}

class _PhraseRowState extends State<_PhraseRow> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    bool p1 = widget.phraseData['p1'] == 1;
    bool p2 = widget.phraseData['p2'] == 1;
    bool isMastered = p1 && p2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isMastered
                ? const Color(0xFF1B5E20).withOpacity(0.2)
                : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isMastered
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.phraseData['text_en'],
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color:
                        isMastered
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                  ),
                ),
              ),
              Row(
                children: [
                  _CustomCheckbox(
                    label: "P1",
                    value: p1,
                    onChanged: () => widget.onToggle('p1', p1),
                  ),
                  const SizedBox(width: 8),
                  _CustomCheckbox(
                    label: "P2",
                    value: p2,
                    onChanged: () => widget.onToggle('p2', p2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _isRevealed = !_isRevealed),
            child: AnimatedCrossFade(
              firstChild: _buildBlurredText(),
              secondChild: Text(
                widget.phraseData['text_es'],
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              crossFadeState:
                  _isRevealed
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredText() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: Colors.white.withOpacity(0.1),
          child: Text(
            widget.phraseData['text_es'],
            style: const TextStyle(color: Colors.transparent, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onChanged;

  const _CustomCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: value ? AppTheme.primaryGreen : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                value
                    ? AppTheme.primaryGreen
                    : AppTheme.textGrey.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: value ? Colors.black : AppTheme.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}
