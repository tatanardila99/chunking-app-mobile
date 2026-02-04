import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color primaryGreen = Color(0xFF21E5A0); // Verde Neón
  static const Color accentBlue = Color(0xFF2979FF); // Azul para gráficos
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFB3B3B3);
  static const Color masteredGreen = Color(
    0xFF1B5E20,
  ); // Verde oscuro para mastered
  // Agrega esto dentro de tu clase AppTheme
  static const Color fireOrange = Color(0xFFFF5722);
  static const Color chartBarBg = Color(0xFF2C2C2C);
  // Gradiente para el círculo principal
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryGreen,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        surface: cardDark,
        background: bgDark,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: bgDark, elevation: 0),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
