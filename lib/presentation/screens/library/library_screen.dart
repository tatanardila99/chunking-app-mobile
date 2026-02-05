import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
    _syncService.syncData().then((_) => _loadData());
  }

  void _loadData() {
    if (mounted) {
      setState(() {
        _patternsFuture = DatabaseHelper.instance.getPatternsWithProgress();
      });
    }
  }

  Future<void> _syncData() async {
    await _syncService.syncData();
    await DatabaseHelper.instance.recalculateAllPatternCounts();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Fondo oscuro profundo extraído de la imagen
    const Color kBackground = Color(0xFF12151C);
    const Color kAccentCyan = Color(0xFF21E5A0);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Contenido Principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header Personalizado
                  _buildHeader(kAccentCyan),
                  const SizedBox(height: 30),

                  // Título de sección (como "Active Habits")
                  const Text(
                    "Your Path",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid de Niveles
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _syncData,
                      color: kAccentCyan,
                      backgroundColor: const Color(0xFF1F232F),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _patternsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: kAccentCyan,
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text(
                                "No patterns found",
                                style: TextStyle(color: Colors.white54),
                              ),
                            );
                          }

                          final patterns = snapshot.data!;

                          // Lógica de desbloqueo (Misma lógica tuya)
                          int unlockedLimit = 0;
                          for (int i = 0; i < patterns.length; i++) {
                            final p = patterns[i];
                            final int total = p['total_phrases'] ?? 0;
                            final int mastered = p['mastered_count'] ?? 0;
                            if (total > 0 && mastered >= total) {
                              unlockedLimit = i + 1;
                            } else {
                              break;
                            }
                          }

                          // Usamos GridView para imitar las tarjetas cuadradas ("Hydration", "Deep Work")
                          return GridView.builder(
                            padding: const EdgeInsets.only(bottom: 150),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // 2 Columnas
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      0.85, // Tarjetas un poco más altas que anchas
                                ),
                            itemCount: patterns.length,
                            itemBuilder: (context, index) {
                              final pattern = patterns[index];
                              final bool isLocked = index > unlockedLimit;

                              return _DashboardCard(
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
            ),

            // Reproductor Flotante
            //const Positioned(
            //  bottom: 110,
            //  left: 20,
            //  right: 20,
            //  child: _MiniPlayer(),
            //),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Avatar simulado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      // Placeholder para avatar si tienes uno
                      image: AssetImage('assets/images/logo.png'),
                      opacity: 0.8,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white70,
                  ), // Fallback
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WELCOME BACK",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.1),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Text(
                      "Tatan Ardila",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        // Texto gigante "Build your 1% today"
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins', // Asegúrate de tener una fuente bold
              color: Colors.white,
              height: 1.2,
            ),
            children: [
              const TextSpan(text: "Build your "),
              TextSpan(text: "1%", style: TextStyle(color: accentColor)),
              const TextSpan(text: " today"),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Map<String, dynamic> patternData;
  final int index;
  final bool isLocked;
  final VoidCallback onReturn;

  const _DashboardCard({
    super.key,
    required this.patternData,
    required this.index,
    required this.isLocked,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    // --- COLORES Y ESTADO ---
    const Color kAccentCyan = Color(0xFF21E5A0);
    // Un gris azulado oscuro pero con un toque más rico para el gradiente
    const Color kCardDarkStart = Color(0xFF252A35);
    const Color kCardDarkEnd = Color(0xFF1F232F);

    final String title = patternData['title'];
    final int total = patternData['total_phrases'] ?? 0;
    final int mastered = patternData['mastered_count'] ?? 0;
    final double progress =
        total > 0 ? (mastered / total).clamp(0.0, 1.0) : 0.0;
    final bool isCompleted = progress >= 1.0;

    // Determina si la tarjeta está activa (ni bloqueada ni terminada al 100%)
    final bool isActive = !isLocked && !isCompleted && progress > 0;

    // Color principal de esta tarjeta según su estado
    final Color stateColor =
        isLocked
            ? Colors.white.withValues(alpha: 0.2) // Apagado
            : isCompleted
            ? kAccentCyan // Brillante si terminó
            : kAccentCyan.withValues(
              alpha: 0.8,
            ); // Un poco menos si está en progreso

    return GestureDetector(
      onTap: () async {
        if (isLocked) {
          // Haptic feedback suave al tocar algo bloqueado
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(
                    Icons.lock_outline,
                    color: Color.fromARGB(255, 58, 181, 197),
                  ),
                  SizedBox(width: 10),
                  Text("Complete previous levels to unlock! 🚀"),
                ],
              ),
              backgroundColor: Color.fromARGB(255, 71, 243, 183),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        } else {
          await context.push('/lesson/${patternData['id']}');
          onReturn();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          // 1. GRADIENTE DE FONDO (Sutil profundidad)
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isLocked
                    ? [
                      const Color(0xFF1A1D24),
                      const Color(0xFF14171C),
                    ] // Más plano si está bloqueado
                    : [
                      kCardDarkStart,
                      kCardDarkEnd,
                    ], // Rico si está desbloqueado
          ),
          borderRadius: BorderRadius.circular(26), // Bordes muy suaves
          // 2. BORDE NEÓN (Solo si no está bloqueado)
          border: Border.all(
            color:
                isLocked
                    ? Colors.white.withValues(alpha: 0.05)
                    : stateColor.withValues(alpha: isCompleted ? 0.5 : 0.3),
            width: isLocked ? 1 : 1.5,
          ),

          // 3. SOMBRA RESPLANDOR (El toque "espectacular")
          boxShadow: [
            if (!isLocked)
              BoxShadow(
                color: stateColor.withValues(
                  alpha: isCompleted ? 0.2 : 0.12,
                ), // Color del neón
                blurRadius: 25, // Muy difuminado
                spreadRadius: -5, // Para que no se expanda mucho, solo un halo
                offset: const Offset(0, 8),
              ),
            // Sombra de profundidad estándar
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- CABECERA: ICONO Y ESTADO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono "envasado" con efecto cristal
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          isLocked
                              ? Colors.white.withValues(alpha: 0.03)
                              : stateColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isLocked
                                ? Colors.transparent
                                : stateColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      isLocked
                          ? Icons.lock_rounded
                          : isCompleted
                          ? Icons.check_circle_outline_rounded
                          : Icons.grid_view_rounded,
                      color: isLocked ? Colors.white24 : stateColor,
                      size: 22,
                    ),
                  ),

                  // Indicador de índice o "DONE"
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kAccentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kAccentCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        "MASTERED",
                        style: TextStyle(
                          color: kAccentCyan,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.15),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // --- TÍTULO PRINCIPAL ---
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      isLocked
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 8),

              // --- BARRA DE PROGRESO Y SUBTÍTULO ---
              if (isLocked)
                Text(
                  "Locked Level",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else ...[
                // Barra de progreso moderna
                Stack(
                  children: [
                    // Fondo de la barra
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // Progreso animado
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutQuint,
                          height: 6,
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                stateColor.withValues(alpha: 0.7),
                                stateColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              // Pequeño resplandor en la barra misma
                              BoxShadow(
                                color: stateColor.withValues(alpha: 0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Texto de progreso
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$mastered / $total phrases",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(
                        color: isCompleted ? kAccentCyan : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Player Flotante
//class _MiniPlayer extends StatelessWidget {
//  const _MiniPlayer();
//  @override
//  Widget build(BuildContext context) {
//    return ClipRRect(
//      borderRadius: BorderRadius.circular(20),
//      child: BackdropFilter(
//        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//        child: Container(
//          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//          decoration: BoxDecoration(
//            color: const Color(0xFF1E1E1E).withValues(0.95),
//            borderRadius: BorderRadius.circular(20),
//            border: Border.all(color: Colors.white.withValues(0.1)),
//          ),
//          child: Row(
//            children: [
//              Container(
//                padding: const EdgeInsets.all(8),
//                decoration: const BoxDecoration(
//                  color: Color(0xFF00E5FF),
//                  shape: BoxShape.circle,
//                ),
//                child: const Icon(
//                  Icons.play_arrow_rounded,
//                  color: Colors.black,
//                  size: 20,
//                ),
//              ),
//              const SizedBox(width: 14),
//              const Expanded(
//                child: Column(
//                  crossAxisAlignment: CrossAxisAlignment.start,
//                  children: [
//                    Text(
//                      "Quick Practice",
//                      style: TextStyle(
//                        color: Colors.white,
//                        fontWeight: FontWeight.bold,
//                        fontSize: 14,
//                      ),
//                    ),
//                    Text(
//                      "Shuffle all unlocked patterns",
//                      style: TextStyle(color: Colors.white54, fontSize: 11),
//                    ),
//                  ],
//                ),
//              ),
//            ],
//          ),
//        ),
//      ),
//    );
//  }
//}
