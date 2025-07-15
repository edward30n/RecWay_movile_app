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
import '../theme/app_theme.dart';

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

  /// Inicializar GPS de forma más robusta
  Future<void> _initializeGPS() async {
    try {
      // Verificar servicios de ubicación
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Servicios de ubicación deshabilitados');
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('⚠️ Permisos de ubicación denegados');
        return;
      }

      // Intentar obtener posición actual con timeout corto
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        setState(() {
          _currentPosition = position;
        });
        print('📍 Posición inicial obtenida: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('⚠️ No se pudo obtener posición inicial: $e');
        // Usar última posición conocida
        await _tryLastKnownPosition();
      }
    } catch (e) {
      print('⚠️ Error inicializando GPS: $e');
    }
  }

  /// Intentar obtener la última posición conocida como fallback
  Future<void> _tryLastKnownPosition() async {
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        setState(() {
          _currentPosition = lastPosition;
        });
        print('📍 Usando última posición conocida: ${lastPosition.latitude}, ${lastPosition.longitude}');
      }
    } catch (e) {
      print('⚠️ No se pudo obtener última posición conocida: $e');
    }
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

    // Inicializar GPS de forma robusta
    await _initializeGPS();

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

    // Configurar GPS con configuración más permisiva para evitar timeouts
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Cambiado de bestForNavigation
      distanceFilter: 1, // Cambiado de 0 para reducir carga
      timeLimit: Duration(minutes: 2), // Aumentado para evitar timeouts
    );

    // Iniciar stream de GPS con manejo de errores mejorado
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
        });
      },
      onError: (error) {
        print('⚠️ Error GPS: $error');
        // No mostrar error en UI para timeouts, solo para errores graves
        if (!error.toString().contains('timeout') && !error.toString().contains('time limit')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('GPS temporalmente no disponible'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 2),
            ),
          );
        }
        // Intentar obtener la última posición conocida
        _tryLastKnownPosition();
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
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Grabación Completada',
          style: AppTextStyles.headline3.copyWith(color: AppColors.surface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duración: ${_formatTime(_recordingTime)}',
              style: AppTextStyles.body1.copyWith(color: AppColors.surface),
            ),
            Text(
              'Muestras recolectadas: $_dataCount',
              style: AppTextStyles.body1.copyWith(color: AppColors.surface),
            ),
            if (_recordingTime > 0)
              Text(
                'Frecuencia promedio: ${(_dataCount / _recordingTime).toStringAsFixed(1)} Hz',
                style: AppTextStyles.body1.copyWith(color: AppColors.surface),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.surface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: AppColors.surface,
            ),
            child: Text('Exportar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    if (_currentSessionId == null) return;

    // Verificar permisos de almacenamiento con la nueva función mejorada
    final hasStoragePermission = await PermissionService.requestStoragePermissionsForExport();
    if (!hasStoragePermission) {
      // Mostrar diálogo explicativo específico
      PermissionService.showStoragePermissionExplanation(context);
      return;
    }

    try {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.primaryMedium,
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exportando datos...',
                      style: AppTextStyles.body1.copyWith(color: AppColors.surface),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Generando archivo CSV',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.surface.withOpacity(0.7),
                      ),
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
      csvContent += '# Formato de datos:\n';
      csvContent += '#   - Sensores (acc/gyro): 6 decimales de precisión\n';
      csvContent += '#   - GPS (lat/lng): 8 decimales de precisión\n';
      csvContent += '#   - Filas incompletas automáticamente removidas\n';
      csvContent += '#\n';
      csvContent += 'timestamp,acc_x,acc_y,acc_z,gyro_x,gyro_y,gyro_z,gps_lat,gps_lng,gps_accuracy,gps_speed,gps_altitude,gps_heading\n';
      
      // Procesar datos en lotes más pequeños para evitar problemas de memoria
      const batchSize = 50; // Reducido de 100 a 50 para mayor estabilidad
      final validRows = <String>[];
      
      for (int i = 0; i < data.length; i += batchSize) {
        final endIndex = (i + batchSize < data.length) ? i + batchSize : data.length;
        final batch = data.sublist(i, endIndex);
        
        // Procesar el lote actual con validación y formato de precisión
        for (var row in batch) {
          // Formatear valores con precisión específica
          final accX = _formatSensorValue(row['acc_x']);
          final accY = _formatSensorValue(row['acc_y']);
          final accZ = _formatSensorValue(row['acc_z']);
          final gyroX = _formatSensorValue(row['gyro_x']);
          final gyroY = _formatSensorValue(row['gyro_y']);
          final gyroZ = _formatSensorValue(row['gyro_z']);
          
          // Formatear valores GPS (mayor precisión para coordenadas)
          final gpsLat = _formatGPSValue(row['gps_lat']);
          final gpsLng = _formatGPSValue(row['gps_lng']);
          final gpsAccuracy = _formatGPSValue(row['gps_accuracy']);
          final gpsSpeed = _formatGPSValue(row['gps_speed']);
          final gpsAltitude = _formatGPSValue(row['gps_altitude']);
          final gpsHeading = _formatGPSValue(row['gps_heading']);
          
          // Crear la fila CSV
          final csvRow = '${row['timestamp']},$accX,$accY,$accZ,$gyroX,$gyroY,$gyroZ,$gpsLat,$gpsLng,$gpsAccuracy,$gpsSpeed,$gpsAltitude,$gpsHeading';
          
          // Validar que la fila tenga contenido esencial (timestamp y al menos un sensor)
          if (_isValidCSVRow(csvRow, row)) {
            validRows.add(csvRow);
          }
        }
        
        // Dar más tiempo al sistema para procesar
        await Future.delayed(Duration(milliseconds: 20));
      }
      
      // Verificar y limpiar filas incompletas al final
      final cleanedRows = _cleanIncompleteRows(validRows);
      
      // Agregar filas validadas al contenido CSV
      csvContent += cleanedRows.join('\n');
      if (cleanedRows.isNotEmpty) {
        csvContent += '\n'; // Asegurar nueva línea al final
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
        // Mostrar información sobre la limpieza de datos
        final originalCount = data.length;
        final finalCount = cleanedRows.length;
        
        if (originalCount != finalCount) {
          print('📊 Limpieza de datos: $originalCount registros originales → $finalCount registros finales');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Datos procesados: ${originalCount - finalCount} registros incompletos removidos'),
              backgroundColor: AppColors.accentBlue,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Mostrar opciones de exportación
        _showExportOptionsDialog(savedFiles, finalCount, fileName);
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
        backgroundColor: AppColors.primaryMedium,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Text(
              'Completado',
              style: AppTextStyles.headline3.copyWith(color: AppColors.surface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registros: $recordCount',
                    style: AppTextStyles.body1.copyWith(color: AppColors.surface),
                  ),
                  Text(
                    'Archivo: $fileName',
                    style: AppTextStyles.body1.copyWith(color: AppColors.surface),
                  ),
                  Text(
                    'Ubicaciones: ${files.length}',
                    style: AppTextStyles.body1.copyWith(color: AppColors.surface),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.paddingM),
            Text(
              'El archivo se guardó en:',
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppDimensions.paddingS),
            ...files.map((file) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.folder, 
                    size: 16, 
                    color: AppColors.accentBlue,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getReadableePath(file.path),
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.surface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            )),
            SizedBox(height: AppDimensions.paddingM),
            Text(
              '¿Qué quieres hacer ahora?',
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.bold,
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
              style: TextStyle(color: AppColors.accentBlue),
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
              style: TextStyle(color: AppColors.warning),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: AppColors.surface,
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
        title: Text(
          '📋 Detalles del Archivo',
          style: AppTextStyles.headline3.copyWith(color: AppColors.surface),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('📊 Registros', recordCount.toString()),
              _buildDetailItem('📅 Fecha', DateTime.now().toString().split(' ')[0]),
              _buildDetailItem('⏰ Hora', DateTime.now().toString().split(' ')[1].split('.')[0]),
              _buildDetailItem('💾 Archivos guardados', files.length.toString()),
              SizedBox(height: AppDimensions.paddingM),
              Text(
                'Ubicaciones de archivos:',
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDimensions.paddingS),
              ...files.map((file) => Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                padding: EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: AppColors.surface.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getReadableePath(file.path),
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      file.path,
                      style: AppTextStyles.body2.copyWith(
                        fontSize: 10,
                        color: AppColors.surface.withOpacity(0.6),
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
            icon: Icon(Icons.share, color: AppColors.accentBlue),
            label: Text(
              'Compartir',
              style: TextStyle(color: AppColors.accentBlue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(color: AppColors.surface),
            ),
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
              style: AppTextStyles.body1.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.surface.withOpacity(0.8),
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

  /// Formatear valores de sensores (acelerómetro y giroscopio) con 6 decimales
  String _formatSensorValue(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      return value.toStringAsFixed(6);
    }
    return value.toString();
  }

  /// Formatear valores GPS con mayor precisión (8 decimales para coordenadas)
  String _formatGPSValue(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      return value.toStringAsFixed(8);
    }
    return value.toString();
  }

  /// Validar que una fila CSV tenga contenido esencial
  bool _isValidCSVRow(String csvRow, Map<String, dynamic> originalRow) {
    // Verificar que tenga timestamp
    if (originalRow['timestamp'] == null) return false;
    
    // Verificar que tenga al menos algunos datos de sensores
    final hasAccelerometer = originalRow['acc_x'] != null || 
                            originalRow['acc_y'] != null || 
                            originalRow['acc_z'] != null;
    
    final hasGyroscope = originalRow['gyro_x'] != null || 
                        originalRow['gyro_y'] != null || 
                        originalRow['gyro_z'] != null;
    
    final hasGPS = originalRow['gps_lat'] != null || 
                  originalRow['gps_lng'] != null;
    
    // La fila es válida si tiene timestamp y al menos un tipo de dato
    return hasAccelerometer || hasGyroscope || hasGPS;
  }

  /// Limpiar filas incompletas al final del archivo
  List<String> _cleanIncompleteRows(List<String> rows) {
    if (rows.isEmpty) return rows;
    
    // Contar el número esperado de campos (13 campos en total)
    const expectedFieldCount = 13;
    
    // Buscar desde el final hacia atrás hasta encontrar filas válidas consecutivas
    int lastValidIndex = rows.length - 1;
    int consecutiveValidRows = 0;
    const minConsecutiveValid = 3; // Requerir al menos 3 filas válidas consecutivas
    
    for (int i = rows.length - 1; i >= 0; i--) {
      final fields = rows[i].split(',');
      
      // Verificar que la fila tenga el número correcto de campos
      if (fields.length == expectedFieldCount) {
        // Verificar que tenga timestamp válido
        final timestamp = fields[0];
        if (timestamp.isNotEmpty && int.tryParse(timestamp) != null) {
          consecutiveValidRows++;
          
          // Si hemos encontrado suficientes filas válidas consecutivas, parar aquí
          if (consecutiveValidRows >= minConsecutiveValid) {
            break;
          }
        } else {
          // Fila inválida, reiniciar contador
          consecutiveValidRows = 0;
          lastValidIndex = i - 1;
        }
      } else {
        // Fila incompleta, reiniciar contador
        consecutiveValidRows = 0;
        lastValidIndex = i - 1;
      }
    }
    
    // Si no encontramos suficientes filas válidas consecutivas al final,
    // usar la última fila que sabemos que es válida
    if (consecutiveValidRows < minConsecutiveValid && lastValidIndex >= 0) {
      final cleanedRows = rows.sublist(0, lastValidIndex + 1);
      print('🔧 Limpieza CSV: Removidas ${rows.length - cleanedRows.length} filas incompletas del final');
      return cleanedRows;
    }
    
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return AppWidgets.gradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'RecWay',
            style: AppTextStyles.headline3.copyWith(color: AppColors.surface),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            children: [
              // Status Cards
              StatusCards(
                recordingTime: _recordingTime,
                dataCount: _dataCount,
                samplingRate: _samplingRate,
                isRecording: _isRecording,
              ),
              
              SizedBox(height: AppDimensions.paddingL),

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

              SizedBox(height: AppDimensions.paddingL),

              // Sensor Data Display
              SensorCard(
                accelerometer: _currentAccelerometer,
                gyroscope: _currentGyroscope,
                position: _currentPosition,
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
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
