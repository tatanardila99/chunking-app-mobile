import 'package:chunking_english/presentation/screens/practice/practice_screen.dart';
import 'package:chunking_english/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/main_wrapper.dart';
import 'presentation/screens/library/library_screen.dart';
import 'presentation/screens/lesson/lesson_screen.dart';
import 'presentation/screens/stats/stats_screen.dart';

void main() {
  runApp(const ProviderScope(child: ChunkingApp()));
}

// Configuración de GoRouter
final _router = GoRouter(
  initialLocation: '/library', // Arrancamos en Library
  routes: [
    // 1. EL SHELL DE NAVEGACIÓN (Con barra inferior)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        // RAMA 0: Library (Primer icono)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),

        // RAMA 1: Practice (Segundo icono - Placeholder)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/practice',
              builder:
                  (context, state) =>
                      const PracticeScreen(), // <--- AQUÍ ESTÁ EL CAMBIO
            ),
          ],
        ),

        // RAMA 2: Stats (Tercer icono - Aquí está tu pantalla de progreso)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),

        // RAMA 3: Profile (Cuarto icono - Placeholder)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(), // <--- AQUÍ
            ),
          ],
        ),
      ],
    ),

    // 2. RUTA DE LA LECCIÓN (Fuera del menú inferior)
    GoRoute(
      path: '/lesson/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LessonScreen(patternId: id);
      },
    ),
  ],
);

class ChunkingApp extends ConsumerWidget {
  const ChunkingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Chunking English',
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
