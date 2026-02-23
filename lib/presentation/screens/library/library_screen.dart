import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/pattern.dart';
import '../../../data/services/sync_service.dart';
import '../../providers/pattern_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/dependency_injection.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _syncData(WidgetRef ref) async {
    final syncService = SyncService();
    await syncService.syncData();
    
    // Recalcular contadores
    final patternRepo = ref.read(patternRepositoryProvider);
    await patternRepo.recalculatePatternCounts();
    
    // Invalidar providers para refrescar
    ref.invalidate(patternsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(patternsProvider);
    final userNameAsync = ref.watch(userNameProvider);

    const Color kBackground = Color(0xFF12151C);
    const Color kAccentCyan = Color(0xFF21E5A0);

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header Personalizado
              _buildHeader(kAccentCyan, userNameAsync),
              const SizedBox(height: 30),

              // Título de sección
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
                child: patternsAsync.when(
                  data: (patterns) {
                    if (patterns.isEmpty) {
                      return const Center(
                        child: Text(
                          "No patterns found",
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    // Lógica de desbloqueo
                    int unlockedLimit = 0;
                    for (int i = 0; i < patterns.length; i++) {
                      final p = patterns[i];
                      if (p.isCompleted) {
                        unlockedLimit = i + 1;
                      } else {
                        break;
                      }
                    }

                    return RefreshIndicator(
                      onRefresh: () => _syncData(ref),
                      color: kAccentCyan,
                      backgroundColor: const Color(0xFF1F232F),
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 150),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: patterns.length,
                        itemBuilder: (context, index) {
                          final pattern = patterns[index];
                          final bool isLocked = index > unlockedLimit;

                          return _DashboardCard(
                            pattern: pattern,
                            index: index + 1,
                            isLocked: isLocked,
                            onReturn: () => ref.invalidate(patternsProvider),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(color: kAccentCyan),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor, AsyncValue<String> userNameAsync) {
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
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WELCOME BACK",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 8, 167, 98),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    userNameAsync.when(
                      data: (userName) => Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const Text(
                        "Loading...",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (_, __) => const Text(
                        "User",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
              fontFamily: 'Poppins',
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
  final Pattern pattern;
  final int index;
  final bool isLocked;
  final VoidCallback onReturn;

  const _DashboardCard({
    required this.pattern,
    required this.index,
    required this.isLocked,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    const Color kAccentCyan = Color(0xFF21E5A0);
    const Color kCardDarkStart = Color(0xFF252A35);
    const Color kCardDarkEnd = Color(0xFF1F232F);

    final double progress = pattern.progress;
    final bool isCompleted = pattern.isCompleted;

    final Color stateColor =
        isLocked
            ? Colors.white.withValues(alpha: 0.2)
            : isCompleted
            ? kAccentCyan
            : kAccentCyan.withValues(alpha: 0.8);

    return GestureDetector(
      onTap: () async {
        if (isLocked) {
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
          await context.push('/lesson/${pattern.id}');
          onReturn();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isLocked
                    ? [
                      const Color(0xFF1A1D24),
                      const Color(0xFF14171C),
                    ]
                    : [
                      kCardDarkStart,
                      kCardDarkEnd,
                    ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color:
                isLocked
                    ? Colors.white.withValues(alpha: 0.05)
                    : stateColor.withValues(alpha: isCompleted ? 0.5 : 0.3),
            width: isLocked ? 1 : 1.5,
          ),
          boxShadow: [
            if (!isLocked)
              BoxShadow(
                color: stateColor.withValues(
                  alpha: isCompleted ? 0.2 : 0.12,
                ),
                blurRadius: 25,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

              Text(
                pattern.title,
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
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${pattern.masteredCount} / ${pattern.totalPhrases} phrases",
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
