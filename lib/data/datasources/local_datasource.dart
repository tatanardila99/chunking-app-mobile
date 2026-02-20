import '../local/database_helper.dart';

/// LocalDataSource actúa como wrapper de DatabaseHelper
/// Proporciona una capa de abstracción para acceso a datos locales
class LocalDataSource {
  final DatabaseHelper _dbHelper;

  LocalDataSource(this._dbHelper);

  // ==================== PATTERNS ====================

  Future<List<Map<String, dynamic>>> getPatterns() async {
    return await _dbHelper.getPatternsWithProgress();
  }

  Future<Map<String, dynamic>?> getPatternById(int id) async {
    return await _dbHelper.getPatternById(id);
  }

  // ==================== PHRASES ====================

  Future<List<Map<String, dynamic>>> getPhrasesByPatternId(
    int patternId,
  ) async {
    return await _dbHelper.getPhrasesByPatternId(patternId);
  }

  Future<List<Map<String, dynamic>>> getDuePhrases(int limit) async {
    return await _dbHelper.getDuePhrasesForSRS(limit);
  }

  Future<List<Map<String, dynamic>>> getSmartMixPhrases(int limit) async {
    return await _dbHelper.getSmartMixPhrases(limit);
  }

  // ==================== PROGRESS ====================

  Future<Map<String, dynamic>?> getProgressByPhraseId(int phraseId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'user_progress',
      where: 'phrase_id = ?',
      whereArgs: [phraseId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateProgress(int phraseId, String field, bool value) async {
    await _dbHelper.updateProgress(phraseId, field, value);
  }

  Future<void> updateSRSProgress({
    required int phraseId,
    required int srsLevel,
    required int nextReviewDate,
    required int lastReviewedDate,
    required int failCount,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'user_progress',
      {
        'srs_level': srsLevel,
        'next_review_date': nextReviewDate,
        'last_reviewed_date': lastReviewedDate,
        'fail_count': failCount,
      },
      where: 'phrase_id = ?',
      whereArgs: [phraseId],
    );
  }

  Future<void> logSession({
    required int phraseId,
    required String mode,
    required bool isCorrect,
    int? responseTimeMs,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('session_logs', {
      'phrase_id': phraseId,
      'mode': mode,
      'is_correct': isCorrect ? 1 : 0,
      'response_time_ms': responseTimeMs,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ==================== STATS ====================

  Future<int> getDailyXP() async {
    return await _dbHelper.getDailyXP();
  }

  Future<Map<String, int>> getGlobalStats() async {
    return await _dbHelper.getGlobalStats();
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    return await _dbHelper.getWeeklyStats();
  }

  Future<String> getUserLevel() async {
    return await _dbHelper.getUserLevel();
  }

  Future<int> getCurrentStreak() async {
    return await _dbHelper.getCurrentStreak();
  }

  Future<double> getTotalListeningHours() async {
    return await _dbHelper.getTotalListeningHours();
  }

  Future<void> addPhraseCount(int count) async {
    await _dbHelper.addPhraseCount(count);
  }
}
