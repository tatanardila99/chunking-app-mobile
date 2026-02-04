import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chunking_english.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Mantenemos version: 1. Al desinstalar la app, esto corre desde cero.
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // --- 1. CREACIÓN DE TABLAS (ACTUALIZADO PARA SLOT MACHINE & SRS) ---
  Future<void> _onCreate(Database db, int version) async {
    // A. Tabla de Patrones (Metadata)
    // CAMBIO: Agregado 'sort_order' para ordenamiento personalizado
    await db.execute('''
      CREATE TABLE patterns (
        id INTEGER PRIMARY KEY,
        title TEXT,
        subtitle TEXT,
        grammar_rule TEXT,
        level TEXT,
        sort_order INTEGER DEFAULT 0, -- <--- NUEVO
        is_active INTEGER DEFAULT 1,
        total_phrases INTEGER DEFAULT 0,
        mastered_count INTEGER DEFAULT 0
      )
    ''');

    // B. Tabla de Frases (Contenido)
    // CAMBIO: Agregado 'image_url' para el Visual Anchor del Slot Machine
    await db.execute('''
      CREATE TABLE phrases (
        id INTEGER PRIMARY KEY,
        pattern_id INTEGER,
        text_en TEXT,
        text_es TEXT,
        audio_url TEXT,
        image_url TEXT, -- <--- NUEVO: URL local o remota de la imagen
        FOREIGN KEY (pattern_id) REFERENCES patterns (id) ON DELETE CASCADE
      )
    ''');

    // C. Tabla de Progreso (HÍBRIDO: P1/P2 + SRS)
    // Mantenemos P1/P2 para que no se rompa tu LessonScreen actual.
    // Agregamos campos SRS para el futuro Daily Mix.
    await db.execute('''
      CREATE TABLE user_progress (
        phrase_id INTEGER PRIMARY KEY,
        p1 INTEGER DEFAULT 0,             -- Legacy (Lesson Screen)
        p2 INTEGER DEFAULT 0,             -- Legacy (Lesson Screen)
        srs_level INTEGER DEFAULT 0,      -- NUEVO: 0=Nuevo, 1=Aprendido, 2=Retenido, 3=Maestro
        next_review_date INTEGER,         -- NUEVO: Timestamp (ms) para la próxima revisión
        last_reviewed_date INTEGER,       -- NUEVO: Timestamp (ms) de la última práctica
        fail_count INTEGER DEFAULT 0,     -- NUEVO: Contador de fallos
        FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
      )
    ''');

    // D. Tabla de Actividad Diaria
    await db.execute('''
      CREATE TABLE daily_activity (
        date TEXT PRIMARY KEY,
        xp INTEGER DEFAULT 0,
        phrases_count INTEGER DEFAULT 0,
        listening_seconds INTEGER DEFAULT 0
      )
    ''');

    // E. NUEVA TABLA: SESSION LOGS (Para Speed Drill y Métricas)
    await db.execute('''
      CREATE TABLE session_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phrase_id INTEGER,
        mode TEXT,                -- 'standard', 'speed_drill', 'passive'
        is_correct INTEGER,       -- 1 o 0
        response_time_ms INTEGER, -- Tiempo de respuesta
        created_at INTEGER,       -- Timestamp
        FOREIGN KEY (phrase_id) REFERENCES phrases (id)
      )
    ''');

    // Insertar datos de prueba
    await _seedData(db);
  }

  // --- DATOS INICIALES (SEED ACTUALIZADO) ---
  Future<void> _seedData(Database db) async {
    // Patrón 1
    await db.insert('patterns', {
      'id': 1,
      'title': "I'm allowed to...",
      'subtitle': "Permisos y reglas",
      'grammar_rule':
          "Used to express permission. Followed by a verb in base form.",
      'level': "A1",
      'sort_order': 1, // Nuevo
      'total_phrases': 2,
      'mastered_count': 0,
    });

    // Frases del Patrón 1 (Con image_url null por ahora)
    await db.insert('phrases', {
      'id': 1,
      'pattern_id': 1,
      'text_en': "I'm allowed to drive",
      'text_es': "Tengo permiso para conducir",
      'image_url': 'https://picsum.photos/seed/car/300/300',
    });
    await db.insert('phrases', {
      'id': 2,
      'pattern_id': 1,
      'text_en': "I'm allowed to park here",
      'text_es': "Tengo permiso para estacionar aquí",
      'image_url': 'https://picsum.photos/seed/parking/300/300',
    });

    // Inicializar progreso (SRS en 0)
    await db.insert('user_progress', {
      'phrase_id': 1,
      'p1': 0,
      'p2': 0,
      'srs_level': 0,
      'fail_count': 0,
    });
    await db.insert('user_progress', {
      'phrase_id': 2,
      'p1': 0,
      'p2': 0,
      'srs_level': 0,
      'fail_count': 0,
    });

    // Patrón 2
    await db.insert('patterns', {
      'id': 2,
      'title': "It's worth...",
      'subtitle': "Valor y recomendación",
      'grammar_rule': "Used to recommend something good. Followed by Verb-ING.",
      'level': "B1",
      'sort_order': 2, // Nuevo
      'total_phrases': 2,
      'mastered_count': 0,
    });

    await db.insert('phrases', {
      'id': 3,
      'pattern_id': 2,
      'text_en': "It's worth trying",
      'text_es': "Vale la pena intentarlo",
      'image_url': 'https://picsum.photos/seed/trying/300/300',
    });
    await db.insert('phrases', {
      'id': 4,
      'pattern_id': 2,
      'text_en': "It's worth waiting",
      'text_es': "Vale la pena esperar",
      'image_url': 'https://picsum.photos/seed/waiting/300/300',
    });
    await db.insert('user_progress', {
      'phrase_id': 3,
      'p1': 0,
      'p2': 0,
      'srs_level': 0,
      'fail_count': 0,
    });
    await db.insert('user_progress', {
      'phrase_id': 4,
      'p1': 0,
      'p2': 0,
      'srs_level': 0,
      'fail_count': 0,
    });
  }

  // ===========================================================================
  // SECCIÓN 2: LÓGICA DE ACTUALIZACIÓN (LEGACY + FUTURE)
  // ===========================================================================

  Future<void> updateProgress(int phraseId, String field, bool value) async {
    final db = await instance.database;
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // 1. Actualizar Checkbox (P1 o P2) - Mantener lógica actual
    await db.rawUpdate(
      'UPDATE user_progress SET $field = ? WHERE phrase_id = ?',
      [value ? 1 : 0, phraseId],
    );

    // 2. Registrar XP y Actividad
    if (value) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO daily_activity (date, xp, phrases_count) VALUES (?, 0, 0)',
        [today],
      );

      await db.rawUpdate(
        'UPDATE daily_activity SET xp = xp + 4, phrases_count = phrases_count + 1 WHERE date = ?',
        [today],
      );
    }

    // 3. Recalcular % del Patrón Padre
    final List<Map<String, dynamic>> phraseResult = await db.query(
      'phrases',
      columns: ['pattern_id'],
      where: 'id = ?',
      whereArgs: [phraseId],
    );

    if (phraseResult.isNotEmpty) {
      int patternId = phraseResult.first['pattern_id'] as int;
      await _updatePatternMastery(db, patternId);
    }
  }

  Future<void> _updatePatternMastery(Database db, int patternId) async {
    final totalRes = await db.rawQuery(
      'SELECT COUNT(*) FROM phrases WHERE pattern_id = ?',
      [patternId],
    );
    int total = Sqflite.firstIntValue(totalRes) ?? 0;

    final masteredRes = await db.rawQuery(
      '''
      SELECT COUNT(*) FROM user_progress up
      JOIN phrases p ON up.phrase_id = p.id
      WHERE p.pattern_id = ? AND up.p1 = 1 AND up.p2 = 1
      ''',
      [patternId],
    );
    int mastered = Sqflite.firstIntValue(masteredRes) ?? 0;

    await db.update(
      'patterns',
      {'total_phrases': total, 'mastered_count': mastered},
      where: 'id = ?',
      whereArgs: [patternId],
    );
  }

  // ===========================================================================
  // SECCIÓN 3: LECTURAS PARA LA UI
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getPatternsWithProgress() async {
    final db = await instance.database;
    // Usamos el nuevo sort_order, y fallback a id
    return await db.query('patterns', orderBy: 'sort_order ASC, id ASC');
  }

  Future<Map<String, dynamic>?> getPatternById(dynamic id) async {
    final db = await instance.database;
    final patternId = id is String ? int.tryParse(id) ?? 0 : id;
    final result = await db.query(
      'patterns',
      where: 'id = ?',
      whereArgs: [patternId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getPhrasesByPatternId(
    dynamic patternId,
  ) async {
    final db = await instance.database;
    final id = patternId is String ? int.tryParse(patternId) ?? 0 : patternId;

    final result = await db.rawQuery(
      '''
      SELECT ph.id, ph.text_en, ph.text_es, ph.image_url, up.p1, up.p2, up.srs_level
      FROM phrases ph
      JOIN user_progress up ON ph.id = up.phrase_id
      WHERE ph.pattern_id = ?
      ''',
      [id],
    );

    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ===========================================================================
  // SECCIÓN 4: ESTADÍSTICAS & NUEVOS MÉTODOS SRS
  // ===========================================================================

  // NUEVO: Obtener frases "Vencidas" para el Daily Mix (SRS)
  Future<List<Map<String, dynamic>>> getDuePhrasesForSRS(int limit) async {
    final db = await instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Lógica: Traer frases donde next_review_date ya pasó O es nulo (nuevas)
    // También traemos el pattern_title para el Slot Machine
    final result = await db.rawQuery(
      '''
      SELECT ph.id, ph.text_en, ph.text_es, ph.image_url, 
             pat.title as pattern_title, 
             up.srs_level, up.next_review_date
      FROM phrases ph
      JOIN user_progress up ON ph.id = up.phrase_id
      JOIN patterns pat ON ph.pattern_id = pat.id
      WHERE (up.next_review_date <= ? OR up.next_review_date IS NULL)
      ORDER BY up.next_review_date ASC
      LIMIT ?
    ''',
      [nowMs, limit],
    );

    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // (Mantenemos tus métodos de Stats originales)
  Future<int> getDailyXP() async {
    final db = await instance.database;
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final result = await db.query(
      'daily_activity',
      columns: ['xp'],
      where: 'date = ?',
      whereArgs: [today],
    );
    return result.isNotEmpty ? (result.first['xp'] as int) : 0;
  }

  Future<Map<String, int>> getGlobalStats() async {
    final db = await instance.database;
    final masteredRes = await db.rawQuery(
      'SELECT COUNT(*) FROM user_progress WHERE p1=1 AND p2=1',
    );
    final mastered = Sqflite.firstIntValue(masteredRes) ?? 0;
    return {'chunks_collected': mastered, 'accuracy': 94};
  }

  Future<void> recalculateAllPatternCounts() async {
    final db = await instance.database;
    final patterns = await db.query('patterns');
    for (var pattern in patterns) {
      int id = pattern['id'] as int;
      final totalRes = await db.rawQuery(
        'SELECT COUNT(*) FROM phrases WHERE pattern_id = ?',
        [id],
      );
      int total = Sqflite.firstIntValue(totalRes) ?? 0;
      final masteredRes = await db.rawQuery(
        'SELECT COUNT(*) FROM user_progress up JOIN phrases p ON up.phrase_id = p.id WHERE p.pattern_id = ? AND up.p1 = 1 AND up.p2 = 1',
        [id],
      );
      int mastered = Sqflite.firstIntValue(masteredRes) ?? 0;
      await db.update(
        'patterns',
        {'total_phrases': total, 'mastered_count': mastered},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    print("✅ Contadores de patrones recalculados correctamente.");
  }

  // (Este método se mantiene por si quieres un mix aleatorio, pero el de SRS es mejor)
  Future<List<Map<String, dynamic>>> getSmartMixPhrases(int limit) async {
    return getDuePhrasesForSRS(limit); // Ahora redirigimos al SRS
  }

  Future<List<double>> getWeeklyActivity() async {
    final db = await instance.database;
    final now = DateTime.now();
    List<double> activity = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final result = await db.query(
        'daily_activity',
        columns: ['phrases_count'],
        where: 'date = ?',
        whereArgs: [dateStr],
      );
      activity.add(
        result.isNotEmpty
            ? (result.first['phrases_count'] as int).toDouble()
            : 0.0,
      );
    }
    return activity;
  }

  Future<String> getUserLevel() async {
    final db = await instance.database;
    final patterns = await db.query(
      'patterns',
      orderBy: 'sort_order ASC, id ASC',
    );
    String currentLevel = "A1";
    for (int i = 0; i < patterns.length; i++) {
      final p = patterns[i];
      final int total = (p['total_phrases'] as int?) ?? 0;
      final int mastered = (p['mastered_count'] as int?) ?? 0;
      bool previousCompleted = true;
      if (i > 0) {
        final prevP = patterns[i - 1];
        final int prevTotal = (prevP['total_phrases'] as int?) ?? 0;
        final int prevMastered = (prevP['mastered_count'] as int?) ?? 0;
        if (prevTotal == 0 || prevMastered < prevTotal)
          previousCompleted = false;
      }
      if (previousCompleted) {
        currentLevel = (p['level'] as String?) ?? "A1";
      } else {
        break;
      }
    }
    return currentLevel;
  }

  Future<int> getCurrentStreak() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT date FROM daily_activity ORDER BY date DESC',
    );
    if (result.isEmpty) return 0;
    List<String> dates = result.map((e) => e['date'] as String).toList();
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterday =
        "${yesterdayDate.year}-${yesterdayDate.month.toString().padLeft(2, '0')}-${yesterdayDate.day.toString().padLeft(2, '0')}";
    if (dates.first != today && dates.first != yesterday) return 0;
    int streak = 0;
    DateTime currentDateCheck = DateTime.parse(dates.first);
    for (String dateStr in dates) {
      final date = DateTime.parse(dateStr);
      if (isSameDay(date, currentDateCheck)) {
        streak++;
        currentDateCheck = currentDateCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db = await instance.database;
    final now = DateTime.now();
    List<Map<String, dynamic>> stats = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final result = await db.query(
        'daily_activity',
        where: 'date = ?',
        whereArgs: [dateStr],
      );
      int phrases = 0;
      if (result.isNotEmpty) {
        phrases = (result.first['phrases_count'] as int?) ?? 0;
      }
      stats.add({
        'day': _getDayLetter(date.weekday),
        'value': phrases,
        'isToday': (i == 0),
      });
    }
    return stats;
  }

  String _getDayLetter(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday - 1];
  }

  Future<void> addPhraseCount(int count) async {
    final db = await instance.database;
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    await db.rawInsert(
      'INSERT OR IGNORE INTO daily_activity (date, xp, phrases_count, listening_seconds) VALUES (?, 0, 0, 0)',
      [today],
    );
    await db.rawUpdate(
      'UPDATE daily_activity SET phrases_count = phrases_count + ? WHERE date = ?',
      [count, today],
    );
  }

  Future<double> getTotalListeningHours() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(listening_seconds) as total FROM daily_activity',
    );
    int totalSeconds = Sqflite.firstIntValue(result) ?? 0;
    return totalSeconds / 3600.0;
  }
}
