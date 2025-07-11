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
import 'dart:convert';
import '../services/database_service.dart';
import '../services/permission_service.dart';
import '../services/native_sensor_service.dart';
import '../services/device_info_service.dart';
import '../widgets/sensor_card.dart';
import '../widgets/control_panel.dart';
import '../widgets/status_cards.dart';
import '../widgets/export_format_dialog.dart';

class SensorHomePage extends StatefulWidget {
  const SensorHomePage({super.key});

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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🚀 === INICIANDO APLICACIÓN ===');
    
    // Verificar estado final de permisos (ya fueron solicitados en main.dart)
    await PermissionService.checkAndLogAllPermissions();
    
    // Solicitar deshabilitar optimización de batería y configurar sensores nativos
    await _requestBatteryOptimizationPermission();
    await _initializeNativeSensors();
    
    print('✅ === SENSOR HOME INICIALIZADA ===');
  }
  void _startRecording() async {
    if (_isRecording) return;

    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _isRecording = true;
      _recordingTime = 0;
      _dataCount = 0;
    });

    // ACTIVAR WAKELOCK PARA MANTENER SENSORES ACTIVOS
    await WakelockPlus.enable();
    print('🔋 WakeLock activado en app principal');

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
        // No guardamos aquí, el timer se encarga de eso
      },
      onError: (error) {
        print('Error GPS: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error GPS: $error')),
        );
      },
    );

    // Iniciar sensores con alta frecuencia (solo para actualizar la UI)
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval, // 20ms para mejor respuesta
    ).listen(
      (AccelerometerEvent event) {
        setState(() {
          _currentAccelerometer = event;
        });
        // Log para verificar que los datos cambian
        print('📱 APP Accel: ${event.x.toStringAsFixed(3)}, ${event.y.toStringAsFixed(3)}, ${event.z.toStringAsFixed(3)}');
      },
    );

    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval, // 20ms para mejor respuesta
    ).listen(
      (GyroscopeEvent event) {
        setState(() {
          _currentGyroscope = event;
        });
        // Log para verificar que los datos cambian
        print('📱 APP Gyro: ${event.x.toStringAsFixed(3)}, ${event.y.toStringAsFixed(3)}, ${event.z.toStringAsFixed(3)}');
      },
    );

    // Iniciar servicio en segundo plano si está habilitado
    if (_backgroundMode) {
      await _startBackgroundService();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grabación iniciada - ${_samplingRate} Hz (SENSORES ACTIVOS)'),
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
    
    // Enviar comando al servicio para iniciar grabación
    service.invoke('startRecording', {
      'sessionId': _currentSessionId,
      'samplingRate': _samplingRate,
    });
    
    print('📤 Comando enviado al servicio: iniciar grabación');
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
      print('⚠️ Sin permisos de almacenamiento para exportar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se requieren permisos de almacenamiento para exportar datos')),
      );
      return;
    }

    try {
      // Obtener datos para contar muestras
      final data = await DatabaseService.getData(sessionId: _currentSessionId);
      
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay datos para exportar en esta sesión'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar diálogo de selección de formato
      final selectedFormat = await showExportFormatDialog(
        context,
        sessionId: _currentSessionId!,
        totalSamples: data.length,
      );
      
      if (selectedFormat == null) return; // Usuario canceló

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
                      'Generando archivo ${selectedFormat.name.toUpperCase()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      print('🔄 Iniciando exportación para sesión: $_currentSessionId');
      print('📊 Total de registros a exportar: ${data.length}');
      print('📁 Formato seleccionado: ${selectedFormat.name.toUpperCase()}');

      // Obtener metadatos del dispositivo
      final metadata = await DeviceInfoService.getExportMetadata(
        _currentSessionId!,
        data.length,
      );

      // Crear nombre de archivo con timestamp
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = selectedFormat == ExportFormat.csv
          ? 'sensor_data_$dateStr.csv'
          : 'sensor_data_$dateStr.json';

      String fileContent = '';
      
      if (selectedFormat == ExportFormat.csv) {
        // Generar CSV con metadatos completos
        fileContent = DeviceInfoService.generateCsvHeader(metadata);
        
        // Procesar datos en lotes para evitar problemas de memoria
        const batchSize = 50;
        final buffer = StringBuffer();
        
        for (int i = 0; i < data.length; i += batchSize) {
          final endIndex = (i + batchSize < data.length) ? i + batchSize : data.length;
          final batch = data.sublist(i, endIndex);
          
          for (var row in batch) {
            buffer.writeln('${row['timestamp']},${row['acc_x'] ?? ''},${row['acc_y'] ?? ''},${row['acc_z'] ?? ''},${row['gyro_x'] ?? ''},${row['gyro_y'] ?? ''},${row['gyro_z'] ?? ''},${row['gps_lat'] ?? ''},${row['gps_lng'] ?? ''},${row['gps_accuracy'] ?? ''},${row['gps_speed'] ?? ''},${row['gps_altitude'] ?? ''},${row['gps_heading'] ?? ''},${row['session_id'] ?? ''}');
          }
          
          fileContent += buffer.toString();
          buffer.clear();
          await Future.delayed(Duration(milliseconds: 20));
          
          if (i % (batchSize * 10) == 0) {
            print('📈 Procesando: ${(i / data.length * 100).toInt()}% completado');
          }
        }
      } else {
        // Generar JSON con estructura completa
        final jsonData = DeviceInfoService.generateJsonExport(metadata, data);
        fileContent = JsonEncoder.withIndent('  ').convert(jsonData);
      }

      // Intentar guardar en múltiples ubicaciones
      List<File> savedFiles = [];
      
      try {
        // 1. Directorio de documentos de la app
        final appDir = await getApplicationDocumentsDirectory();
        final appFile = File('${appDir.path}/$fileName');
        await appFile.writeAsString(fileContent);
        savedFiles.add(appFile);
        print('✅ Archivo guardado en app documents: ${appFile.path}');
      } catch (e) {
        print('❌ Error guardando en app documents: $e');
      }

      try {
        // 2. Directorio de Downloads (si es posible)
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadsPath = externalDir.path.replaceAll('Android/data/com.example.test1/files', 'Download');
          final downloadsDir = Directory('$downloadsPath/RecWay_SensorData');
          
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          
          final downloadsFile = File('${downloadsDir.path}/$fileName');
          await downloadsFile.writeAsString(fileContent);
          savedFiles.add(downloadsFile);
          print('✅ Archivo guardado en Downloads: ${downloadsFile.path}');
        }
      } catch (e) {
        print('❌ Error guardando en Downloads: $e');
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
      print('❌ Error durante la exportación: $e');
      
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
            )).toList(),
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
              )).toList(),
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
      print('✅ Optimización de batería deshabilitada');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Optimización de batería deshabilitada - mejor rendimiento en segundo plano'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print('⚠️ Optimización de batería no deshabilitada');
      _showBatteryOptimizationDialog();
    }
    
    // También solicitar optimización nativa
    try {
      await NativeSensorService.requestBatteryOptimization();
      print('🔋 Solicitada optimización de batería nativa');
    } catch (e) {
      print('❌ Error solicitando optimización de batería nativa: $e');
    }
  }
  
  Future<void> _initializeNativeSensors() async {
    try {
      final status = await NativeSensorService.getStatus();
      print('📱 Estado sensores nativos: $status');
      
      if (status['hasAccelerometer'] == true && status['hasGyroscope'] == true) {
        print('✅ Sensores nativos disponibles');
      } else {
        print('⚠️ Algunos sensores nativos no están disponibles');
      }
    } catch (e) {
      print('❌ Error inicializando sensores nativos: $e');
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
