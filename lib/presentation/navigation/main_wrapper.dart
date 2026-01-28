import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainWrapper extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainWrapper({super.key, required this.navigationShell});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  void _goToBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      extendBody:
          true, // ¡Clave! Permite que el contenido se vea detrás de la barra (efecto cristal)
      body: widget.navigationShell,
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        30,
      ), // Márgenes para que "flote"
      height: 70, // Altura de la cápsula
      decoration: BoxDecoration(
        color: const Color(
          0xFF1E1E1E,
        ).withOpacity(0.85), // Fondo semitransparente
        borderRadius: BorderRadius.circular(35), // Bordes muy redondos
        border: Border.all(color: Colors.white.withOpacity(0.1)), // Borde sutil
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ), // Efecto de desenfoque (Glass)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                icon: Icons.grid_view_rounded,
                label: "Library",
                index: 0,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _goToBranch,
              ),
              _NavBarItem(
                icon: Icons.fitness_center_rounded,
                label: "Practice",
                index: 1,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _goToBranch,
              ),
              _NavBarItem(
                icon: Icons.bar_chart_rounded,
                label: "Stats",
                index: 2,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _goToBranch,
              ),
              _NavBarItem(
                icon: Icons.person_rounded,
                label: "Profile",
                index: 3,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _goToBranch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque, // Para mejorar el área de toque
      child: SizedBox(
        width: 60,
        height: 70, // Ocupa toda la altura
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack, // Efecto rebote
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppTheme.primaryGreen.withOpacity(
                          0.2,
                        ) // Fondo verde suave al seleccionar
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey,
                size: isSelected ? 26 : 24, // Crece un poco al seleccionar
              ),
            ),
            // Puntito indicador debajo (opcional, estilo minimalista)
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
