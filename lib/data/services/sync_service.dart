import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../../core/config/api_config.dart'; // <--- IMPORTANTE: Importamos la Config
import '../local/database_helper.dart';

class SyncService {
  // Ya no definimos _apiUrl aquí, usamos la centralizada.

  Future<void> syncData() async {
    try {
      print("🔄 Iniciando sincronización con el servidor...");
      print("📡 Conectando a: ${ApiConfig.syncData}"); // Log para depurar

      // 1. Llamar al Backend usando ApiConfig
      final response = await http.get(Uri.parse(ApiConfig.syncData));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List patterns = data['patterns'];
        List phrases = data['phrases'];

        print(
          "📥 Recibidos: ${patterns.length} patrones y ${phrases.length} frases.",
        );

        // 2. Guardar en SQLite Local
        await _saveToLocalDB(patterns, phrases);

        print("✅ Sincronización completada exitosamente.");
      } else {
        print("❌ Error en servidor: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("⚠️ Error de conexión (Posiblemente Offline o IP incorrecta): $e");
      // Si falla, la app sigue funcionando offline.
    }
  }

  Future<void> _saveToLocalDB(List patterns, List phrases) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    // A. Actualizar Patrones
    for (var p in patterns) {
      batch.insert('patterns', {
        'id': p['id'], // ID de MySQL
        'title': p['title'],
        'subtitle': p['subtitle'],
        'grammar_rule': p['grammar_rule'],
        'level': p['level'],
        'sort_order':
            p['sort_order'] ?? 0, // <--- OJO: Guardamos el orden lógico
        'is_active': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // B. Actualizar Frases
    for (var ph in phrases) {
      batch.insert('phrases', {
        'id': ph['id'],
        'pattern_id': ph['pattern_id'],
        'text_en': ph['text_en'],
        'text_es': ph['text_es'],
        'audio_url': ph['audio_url'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Inicializar progreso vacío solo si es una frase nueva
      batch.rawInsert(
        '''
        INSERT OR IGNORE INTO user_progress (phrase_id, p1, p2) VALUES (?, 0, 0)
        ''',
        [ph['id']],
      );
    }

    await batch.commit(noResult: true);
  }
}
