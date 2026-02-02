import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/services/sync_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final SyncService _syncService = SyncService();
  late Future<List<Map<String, dynamic>>> _patternsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Intentamos sincronizar en segundo plano al iniciar
    _syncService.syncData().then((_) => _loadData());
  }

  // ESTA ES LA CLAVE: Reasignar el Future fuerza a la UI a volver a leer la BD
  void _loadData() {
    if (mounted) {
      setState(() {
        _patternsFuture = DatabaseHelper.instance.getPatternsWithProgress();
      });
    }
  }

  Future<void> _syncData() async {
    // 1. Traer datos de la nube
    await _syncService.syncData();

    // 2. IMPORTANTE: Recalcular los totales para que no queden en 0
    await DatabaseHelper.instance.recalculateAllPatternCounts();

    // 3. Recargar la UI
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _syncData,
                    color: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.cardDark,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _patternsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "No patterns found.",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        final patterns = snapshot.data!;

                        // --- ALGORITMO DE EFECTO DOMINÓ ---
                        // Calculamos hasta qué índice está permitido jugar.
                        // Empezamos asumiendo que solo el primero (índice 0) está desbloqueado.
                        int unlockedLimit = 0;

                        for (int i = 0; i < patterns.length; i++) {
                          final p = patterns[i];
                          final int total = p['total_phrases'] ?? 0;
                          final int mastered = p['mastered_count'] ?? 0;

                          // Si este patrón está COMPLETO (y es válido), permitimos abrir el SIGUIENTE.
                          if (total > 0 && mastered >= total) {
                            unlockedLimit = i + 1;
                          } else {
                            // Si encontramos uno incompleto, ¡AQUÍ SE ROMPE LA CADENA!
                            // Ya no seguimos revisando, los siguientes se quedan bloqueados.
                            break;
                          }
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                          itemCount: patterns.length,
                          itemBuilder: (context, index) {
                            final pattern = patterns[index];

                            // Ahora el bloqueo es mucho más simple y estricto:
                            // Si tu índice es mayor al límite permitido -> ESTÁS BLOQUEADO.
                            final bool isLocked = index > unlockedLimit;

                            return _ModernPatternCard(
                              patternData: pattern,
                              index: index + 1,
                              isLocked: isLocked,
                              onReturn: _loadData,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Reproductor Flotante
            const Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: _MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Library",
                style: TextStyle(color: AppTheme.textGrey, letterSpacing: 1.0),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.sync,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  onPressed: _syncData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "My Patterns",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "English Chunking Method",
            style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _ModernPatternCard extends StatelessWidget {
  final Map<String, dynamic> patternData;
  final int index;
  final bool isLocked;
  final VoidCallback onReturn;

  const _ModernPatternCard({
    required this.patternData,
    required this.index,
    required this.isLocked,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final String title = patternData['title'];
    final String subtitle = patternData['subtitle'] ?? '';
    final int total = patternData['total_phrases'] ?? 0;
    final int mastered = patternData['mastered_count'] ?? 0;

    // Calculamos progreso
    final double progress =
        total > 0 ? (mastered / total).clamp(0.0, 1.0) : 0.0;
    final bool isCompleted = progress >= 1.0;

    // Está activo si NO está bloqueado y NO está completado al 100%
    // OJO: Si ya empezaste (progress > 0), también cuenta como activo para mostrar la barra
    final bool showProgressBar = !isLocked && (progress > 0 || isCompleted);

    return GestureDetector(
      onTap: () async {
        if (isLocked) {
          _showLockedAlert(context);
        } else {
          // --- AQUÍ ESTÁ LA MAGIA ---
          // Usamos await para esperar que vuelvas de la otra pantalla
          await context.push('/lesson/${patternData['id']}');
          // Al volver, ejecutamos la recarga inmediatamente
          print("Volviendo a Library... Recargando UI");
          onReturn();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isCompleted
                  ? const Color(0xFF1B5E20).withOpacity(0.15)
                  : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                (progress > 0 && !isLocked)
                    ? AppTheme.primaryGreen.withOpacity(0.5)
                    : Colors.white.withOpacity(0.05),
            width: (progress > 0 && !isLocked) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // 1. Indicador Circular
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isLocked
                            ? Colors.white.withOpacity(0.05)
                            : isCompleted
                            ? AppTheme.primaryGreen
                            : AppTheme.bgDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isLocked
                              ? Colors.transparent
                              : AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child:
                        isLocked
                            ? Icon(
                              Icons.lock_rounded,
                              color: Colors.white.withOpacity(0.3),
                              size: 20,
                            )
                            : isCompleted
                            ? const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 24,
                            )
                            : Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isLocked
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocked ? "Complete previous level" : subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isLocked
                                  ? Colors.white.withOpacity(0.2)
                                  : AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Icono de acción
                if (!isLocked && !isCompleted)
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withOpacity(0.2),
                    size: 20,
                  ),
              ],
            ),

            // 4. BARRA DE PROGRESO (Ahora se muestra si showProgressBar es true)
            if (showProgressBar) ...[
              const SizedBox(height: 20),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCompleted
                            ? "Completed!"
                            : "${(progress * 100).toInt()}% Mastered",
                        style: TextStyle(
                          color:
                              isCompleted
                                  ? AppTheme.primaryGreen
                                  : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$mastered/$total Phrases",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutExpo,
                            height: 8,
                            width:
                                constraints.maxWidth *
                                progress, // Ancho dinámico
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen,
                                  Color(0xFF69F0AE),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLockedAlert(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Level Locked",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Master all phrases (P1 & P2) in the previous level.💖​",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 19, 150, 197),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }
}

// Player Flotante (Sin cambios, ya estaba perfecto)
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Ready to practice?",
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Select a pattern to start",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
