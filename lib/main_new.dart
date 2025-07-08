import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:convert';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicio en segundo plano
  await initializeService();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Data Collector Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: SensorHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SensorHomePage extends StatefulWidget {
  @override
  _SensorHomePageState createState() => _SensorHomePageState();
}

class _SensorHomePageState extends State<SensorHomePage> {
  // Streams para sensores
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;
  
  // Base de datos
  Database? _database;
  
  // Estado de la aplicación
  bool _isRecording = false;
  int _recordingTime = 0;
  Timer? _timer;
  int _dataCount = 0;
  
  // Configuración
  int _samplingRate = 10; // Hz
  bool _backgroundMode = false;
  
  // Datos actuales de sensores
  AccelerometerEvent? _currentAccelerometer;
  GyroscopeEvent? _currentGyroscope;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _initializeDatabase();
    await _checkLocationServices();
  }

  Future<void> _requestPermissions() async {
    // Solicitar todos los permisos necesarios
    Map<Permission, PermissionStatus> permissions = await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.sensors,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();

    // Verificar si todos los permisos fueron concedidos
    permissions.forEach((permission, status) {
      if (status != PermissionStatus.granted) {
        print('Permiso $permission no concedido: $status');
      }
    });
  }

  Future<void> _checkLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Mostrar diálogo para activar servicios de ubicación
      _showLocationServiceDialog();
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Servicios de Ubicación'),
          content: Text('Los servicios de ubicación están desactivados. Por favor, actívalos para obtener datos GPS precisos.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: Text('Abrir Configuración'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'sensor_data_pro.db');
    
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        return _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) {
        return _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sensor_data (
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

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_timestamp ON sensor_data(timestamp);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_session ON sensor_data(session_id);
    ''');
  }

  void _startRecording() async {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _recordingTime = 0;
      _dataCount = 0;
    });

    // Iniciar timer para el tiempo de grabación
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTime++;
      });
    });

    // Configurar GPS con máxima precisión
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // Actualizar con cualquier movimiento
      timeLimit: Duration(seconds: 30), // Timeout para obtener posición
    );

    // Iniciar stream de GPS
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
        });
        _saveDataPoint();
      },
      onError: (error) {
        print('Error GPS: $error');
      },
    );

    // Iniciar sensores
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        setState(() {
          _currentAccelerometer = event;
        });
      },
    );

    _gyroscopeSubscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        setState(() {
          _currentGyroscope = event;
        });
      },
    );

    // Iniciar servicio en segundo plano si está habilitado
    if (_backgroundMode) {
      await _startBackgroundService();
    }

    // Mostrar notificación de grabación activa
    _showRecordingNotification();
  }

  void _stopRecording() {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });

    // Detener timer
    _timer?.cancel();
    _timer = null;

    // Detener streams
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();

    // Detener servicio en segundo plano
    FlutterBackgroundService().invoke('stopService');

    // Cancelar notificación
    _cancelRecordingNotification();

    _showDataSummary();
  }

  Future<void> _saveDataPoint() async {
    if (_database == null || !_isRecording) return;

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    
    await _database!.insert('sensor_data', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'acc_x': _currentAccelerometer?.x,
      'acc_y': _currentAccelerometer?.y,
      'acc_z': _currentAccelerometer?.z,
      'gyro_x': _currentGyroscope?.x,
      'gyro_y': _currentGyroscope?.y,
      'gyro_z': _currentGyroscope?.z,
      'gps_lat': _currentPosition?.latitude,
      'gps_lng': _currentPosition?.longitude,
      'gps_accuracy': _currentPosition?.accuracy,
      'gps_speed': _currentPosition?.speed,
      'gps_altitude': _currentPosition?.altitude,
      'gps_heading': _currentPosition?.heading,
      'session_id': sessionId,
    });

    setState(() {
      _dataCount++;
    });
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  void _showRecordingNotification() {
    // Implementar notificación persistente
  }

  void _cancelRecordingNotification() {
    // Cancelar notificación
  }

  void _showDataSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grabación Completada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duración: ${_formatTime(_recordingTime)}'),
            Text('Muestras recolectadas: $_dataCount'),
            if (_recordingTime > 0)
              Text('Frecuencia promedio: ${(_dataCount / _recordingTime).toStringAsFixed(1)} Hz'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData();
            },
            child: Text('Exportar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    if (_database == null) return;

    final data = await _database!.query(
      'sensor_data',
      orderBy: 'timestamp DESC',
      limit: _dataCount,
    );

    // Crear CSV
    String csvContent = 'timestamp,acc_x,acc_y,acc_z,gyro_x,gyro_y,gyro_z,gps_lat,gps_lng,gps_accuracy,gps_speed,gps_altitude,gps_heading\n';
    
    for (var row in data) {
      csvContent += '${row['timestamp']},${row['acc_x']},${row['acc_y']},${row['acc_z']},${row['gyro_x']},${row['gyro_y']},${row['gyro_z']},${row['gps_lat']},${row['gps_lng']},${row['gps_accuracy']},${row['gps_speed']},${row['gps_altitude']},${row['gps_heading']}\n';
    }

    // Guardar archivo (implementar según necesidades)
    print('Datos exportados: ${data.length} registros');
    print('CSV generado con ${csvContent.split('\n').length - 1} líneas');
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Data Collector Pro'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Tiempo',
                    _formatTime(_recordingTime),
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Muestras',
                    _dataCount.toString(),
                    Icons.data_usage,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Frecuencia',
                    '$_samplingRate Hz',
                    Icons.speed,
                    Colors.purple,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Estado',
                    _isRecording ? 'Grabando' : 'Detenido',
                    _isRecording ? Icons.fiber_manual_record : Icons.stop,
                    _isRecording ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Control Panel
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Control',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isRecording ? _stopRecording : _startRecording,
                            icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                            label: Text(_isRecording ? 'Detener' : 'Iniciar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _dataCount > 0 ? _exportData : null,
                            icon: Icon(Icons.download),
                            label: Text('Exportar'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Configuración de frecuencia
                    Row(
                      children: [
                        Text('Frecuencia: '),
                        Expanded(
                          child: DropdownButton<int>(
                            value: _samplingRate,
                            isExpanded: true,
                            items: [1, 5, 10, 20, 50].map((rate) {
                              return DropdownMenuItem(
                                value: rate,
                                child: Text('$rate Hz'),
                              );
                            }).toList(),
                            onChanged: _isRecording ? null : (value) {
                              setState(() {
                                _samplingRate = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Modo segundo plano
                    SwitchListTile(
                      title: Text('Modo Segundo Plano'),
                      subtitle: Text('Continuar grabando cuando la app esté en segundo plano'),
                      value: _backgroundMode,
                      onChanged: _isRecording ? null : (value) {
                        setState(() {
                          _backgroundMode = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Sensor Data Display
            _buildSensorDataCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataCards() {
    return Column(
      children: [
        // Acelerómetro
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smartphone, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Acelerómetro (m/s²)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildAxisValue('X', _currentAccelerometer?.x ?? 0, Colors.red)),
                    Expanded(child: _buildAxisValue('Y', _currentAccelerometer?.y ?? 0, Colors.green)),
                    Expanded(child: _buildAxisValue('Z', _currentAccelerometer?.z ?? 0, Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Giroscopio
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rotate_right, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Giroscopio (rad/s)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildAxisValue('X', _currentGyroscope?.x ?? 0, Colors.red)),
                    Expanded(child: _buildAxisValue('Y', _currentGyroscope?.y ?? 0, Colors.green)),
                    Expanded(child: _buildAxisValue('Z', _currentGyroscope?.z ?? 0, Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // GPS
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'GPS de Alta Precisión',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (_currentPosition != null) ...[
                  _buildGPSValue('Latitud', '${_currentPosition!.latitude.toStringAsFixed(6)}°'),
                  _buildGPSValue('Longitud', '${_currentPosition!.longitude.toStringAsFixed(6)}°'),
                  _buildGPSValue('Precisión', '±${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
                  _buildGPSValue('Velocidad', '${(_currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h'),
                  _buildGPSValue('Altitud', '${_currentPosition!.altitude.toStringAsFixed(1)}m'),
                ] else
                  Text('Esperando señal GPS...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAxisValue(String axis, double value, Color color) {
    return Column(
      children: [
        Text(axis, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toStringAsFixed(3),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGPSValue(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
    _database?.close();
    super.dispose();
  }
}
