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
import '../widgets/export_format_dialog.dart';
import '../theme/app_theme.dart';

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
  Timer? _uiUpdateTimer; // Timer para controlar las actualizaciones de UI
  int _dataCount = 0;
  String? _currentSessionId;
  
  // Configuración
  int _samplingRate = 10; // Hz
  bool _backgroundMode = false;
  
  // Datos actuales de sensores
  AccelerometerEvent? _currentAccelerometer;
  GyroscopeEvent? _currentGyroscope;
  Position? _currentPosition;
  
  // Control de actualizaciones de UI
  bool _shouldUpdateUI = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _startUIUpdateTimer();
  }
  
  /// Inicia el timer para limitar las actualizaciones de UI a 1 vez por segundo
  void _startUIUpdateTimer() {
    _uiUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _shouldUpdateUI = true;
      });
    });
  }

  Future<void> _initializeApp() async {
    //print('🚀 === INICIANDO APLICACIÓN ===');
    
    // Verificar estado final de permisos (ya fueron solicitados en main.dart)
    await PermissionService.checkAndLogAllPermissions();
    
    // Solicitar deshabilitar optimización de batería y configurar sensores nativos
    await _requestBatteryOptimizationPermission();
    await _initializeNativeSensors();
    
    //print('✅ === SENSOR HOME INICIALIZADA ===');
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
    //print('🔋 WakeLock activado en app principal');

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
        _currentPosition = position;
        if (_shouldUpdateUI) {
          setState(() {
            _shouldUpdateUI = false;
          });
        }
        // No guardamos aquí, el timer se encarga de eso
      },
      onError: (error) {
        //print('Error GPS: $error');
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
        _currentAccelerometer = event;
        if (_shouldUpdateUI) {
          setState(() {
            _shouldUpdateUI = false;
          });
        }
        // Log para verificar que los datos cambian
       // print('📱 APP Accel: ${event.x.toStringAsFixed(3)}, ${event.y.toStringAsFixed(3)}, ${event.z.toStringAsFixed(3)}');
      },
    );

    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval, // 20ms para mejor respuesta
    ).listen(
      (GyroscopeEvent event) {
        _currentGyroscope = event;
        if (_shouldUpdateUI) {
          setState(() {
            _shouldUpdateUI = false;
          });
        }
        // Log para verificar que los datos cambian
        //print('📱 APP Gyro: ${event.x.toStringAsFixed(3)}, ${event.y.toStringAsFixed(3)}, ${event.z.toStringAsFixed(3)}');
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
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                Icons.check_circle, 
                color: AppColors.success, 
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Datos Exportados',
              style: AppTextStyles.headline3.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registros exportados: $recordCount',
                    style: AppTextStyles.body1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Archivo: $fileName',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ubicaciones: ${files.length}',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'El archivo se guardó en:',
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            ...files.map((file) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.folder, 
                    size: 16, 
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getReadableePath(file.path),
                      style: AppTextStyles.body2.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'Que quieres hacer ahora?',
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareFile(files.first);
            },
            icon: Icon(Icons.share, color: AppColors.accentBlue),
            label: Text(
              'Compartir',
              style: AppTextStyles.button.copyWith(
                color: AppColors.accentBlue,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showFileDetailsDialog(files, recordCount);
            },
            icon: Icon(Icons.info, color: AppColors.warning),
            label: Text(
              'Detalles',
              style: AppTextStyles.button.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
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
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Detalles del Archivo',
              style: AppTextStyles.headline3.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Registros', recordCount.toString()),
              _buildDetailItem('Fecha', DateTime.now().toString().split(' ')[0]),
              _buildDetailItem('Hora', DateTime.now().toString().split(' ')[1].split('.')[0]),
              _buildDetailItem('Archivos guardados', files.length.toString()),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Ubicaciones de archivos:',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              ...files.map((file) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: AppColors.accentBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getReadableePath(file.path),
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.path,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
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
            icon: Icon(Icons.share, color: AppColors.accentBlue),
            label: Text(
              'Compartir',
              style: AppTextStyles.button.copyWith(
                color: AppColors.accentBlue,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
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

  /// Construye la sección de estado con cards modernas
  Widget _buildStatusSection() {
    return Column(
      children: [
        // Fila superior con métricas
        Row(
          children: [
            Expanded(
              child: AppWidgets.gradientCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.timer,
                      color: AppColors.accentBlue,
                      size: AppDimensions.iconM,
                    ),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text('Tiempo', style: AppTextStyles.sensorLabel),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      _formatTime(_recordingTime),
                      style: AppTextStyles.headline3.copyWith(
                        color: AppColors.accentBlue,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: AppWidgets.gradientCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.data_usage,
                      color: AppColors.accentCyan,
                      size: AppDimensions.iconM,
                    ),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text('Muestras', style: AppTextStyles.sensorLabel),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      '$_dataCount',
                      style: AppTextStyles.headline3.copyWith(
                        color: AppColors.accentCyan,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: AppWidgets.gradientCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.speed,
                      color: AppColors.warning,
                      size: AppDimensions.iconM,
                    ),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text('Freq.', style: AppTextStyles.sensorLabel),
                    const SizedBox(height: AppDimensions.paddingXS),
                    GestureDetector(
                      onTap: _showFrequencySelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$_samplingRate Hz',
                            style: AppTextStyles.headline3.copyWith(
                              color: AppColors.warning,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingM),
        
        // Estado centrado debajo
        Container(
          width: double.infinity,
          child: AppWidgets.gradientCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRecording ? Icons.fiber_manual_record : Icons.sensors,
                  color: _isRecording ? AppColors.error : AppColors.accentBlue,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  _isRecording 
                    ? 'Grabando datos...'
                    : 'Listo para grabar',
                  style: AppTextStyles.body1.copyWith(
                    color: _isRecording ? AppColors.error : AppColors.accentBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye la sección de control con botones modernos
  Widget _buildControlSection() {
    return AppWidgets.gradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control de Grabación',
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          
          // Botones principales
          Row(
            children: [
              Expanded(
                child: AppWidgets.gradientButton(
                  text: _isRecording ? 'Detener' : 'Iniciar',
                  icon: _isRecording ? Icons.stop : Icons.play_arrow,
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryMedium.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.accentBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _dataCount > 0 ? _exportData : null,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingL,
                          vertical: AppDimensions.paddingM,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.file_download,
                              color: _dataCount > 0 ? AppColors.accentBlue : AppColors.surface.withOpacity(0.5),
                              size: AppDimensions.iconS,
                            ),
                            const SizedBox(width: AppDimensions.paddingS),
                            Text(
                              'Exportar',
                              style: AppTextStyles.button.copyWith(
                                color: _dataCount > 0 ? AppColors.surface : AppColors.surface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingM),
          
          // Configuración
          _buildConfigurationSection(),
        ],
      ),
    );
  }

  /// Construye la sección de configuración
  Widget _buildConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: AppTextStyles.sensorLabel,
        ),
        const SizedBox(height: AppDimensions.paddingM),
        
        // Frecuencia de muestreo
        Row(
          children: [
            Expanded(
              child: Text(
                'Frecuencia: $_samplingRate Hz',
                style: AppTextStyles.body1,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryMedium.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _samplingRate > 1 ? () {
                      setState(() {
                        _samplingRate = (_samplingRate - 1).clamp(1, 100);
                      });
                    } : null,
                    icon: const Icon(Icons.remove, color: AppColors.surface),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Text(
                    '$_samplingRate',
                    style: AppTextStyles.sensorValue.copyWith(fontSize: 14),
                  ),
                  IconButton(
                    onPressed: _samplingRate < 100 ? () {
                      setState(() {
                        _samplingRate = (_samplingRate + 1).clamp(1, 100);
                      });
                    } : null,
                    icon: const Icon(Icons.add, color: AppColors.surface),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingM),
        
        // Modo en segundo plano
        Row(
          children: [
            Expanded(
              child: Text(
                'Segundo plano',
                style: AppTextStyles.body1,
              ),
            ),
            Switch(
              value: _backgroundMode,
              onChanged: (value) {
                setState(() {
                  _backgroundMode = value;
                });
              },
              activeColor: AppColors.accentBlue,
              inactiveThumbColor: AppColors.surface.withOpacity(0.5),
              inactiveTrackColor: AppColors.primaryMedium.withOpacity(0.5),
            ),
          ],
        ),
      ],
    );
  }

  /// Construye la sección de datos de sensores
  Widget _buildSensorSection() {
    return SensorCard(
      accelerometer: _currentAccelerometer,
      gyroscope: _currentGyroscope,
      position: _currentPosition,
    );
  }

  /// Formatea el tiempo en formato mm:ss
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Muestra el diálogo de selección de frecuencia
  void _showFrequencySelector() {
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede cambiar la frecuencia durante la grabación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Seleccionar Frecuencia',
          style: AppTextStyles.headline3.copyWith(color: AppColors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona la frecuencia de muestreo para los sensores:',
              style: AppTextStyles.body1.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            ...[ 1, 5, 10, 20, 50].map((frequency) => Container(
              margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXS),
              child: ListTile(
                leading: Icon(
                  Icons.speed,
                  color: _samplingRate == frequency ? AppColors.accentBlue : AppColors.onSurfaceVariant,
                ),
                title: Text(
                  '$frequency Hz',
                  style: AppTextStyles.body1.copyWith(
                    color: _samplingRate == frequency ? AppColors.accentBlue : AppColors.onSurface,
                    fontWeight: _samplingRate == frequency ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  _getFrequencyDescription(frequency),
                  style: AppTextStyles.body2.copyWith(color: AppColors.onSurfaceVariant),
                ),
                selected: _samplingRate == frequency,
                selectedTileColor: AppColors.accentBlue.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                onTap: () {
                  setState(() {
                    _samplingRate = frequency;
                  });
                  Navigator.pop(context);
                },
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTextStyles.button.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene la descripción de cada frecuencia
  String _getFrequencyDescription(int frequency) {
    switch (frequency) {
      case 1:
        return 'Muy baja - Ahorro máximo de batería';
      case 5:
        return 'Baja - Buena para movimientos lentos';
      case 10:
        return 'Normal - Equilibrio entre precisión y batería';
      case 20:
        return 'Alta - Buena para movimientos rápidos';
      case 50:
        return 'Muy alta - Máxima precisión';
      default:
        return 'Personalizada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar minimalista
              SliverAppBar(
                expandedHeight: 60,
                floating: false,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                ),
              ),
              
              // Contenido principal
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Status Cards mejoradas
                    _buildStatusSection(),
                    
                    const SizedBox(height: AppDimensions.paddingL),
                    
                    // Control Panel moderno
                    _buildControlSection(),
                    
                    const SizedBox(height: AppDimensions.paddingL),
                    
                    // Sensor Data Display mejorado
                    _buildSensorSection(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _samplingTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
