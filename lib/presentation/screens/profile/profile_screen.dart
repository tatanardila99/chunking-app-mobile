import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variables para los datos dinámicos
  int _streak = 0;
  String _currentLevel = "A1";
  String _listeningHours = "0.0";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Refrescar datos cuando vuelves a la pestaña
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final db = DatabaseHelper.instance;
      final streak = await db.getCurrentStreak();
      final level = await db.getUserLevel();
      final hours = await db.getTotalListeningHours();

      if (mounted) {
        setState(() {
          _streak = streak;
          _currentLevel = level;
          _listeningHours = hours.toStringAsFixed(1);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileHeader(),
                      const SizedBox(height: 32),
                      _buildStatsSummary(), // Esta función ahora usa las variables
                      const SizedBox(height: 32),
                      _buildSectionTitle("Settings"),
                      const SizedBox(height: 16),
                      _buildSettingsTile(
                        icon: Icons.notifications_outlined,
                        title: "Notifications",
                        subtitle: "Daily reminders",
                        trailing: Switch(
                          value: true,
                          activeColor: AppTheme.primaryGreen,
                          onChanged: (val) {},
                        ),
                      ),
                      _buildSettingsTile(
                        icon: Icons.language,
                        title: "Language",
                        subtitle: "English -> Spanish",
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Data & Storage"),
                      const SizedBox(height: 16),
                      _buildSettingsTile(
                        icon: Icons.delete_outline_rounded,
                        title: "Reset Progress",
                        subtitle: "Clear all mastery data",
                        iconColor: Colors.redAccent,
                        onTap: () => _showResetDialog(context),
                      ),
                      _buildSettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: "About",
                        subtitle: "Version 1.0.0",
                        trailing: const SizedBox(),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryGreen, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            color: const Color(0xFF1E1E1E),
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Tatan Ardila",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Systems Engineering Student",
          style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // USAMOS LA VARIABLE _streak
          _buildStatItem(
            "$_streak",
            "Streak",
            Icons.local_fire_department_rounded,
            Colors.orange,
          ),
          Container(width: 1, height: 40, color: Colors.white10),
          // USAMOS LA VARIABLE _currentLevel
          _buildStatItem(
            _currentLevel,
            "Current Level",
            Icons.bar_chart_rounded,
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.white10),
          // USAMOS LA VARIABLE _listeningHours
          _buildStatItem(
            _listeningHours,
            "Hours",
            Icons.headphones_rounded,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textGrey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color iconColor = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              "Reset Progress?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "This will reset all your 'Mastered' phrases to zero locally. This cannot be undone.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final db = await DatabaseHelper.instance.database;
                  await db.rawUpdate('UPDATE user_progress SET p1 = 0, p2 = 0');
                  await db.rawUpdate('UPDATE patterns SET mastered_count = 0');
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    _loadProfileData(); // Recarga local después del reset
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text("Progress reset successfully!"),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                },
                child: const Text(
                  "Reset",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }
}
