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

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // --- 1. CREACIÓN DE TABLAS ---
  Future<void> _onCreate(Database db, int version) async {
    // A. Tabla de Patrones (Metadata)
    await db.execute('''
      CREATE TABLE patterns (
        id INTEGER PRIMARY KEY,
        title TEXT,
        subtitle TEXT,
        grammar_rule TEXT,
        level TEXT,
        is_active INTEGER DEFAULT 1,
        total_phrases INTEGER DEFAULT 0,
        mastered_count INTEGER DEFAULT 0
      )
    ''');

    // B. Tabla de Frases (Contenido)
    await db.execute('''
      CREATE TABLE phrases (
        id INTEGER PRIMARY KEY,
        pattern_id INTEGER,
        text_en TEXT,
        text_es TEXT,
        audio_url TEXT,
        FOREIGN KEY (pattern_id) REFERENCES patterns (id) ON DELETE CASCADE
      )
    ''');

    // C. Tabla de Progreso (Estado P1 y P2)
    await db.execute('''
      CREATE TABLE user_progress (
        phrase_id INTEGER PRIMARY KEY,
        p1 INTEGER DEFAULT 0,
        p2 INTEGER DEFAULT 0,
        FOREIGN KEY (phrase_id) REFERENCES phrases (id) ON DELETE CASCADE
      )
    ''');

    // D. Tabla de Actividad Diaria (Para Stats y Rachas) 📊
    await db.execute('''
      CREATE TABLE daily_activity (
        date TEXT PRIMARY KEY,  -- Formato "YYYY-MM-DD"
        xp INTEGER DEFAULT 0,
        phrases_count INTEGER DEFAULT 0
      )
    ''');

    // Insertar datos de prueba iniciales (Seed)
    // NOTA: Si vas a importar tu Excel, borra o comenta esta línea después de la primera vez.
    await _seedData(db);
  }

  // --- DATOS INICIALES (SEED) ---
  Future<void> _seedData(Database db) async {
    // Patrón 1
    await db.insert('patterns', {
      'id': 1,
      'title': "I'm allowed to...",
      'subtitle': "Permisos y reglas",
      'grammar_rule':
          "Used to express permission. Followed by a verb in base form.",
      'level': "A1",
      'total_phrases': 2,
      'mastered_count': 0,
    });

    // Frases del Patrón 1
    await db.insert('phrases', {
      'id': 1,
      'pattern_id': 1,
      'text_en': "I'm allowed to drive",
      'text_es': "Tengo permiso para conducir",
    });
    await db.insert('phrases', {
      'id': 2,
      'pattern_id': 1,
      'text_en': "I'm allowed to park here",
      'text_es': "Tengo permiso para estacionar aquí",
    });
    await db.insert('user_progress', {'phrase_id': 1, 'p1': 0, 'p2': 0});
    await db.insert('user_progress', {'phrase_id': 2, 'p1': 0, 'p2': 0});

    // Patrón 2 (Bloqueado inicialmente)
    await db.insert('patterns', {
      'id': 2,
      'title': "It's worth...",
      'subtitle': "Valor y recomendación",
      'grammar_rule': "Used to recommend something good. Followed by Verb-ING.",
      'level': "B1",
      'total_phrases': 2,
      'mastered_count': 0,
    });

    // Frases del Patrón 2
    await db.insert('phrases', {
      'id': 3,
      'pattern_id': 2,
      'text_en': "It's worth trying",
      'text_es': "Vale la pena intentarlo",
    });
    await db.insert('phrases', {
      'id': 4,
      'pattern_id': 2,
      'text_en': "It's worth waiting",
      'text_es': "Vale la pena esperar",
    });
    await db.insert('user_progress', {'phrase_id': 3, 'p1': 0, 'p2': 0});
    await db.insert('user_progress', {'phrase_id': 4, 'p1': 0, 'p2': 0});
  }

  // ===========================================================================
  // SECCIÓN 2: LÓGICA DE ACTUALIZACIÓN (EL CEREBRO 🧠)
  // ===========================================================================

  Future<void> updateProgress(int phraseId, String field, bool value) async {
    final db = await instance.database;
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // 1. Actualizar Checkbox (P1 o P2)
    await db.rawUpdate(
      '''
      UPDATE user_progress 
      SET $field = ? 
      WHERE phrase_id = ?
    ''',
      [value ? 1 : 0, phraseId],
    );

    // 2. Registrar XP y Actividad si completó algo
    if (value) {
      // Si no existe fila de hoy, la crea en 0
      await db.rawInsert(
        'INSERT OR IGNORE INTO daily_activity (date, xp, phrases_count) VALUES (?, 0, 0)',
        [today],
      );

      // Suma 10 XP y +1 Frase
      await db.rawUpdate(
        '''
        UPDATE daily_activity 
        SET xp = xp + 10, phrases_count = phrases_count + 1 
        WHERE date = ?
      ''',
        [today],
      );
    }

    // 3. Recalcular % del Patrón Padre (Para desbloquear el siguiente nivel)
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

  // Método privado para actualizar los contadores del patrón
  Future<void> _updatePatternMastery(Database db, int patternId) async {
    // Total de frases en este patrón
    final totalRes = await db.rawQuery(
      'SELECT COUNT(*) FROM phrases WHERE pattern_id = ?',
      [patternId],
    );
    int total = Sqflite.firstIntValue(totalRes) ?? 0;

    // Total de frases MASTERIZADAS (P1=1 Y P2=1)
    final masteredRes = await db.rawQuery(
      '''
      SELECT COUNT(*) FROM user_progress up
      JOIN phrases p ON up.phrase_id = p.id
      WHERE p.pattern_id = ? AND up.p1 = 1 AND up.p2 = 1
    ''',
      [patternId],
    );
    int mastered = Sqflite.firstIntValue(masteredRes) ?? 0;

    // Guardar en tabla patterns (Caché para la UI)
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

  // Para LibraryScreen
  Future<List<Map<String, dynamic>>> getPatternsWithProgress() async {
    final db = await instance.database;
    return await db.query('patterns', orderBy: 'id ASC');
  }

  // Para LessonScreen (Info del Header)
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

  // Para LessonScreen (Lista de Frases)
  Future<List<Map<String, dynamic>>> getPhrasesByPatternId(
    dynamic patternId,
  ) async {
    final db = await instance.database;
    final id = patternId is String ? int.tryParse(patternId) ?? 0 : patternId;

    final result = await db.rawQuery(
      '''
      SELECT ph.id, ph.text_en, ph.text_es, up.p1, up.p2
      FROM phrases ph
      JOIN user_progress up ON ph.id = up.phrase_id
      WHERE ph.pattern_id = ?
    ''',
      [id],
    );

    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ===========================================================================
  // SECCIÓN 4: ESTADÍSTICAS (StatsScreen)
  // ===========================================================================

  // XP de Hoy
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

  // Resumen Global
  Future<Map<String, int>> getGlobalStats() async {
    final db = await instance.database;
    // Total Chunks (Frases al 100%)
    final masteredRes = await db.rawQuery(
      'SELECT COUNT(*) FROM user_progress WHERE p1=1 AND p2=1',
    );
    final mastered = Sqflite.firstIntValue(masteredRes) ?? 0;

    return {'chunks_collected': mastered, 'accuracy': 94};
  }

  // Datos para Gráfica (Últimos 7 días)
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
}
