import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'dart:io';
import '../services/database_service.dart';
import '../services/permission_service.dart';
import '../widgets/sensor_card.dart';
import '../widgets/control_panel.dart';
import '../widgets/status_cards.dart';

class SensorHomePage extends StatefulWidget {
  final bool skipInitialization;
  
  const SensorHomePage({
    super.key,
    this.skipInitialization = false,
  });

  @override
  _SensorHomePageState createState() => _SensorHomePageState();
}

class _SensorHomePageState extends State<SensorHomePage> {
  // Streams para sensores
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;
  
  // Estado de la aplicación
  bool _isRecording = false;
  int _recordingTime = 0;
  Timer? _timer;
  Timer? _samplingTimer; // Timer para controlar la frecuencia de muestreo
  int _dataCount = 0;
  String? _currentSessionId;
  
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
    if (!widget.skipInitialization) {
      _initializeApp();
    } else {
      print('🔄 Saltando inicialización - ya completada en splash screen');
    }
  }

  Future<void> _initializeApp() async {
    // Verificar si es la primera vez que se abre la app
    final isFirstLaunch = await _isFirstLaunch();
    
    if (isFirstLaunch) {
      await _showWelcomeAndPermissionsDialog();
    }
    
    // Solicitar permisos de ubicación
    bool locationSuccess = await PermissionService.requestLocationPermissionsStepByStep();
    
    if (locationSuccess) {
      await PermissionService.requestAllPermissions();
    } else {
      _showLocationPermissionRequiredDialog();
    }

    // Verificar servicios de ubicación
    final locationServicesEnabled = await PermissionService.checkLocationServices();
    if (!locationServicesEnabled) {
      _showLocationServiceDialog();
    }

    // Verificar permisos específicos
    await _checkAndRequestSpecificPermissions();
    
    // Solicitar deshabilitar optimización de batería
    await _requestBatteryOptimizationPermission();
  }

  Future<bool> _isFirstLaunch() async {
    // Aquí podrías usar SharedPreferences para verificar si es el primer lanzamiento
    // Por simplicidad, siempre mostraremos el diálogo en esta versión
    return true;
  }

  Future<void> _showWelcomeAndPermissionsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.sensors, color: Colors.blue, size: 28),
              SizedBox(width: 8),
              Text('¡Bienvenido!'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esta aplicación recolecta datos de sensores y GPS para análisis científico.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Text(
                  'Permisos necesarios:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildPermissionExplanation(
                  Icons.location_on,
                  'Ubicación TODO EL TIEMPO',
                  'Permite recolectar datos GPS precisos incluso cuando la app está en segundo plano',
                  isImportant: true,
                ),
                _buildPermissionExplanation(
                  Icons.sensors,
                  'Sensores',
                  'Acceso a acelerómetro y giroscopio del dispositivo',
                ),
                _buildPermissionExplanation(
                  Icons.notifications,
                  'Notificaciones',
                  'Mostrar el estado de grabación y alertas importantes',
                ),
                _buildPermissionExplanation(
                  Icons.storage,
                  'Almacenamiento',
                  'Guardar y exportar archivos de datos al dispositivo',
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Para "Ubicación TODO EL TIEMPO", selecciona "Permitir todo el tiempo" en la configuración.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.check),
              label: Text('Continuar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionExplanation(IconData icon, String title, String description, {bool isImportant = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            size: 20, 
            color: isImportant ? Colors.red.shade600 : Colors.grey.shade600,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isImportant ? Colors.red.shade700 : null,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndRequestSpecificPermissions() async {
    // Verificar ubicación "todo el tiempo"
    final hasLocationAlways = await PermissionService.hasLocationAlwaysPermission();
    if (!hasLocationAlways) {
      await _showLocationAlwaysInstructions();
    }

    // Verificar permisos de almacenamiento
    final hasStorage = await PermissionService.hasStoragePermission();
    if (!hasStorage) {
      _showStoragePermissionDialog();
    }
  }

  void _showStoragePermissionDialog() {
    PermissionService.showPermissionDialog(
      context,
      '💾 Permiso de Almacenamiento',
      'Para exportar y guardar los datos recolectados, necesitamos acceso al almacenamiento del dispositivo.',
    );
  }

  Future<void> _showLocationAlwaysInstructions() async {
    return PermissionService.showLocationAlwaysExplanation(context);
  }

  void _showLocationPermissionRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Permisos de Ubicación Requeridos'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para que la aplicación funcione correctamente, necesita acceso a la ubicación.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '🎯 Funciones afectadas sin permisos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Recolección de datos GPS'),
              Text('• Servicios en segundo plano'),
              Text('• Exportación de datos completos'),
              SizedBox(height: 16),
              Text(
                'Por favor, concede los permisos en la siguiente pantalla.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Intentar solicitar permisos de nuevo
                _retryLocationPermissions();
              },
              child: Text('Reintentar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Abrir Configuración'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _retryLocationPermissions() async {
    bool success = await PermissionService.requestLocationPermissionsStepByStep();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Permisos de ubicación concedidos'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Permisos de ubicación requeridos para funcionalidad completa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Servicios de Ubicación'),
          content: Text(
            'Los servicios de ubicación están desactivados. '
            'Por favor, actívalos para obtener datos GPS precisos.',
          ),
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

  void _startRecording() async {
    if (_isRecording) return;

    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _isRecording = true;
      _recordingTime = 0;
      _dataCount = 0;
    });

    // Activar wakelock
    await WakelockPlus.enable();

    // Iniciar timer para el tiempo de grabación
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTime++;
      });
    });

    // Iniciar timer para controlar la frecuencia de muestreo
    final samplingInterval = Duration(milliseconds: (1000 / _samplingRate).round());
    _samplingTimer = Timer.periodic(samplingInterval, (timer) {
      if (_isRecording) {
        _saveDataPoint();
      }
    });

    // Configurar GPS con máxima precisión
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 30),
    );

    // Iniciar stream de GPS (solo para actualizar la UI, no para guardar datos)
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
        });
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error GPS: $error')),
        );
      },
    );

    // Iniciar sensores con alta frecuencia
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      (AccelerometerEvent event) {
        setState(() {
          _currentAccelerometer = event;
        });
      },
    );

    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grabación iniciada - $_samplingRate Hz'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _stopRecording() {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });

    // Detener timers
    _timer?.cancel();
    _timer = null;
    _samplingTimer?.cancel();
    _samplingTimer = null;

    // Detener streams
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();

    // Detener servicio en segundo plano
    FlutterBackgroundService().invoke('stopRecording');

    _showDataSummary();
  }

  Future<void> _saveDataPoint() async {
    if (!_isRecording || _currentSessionId == null) return;

    await DatabaseService.insertData({
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
      'session_id': _currentSessionId,
    });

    final count = await DatabaseService.getDataCount(sessionId: _currentSessionId);
    setState(() {
      _dataCount = count;
    });
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    
    service.invoke('startRecording', {
      'sessionId': _currentSessionId,
      'samplingRate': _samplingRate,
    });
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
    if (_currentSessionId == null) return;

    // Verificar permisos de almacenamiento
    final hasStoragePermission = await PermissionService.hasStoragePermission();
    if (!hasStoragePermission) {
      _showStoragePermissionDialog();
      return;
    }

    try {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exportando datos...'),
                    SizedBox(height: 4),
                    Text(
                      'Generando archivo CSV',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      // Procesar datos en lotes para evitar sobrecarga de memoria
      final data = await DatabaseService.getData(sessionId: _currentSessionId);
      
      if (data.isEmpty) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay datos para exportar en esta sesión'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Crear CSV de manera más eficiente
      final now = DateTime.now();
      final fileName = 'sensor_data_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

      // Generar contenido CSV en chunks para evitar problemas de memoria
      String csvContent = '';
      csvContent += '# Datos de Sensores - Sensor Data Collector Pro\n';
      csvContent += '# Sesión: $_currentSessionId\n';
      csvContent += '# Fecha de exportación: ${DateTime.now().toIso8601String()}\n';
      csvContent += '# Total de registros: ${data.length}\n';
      csvContent += '# Frecuencia de muestreo: $_samplingRate Hz\n';
      csvContent += '#\n';
      csvContent += 'timestamp,acc_x,acc_y,acc_z,gyro_x,gyro_y,gyro_z,gps_lat,gps_lng,gps_accuracy,gps_speed,gps_altitude,gps_heading\n';
      
      // Procesar datos en lotes más pequeños para evitar problemas de memoria
      const batchSize = 50; // Reducido de 100 a 50 para mayor estabilidad
      final buffer = StringBuffer();
      
      for (int i = 0; i < data.length; i += batchSize) {
        final endIndex = (i + batchSize < data.length) ? i + batchSize : data.length;
        final batch = data.sublist(i, endIndex);
        
        // Procesar el lote actual
        for (var row in batch) {
          buffer.writeln('${row['timestamp']},${row['acc_x'] ?? ''},${row['acc_y'] ?? ''},${row['acc_z'] ?? ''},${row['gyro_x'] ?? ''},${row['gyro_y'] ?? ''},${row['gyro_z'] ?? ''},${row['gps_lat'] ?? ''},${row['gps_lng'] ?? ''},${row['gps_accuracy'] ?? ''},${row['gps_speed'] ?? ''},${row['gps_altitude'] ?? ''},${row['gps_heading'] ?? ''}');
        }
        
        // Agregar al contenido principal y limpiar buffer
        csvContent += buffer.toString();
        buffer.clear();
        
        // Dar más tiempo al sistema para procesar y liberar memoria
        await Future.delayed(Duration(milliseconds: 20));
      }

      // Intentar guardar en múltiples ubicaciones
      List<File> savedFiles = [];
      
      try {
        // 1. Directorio de documentos de la app
        final appDir = await getApplicationDocumentsDirectory();
        final appFile = File('${appDir.path}/$fileName');
        await appFile.writeAsString(csvContent);
        savedFiles.add(appFile);
      } catch (e) {
        // Error handling silently
      }

      try {
        // 2. Directorio de Downloads (si es posible)
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Crear directorio personalizado en Downloads
          final downloadsPath = externalDir.path.replaceAll('Android/data/com.example.test1/files', 'Download');
          final downloadsDir = Directory('$downloadsPath/SensorDataCollector');
          
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          
          final downloadsFile = File('${downloadsDir.path}/$fileName');
          await downloadsFile.writeAsString(csvContent);
          savedFiles.add(downloadsFile);
        }
      } catch (e) {
        // Error handling silently
      }

      // Cerrar diálogo de carga
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (savedFiles.isNotEmpty) {
        // Mostrar opciones de exportación
        _showExportOptionsDialog(savedFiles, data.length, fileName);
      } else {
        throw Exception('No se pudo guardar el archivo en ninguna ubicación');
      }

    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _exportData,
          ),
        ),
      );
    }
  }

  void _showExportOptionsDialog(List<File> files, int recordCount, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('¡Datos Exportados!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 Registros exportados: $recordCount'),
                  Text('📁 Archivo: $fileName'),
                  Text('💾 Ubicaciones: ${files.length}'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'El archivo se guardó en:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...files.map((file) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getReadableePath(file.path),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            )),
            SizedBox(height: 16),
            Text(
              '¿Qué quieres hacer ahora?',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareFile(files.first);
            },
            icon: Icon(Icons.share, color: Colors.blue),
            label: Text('Compartir'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showFileDetailsDialog(files, recordCount);
            },
            icon: Icon(Icons.info, color: Colors.orange),
            label: Text('Detalles'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getReadableePath(String path) {
    if (path.contains('Download')) {
      return 'Downloads/SensorDataCollector/';
    } else if (path.contains('Documents')) {
      return 'Documentos de la app/';
    } else {
      return path.split('/').reversed.take(2).toList().reversed.join('/');
    }
  }

  void _showFileDetailsDialog(List<File> files, int recordCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📋 Detalles del Archivo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('📊 Registros', recordCount.toString()),
              _buildDetailItem('📅 Fecha', DateTime.now().toString().split(' ')[0]),
              _buildDetailItem('⏰ Hora', DateTime.now().toString().split(' ')[1].split('.')[0]),
              _buildDetailItem('💾 Archivos guardados', files.length.toString()),
              SizedBox(height: 16),
              Text(
                'Ubicaciones de archivos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...files.map((file) => Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getReadableePath(file.path),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      file.path,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareFile(files.first);
            },
            icon: Icon(Icons.share),
            label: Text('Compartir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _shareFile(File file) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Datos de sensores exportados desde Sensor Data Collector Pro',
        subject: 'Datos de sensores - ${DateTime.now().toString().split(' ')[0]}',
      );

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo compartido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _requestBatteryOptimizationPermission() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Optimización de batería deshabilitada - mejor rendimiento en segundo plano'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showBatteryOptimizationDialog();
    }
  }

  void _showBatteryOptimizationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.battery_alert, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Optimización de Batería'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para que la aplicación funcione correctamente en segundo plano, es importante deshabilitar la optimización de batería.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '🔋 Beneficios:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Grabación continua cuando la pantalla está bloqueada'),
              Text('• Mayor precisión en la recolección de datos'),
              Text('• Funcionamiento similar a Sensor Logger'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Busca "Sensor Data Collector Pro" en la lista y selecciona "No optimizar"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Ahora No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Ir a Configuración'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Data Collector Pro'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Cards
            StatusCards(
              recordingTime: _recordingTime,
              dataCount: _dataCount,
              samplingRate: _samplingRate,
              isRecording: _isRecording,
            ),
            
            SizedBox(height: 24),

            // Control Panel
            ControlPanel(
              isRecording: _isRecording,
              samplingRate: _samplingRate,
              backgroundMode: _backgroundMode,
              dataCount: _dataCount,
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
              onExportData: _exportData,
              onSamplingRateChanged: (rate) {
                setState(() {
                  _samplingRate = rate;
                });
              },
              onBackgroundModeChanged: (enabled) {
                setState(() {
                  _backgroundMode = enabled;
                });
              },
            ),

            SizedBox(height: 24),

            // Sensor Data Display
            SensorCard(
              accelerometer: _currentAccelerometer,
              gyroscope: _currentGyroscope,
              position: _currentPosition,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
