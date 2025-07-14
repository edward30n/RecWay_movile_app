import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'sensor_data';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'sensor_data_pro.db');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) => _createTables(db),
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        acc_x REAL,
        acc_y REAL,
        acc_z REAL,
        gyro_x REAL,
        gyro_y REAL,
        gyro_z REAL,
        gps_lat REAL,
        gps_lng REAL,
        gps_accuracy REAL,
        gps_speed REAL,
        gps_altitude REAL,
        gps_heading REAL,
        session_id TEXT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_timestamp ON $_tableName(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_session ON $_tableName(session_id)');
  }

  static Future<void> insertData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(_tableName, data);
  }

  static Future<List<Map<String, dynamic>>> getData({String? sessionId, int? limit}) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (sessionId != null) {
      whereClause = 'session_id = ?';
      whereArgs = [sessionId];
    }
    
    return await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  static Future<int> getDataCount({String? sessionId}) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (sessionId != null) {
      whereClause = 'session_id = ?';
      whereArgs = [sessionId];
    }
    
    final result = await db.query(
      _tableName,
      columns: ['COUNT(*) as count'],
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return result.first['count'] as int;
  }

  static Future<void> clearOldData({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(days: daysToKeep)).millisecondsSinceEpoch;
    
    await db.delete(
      _tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoffTime],
    );
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_tableName);
  }

  static Future<List<String>> getUniqueSessions() async {
    final db = await database;
    final results = await db.query(
      _tableName,
      columns: ['DISTINCT session_id'],
      orderBy: 'session_id DESC',
    );
    
    return results
        .map<String>((row) => row['session_id'] as String)
        .where((sessionId) => sessionId.isNotEmpty)
        .toList();
  }

  static Future<Map<String, dynamic>> getSessionStats(String sessionId) async {
    final db = await database;
    
    final countResult = await db.query(
      _tableName,
      columns: ['COUNT(*) as count'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    
    final timeResult = await db.query(
      _tableName,
      columns: ['MIN(timestamp) as start_time', 'MAX(timestamp) as end_time'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    
    final count = countResult.first['count'] as int;
    final startTime = timeResult.first['start_time'] as int?;
    final endTime = timeResult.first['end_time'] as int?;
    
    return {
      'count': count,
      'start_time': startTime,
      'end_time': endTime,
      'duration': startTime != null && endTime != null ? endTime - startTime : 0,
    };
  }

  // Método para verificar la salud de la base de datos
  static Future<bool> isDatabaseHealthy() async {
    try {
      final db = await database;
      
      // Verificar si la tabla existe y es accesible
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'"
      );
      
      if (result.isEmpty) {
        print('⚠️ Tabla de base de datos no encontrada, recreando...');
        await _createTables(db);
      }
      
      // Probar una consulta simple
      await db.rawQuery('SELECT COUNT(*) FROM $_tableName LIMIT 1');
      
      print('✅ Base de datos saludable');
      return true;
    } catch (e) {
      print('❌ Error verificando salud de base de datos: $e');
      return false;
    }
  }

  // Método para limpiar sesiones abiertas en caso de crash
  static Future<void> cleanupOpenSessions() async {
    try {
      final db = await database;
      
      // Verificar si hay sesiones que no se cerraron correctamente
      final openSessions = await db.rawQuery('''
        SELECT DISTINCT session_id 
        FROM $_tableName 
        WHERE session_id IS NOT NULL 
        ORDER BY timestamp DESC 
        LIMIT 10
      ''');
      
      if (openSessions.isNotEmpty) {
        print('🧹 Encontradas ${openSessions.length} sesiones previas');
        // Opcional: aquí podrías marcar sesiones como cerradas o limpiarlas
      }
      
    } catch (e) {
      print('⚠️ Error limpiando sesiones abiertas: $e');
    }
  }
}
