import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'local/database_helper.dart';

class SyncService {
  // Cambia esto por tu IP local si usas emulador Android (10.0.2.2) o tu IP real si usas físico
  // Ejemplo Android Emulator: "http://10.0.2.2:3000/api/sync"
  static const String _apiUrl = "http://192.168.1.18:3000/api/sync";

  Future<void> syncData() async {
    try {
      print("🔄 Iniciando sincronización con el servidor...");

      // 1. Llamar al Backend
      final response = await http.get(Uri.parse(_apiUrl));

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
        print("❌ Error en servidor: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error de conexión (Posiblemente Offline): $e");
      // Si falla, no pasa nada. La app sigue funcionando con lo que ya tenía en SQLite.
    }
  }

  Future<void> _saveToLocalDB(List patterns, List phrases) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    // Estrategia Simple: "Upsert" (Insertar o Reemplazar si ya existe)

    // A. Actualizar Patrones
    for (var p in patterns) {
      batch.insert('patterns', {
        'id': p['id'], // Mantenemos el mismo ID que en MySQL
        'title': p['title'],
        'subtitle': p['subtitle'],
        'grammar_rule': p['grammar_rule'],
        'level': p['level'],
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

      // Asegurarnos de que exista una entrada de progreso para esta frase (si es nueva)
      // "INSERT OR IGNORE" para no borrar el progreso si ya existe
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
