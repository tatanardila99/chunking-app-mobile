import 'package:flutter/material.dart';

class SnackbarUtils {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // Definimos colores según el estado
    final color =
        isError ? Colors.redAccent : const Color(0xFF21E5A0); // Tu verde neón
    final icon =
        isError
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded;
    final title = isError ? "Oops!" : "Success!";

    // Limpiamos snackbars anteriores
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4), // Un segundo más para leer
        margin: const EdgeInsets.all(
          16,
        ), // Margen para que no pegue a los bordes
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            // FONDO: Usamos un negro casi puro para máximo contraste con el neón
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(20),
            // BORDE: Brillante y definido
            border: Border.all(
              color: color.withValues(
                alpha: 0.8,
              ), // Más opacidad para que el borde se vea bien
              width: 1.5,
            ),
            // SOMBRA: Aquí está la clave para que "no se pierda"
            boxShadow: [
              // 1. Resplandor exterior (Glow) del color del estado
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 25,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
              // 2. Sombra negra dura para separar del fondo
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono Glow
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight:
                            FontWeight.w800, // Más grueso para leer mejor
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color:
                            Colors.white, // Blanco puro para máximo contraste
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
