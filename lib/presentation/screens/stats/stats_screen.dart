import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with WidgetsBindingObserver {
  int _streak = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  String _totalPhrases = "0";
  String _listeningHours = "0.0";
  String _currentLevel = "A1";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Agregamos un observador para detectar cambios de estado de la app
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadStats() async {
    try {
      final db = DatabaseHelper.instance;

      // 1. Cargar datos en paralelo para ser más rápidos
      final streak = await db.getCurrentStreak();
      final weekly = await db.getWeeklyStats();
      final level = await db.getUserLevel();
      final hours = await db.getTotalListeningHours();

      // Calcular total de frases masterizadas (aprox) para mostrar dato interesante
      // Usamos una consulta rápida directa
      // Contar frases donde P1 y P2 son 1 (Maestría)
      final database = await db.database;
      final countRes = await database.rawQuery(
        'SELECT COUNT(*) FROM user_progress WHERE p1 = 1 AND p2 = 1',
      );

      // Sqflite.firstIntValue devuelve el primer número de la consulta
      int totalMastered = Sqflite.firstIntValue(countRes) ?? 0;

      if (mounted) {
        setState(() {
          _streak = streak;
          _weeklyData = weekly;
          _currentLevel = level;
          _listeningHours = hours.toStringAsFixed(1);
          _totalPhrases = totalMastered.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si quieres que sea 100% instantáneo al entrar a la pestaña:
    _loadStats();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Statistics",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Your growth journey",
                                style: TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 1. STREAK CARD (HERO SECTION)
                      _buildStreakHero(),

                      const SizedBox(height: 30),

                      // 2. CHART SECTION
                      const Text(
                        "ACTIVITY THIS WEEK",
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildModernChart(),

                      const SizedBox(height: 30),

                      // 3. LIFETIME STATS GRID
                      const Text(
                        "LIFETIME STATS",
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildStreakHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE65100),
            Color(0xFFFF9800),
          ], // Naranja quemado a Naranja vivo
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fuego Animado (Simulado con icono grande)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "$_streak",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "DAYS",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Text(
                "Current Streak",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernChart() {
    // Calcular máximo para normalizar altura
    int maxValue = 1;
    for (var d in _weeklyData) if (d['value'] > maxValue) maxValue = d['value'];

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            _weeklyData.map((day) {
              final int value = day['value'];
              final double percentage = (value / maxValue).clamp(0.0, 1.0);
              final bool isToday = day['isToday'];
              final bool hasActivity = value > 0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Tooltip flotante si tiene actividad
                  if (hasActivity && isToday)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "$value",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                  // La Barra
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuart,
                    width: 14,
                    height: 100 * percentage + 4, // Altura mínima
                    decoration: BoxDecoration(
                      gradient:
                          isToday
                              ? const LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen,
                                  Color(0xFF69F0AE),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              )
                              : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.2),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow:
                          isToday
                              ? [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                              : [],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    day['day'],
                    style: TextStyle(
                      color: isToday ? AppTheme.primaryGreen : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4, // Cajas más rectangulares
      children: [
        _buildStatBox(
          Icons.check_circle_outline_rounded,
          _totalPhrases,
          "Phrases Mastered",
          Colors.blueAccent,
        ),
        _buildStatBox(
          Icons.timer_outlined,
          _listeningHours,
          "Listening Hours",
          Colors.purpleAccent,
        ),
        _buildStatBox(
          Icons.bar_chart_rounded,
          _currentLevel,
          "Current Level",
          Colors.tealAccent,
        ),
        _buildStatBox(
          Icons.star_outline_rounded,
          "Top 5%",
          "Global Rank",
          Colors.amberAccent,
        ),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
