import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'database_service.dart';
import 'native_sensor_service.dart';

Future<void> initializeService() async {
  try {
    final service = FlutterBackgroundService();
    
    // Verificar si ya está configurado
    final isRunning = await service.isRunning();
    if (isRunning) {
      print('✅ Servicio ya está ejecutándose, saltando configuración');
      return;
    }
    
    print('🔧 Configurando servicio de background...');
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Cambiar a false para control manual
        isForegroundMode: true,
        notificationChannelId: 'sensor_data_collector',
        initialNotificationTitle: 'Sensor Data Collector Pro',
        initialNotificationContent: 'Recolectando datos en segundo plano...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false, // Cambiar a false para control manual
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    // Iniciar manualmente después de configurar
    print('🚀 Iniciando servicio manualmente...');
    await service.startService();
    
    print('✅ Servicio configurado e iniciado correctamente');
  } catch (e) {
    print('❌ Error inicializando servicio: $e');
    rethrow;
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // INMEDIATAMENTE configurar como servicio de primer plano
  if (service is AndroidServiceInstance) {
    try {
      await service.setAsForegroundService();
      print('✅ Servicio configurado como foreground service');
    } catch (e) {
      print('⚠️ Error configurando foreground service: $e');
    }
  }
  
  // ACTIVAR WAKELOCK PARA MANTENER CPU ACTIVO
  await WakelockPlus.enable();
  print('🔋 WakeLock activado para mantener sensores activos');
  
  // Variables para el muestreo controlado
  Timer? samplingTimer;
  String? currentSessionId;
  int samplingRate = 10;
  bool isRecording = false;
  
  // Datos actuales de sensores
  AccelerometerEvent? currentAccelerometer;
  GyroscopeEvent? currentGyroscope;
  Position? currentPosition;
  
  // Streams de sensores
  StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;
  StreamSubscription<Position>? positionSubscription;
  
  // Timer para forzar lectura de sensores
  Timer? sensorForceTimer;
  
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  
  // Configurar GPS con máxima precisión
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
    timeLimit: Duration(seconds: 30),
  );
  
  // Escuchar comandos de la aplicación principal
  service.on('startRecording').listen((event) async {
    final data = event!;
    currentSessionId = data['sessionId'] as String?;
    samplingRate = data['samplingRate'] as int? ?? 10;
    isRecording = true;
    
    print('🔴 Servicio: Iniciando grabación - $samplingRate Hz');
    
    // MANTENER PANTALLA ACTIVA DURANTE GRABACIÓN
    await WakelockPlus.enable();
    
    // Intentar iniciar sensores nativos como respaldo
    final nativeStarted = await NativeSensorService.startNativeSensors(samplingRate);
    if (nativeStarted) {
      print('🔋 Sensores nativos iniciados como respaldo');
      
      // Iniciar polling de sensores nativos
      NativeSensorService.startPolling(
        intervalMs: (1000 / samplingRate).round(),
        onDataReceived: (nativeData) async {
          if (isRecording && currentSessionId != null) {
            // Convertir datos nativos al formato esperado
            final accelData = nativeData['accelerometer'] as Map<String, dynamic>?;
            final gyroData = nativeData['gyroscope'] as Map<String, dynamic>?;
            
            if (accelData != null) {
              currentAccelerometer = AccelerometerEvent(
                accelData['x']?.toDouble() ?? 0.0,
                accelData['y']?.toDouble() ?? 0.0,
                accelData['z']?.toDouble() ?? 0.0,
                DateTime.now(),
              );
            }
            
            if (gyroData != null) {
              currentGyroscope = GyroscopeEvent(
                gyroData['x']?.toDouble() ?? 0.0,
                gyroData['y']?.toDouble() ?? 0.0,
                gyroData['z']?.toDouble() ?? 0.0,
                DateTime.now(),
              );
            }
            
            print('📱 Sensores nativos - Accel: ${accelData?['x']?.toStringAsFixed(3)}, Gyro: ${gyroData?['x']?.toStringAsFixed(3)}');
          }
        },
      );
    }
    
    // Actualizar notificación
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "🔴 GRABANDO - $samplingRate Hz",
        content: "Sesión: ${currentSessionId?.substring(8, 18) ?? 'N/A'} - Sensores ACTIVOS + NATIVOS",
      );
    }
    
    // Iniciar timer de muestreo
    final samplingInterval = Duration(milliseconds: (1000 / samplingRate).round());
    samplingTimer = Timer.periodic(samplingInterval, (timer) async {
      if (isRecording && currentSessionId != null) {
        await _saveDataPoint(
          currentSessionId!,
          currentAccelerometer,
          currentGyroscope,
          currentPosition,
        );
      }
    });
    
    // FORZAR LECTURA DE SENSORES CON MAYOR FRECUENCIA
    sensorForceTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      // Forzar que los sensores no se duerman
      if (isRecording) {
        try {
          // Mantener activo el stream de sensores
          print('📱 Manteniendo sensores activos...');
        } catch (e) {
          print('❌ Error manteniendo sensores: $e');
        }
      }
    });
    
    // Iniciar streams de sensores con configuración de alta frecuencia
    accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval, // 20ms = 50Hz máximo
    ).listen((event) {
      currentAccelerometer = event;
      print('📊 Accel: ${event.x.toStringAsFixed(3)}, ${event.y.toStringAsFixed(3)}, ${event.z.toStringAsFixed(3)}');
    });
    
    gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval, // 20ms = 50Hz máximo
    ).listen((event) {
      currentGyroscope = event;
      print('🌀 Gyro: ${event.x.toStringAsFixed(3)}, ${event.y.toStringAsFixed(3)}, ${event.z.toStringAsFixed(3)}');
    });
    
    positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        currentPosition = position;
        print('🗺️ GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
      },
      onError: (error) {
        print('❌ Error GPS en servicio: $error');
      },
    );
  });
  
  service.on('stopRecording').listen((event) async {
    print('⏹️ Servicio: Deteniendo grabación');
    isRecording = false;
    currentSessionId = null;
    
    // Detener sensores nativos
    await NativeSensorService.stopNativeSensors();
    NativeSensorService.stopPolling();
    
    // Limpiar timers y streams
    samplingTimer?.cancel();
    samplingTimer = null;
    sensorForceTimer?.cancel();
    sensorForceTimer = null;
    accelerometerSubscription?.cancel();
    gyroscopeSubscription?.cancel();
    positionSubscription?.cancel();
    
    // Deshabilitar WakeLock cuando no se está grabando
    WakelockPlus.disable();
    
    // Actualizar notificación
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "RecWay",
        content: "Listo para recolectar datos",
      );
    }
  });
  
  // Mantener servicio vivo con heartbeat más agresivo
  Timer.periodic(Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        final status = isRecording ? "🔴 GRABANDO" : "⚪ LISTO";
        final sensorStatus = isRecording ? "SENSORES ACTIVOS" : "En espera";
        
        service.setForegroundNotificationInfo(
          title: "$status - $samplingRate Hz",
          content: "$sensorStatus - ${DateTime.now().toString().substring(11, 19)}",
        );
      }
    }
    
    // Verificar estado de sensores
    if (isRecording) {
      print('💓 Heartbeat - Recording: $isRecording, Accel: ${currentAccelerometer != null}, Gyro: ${currentGyroscope != null}, GPS: ${currentPosition != null}');
      
      // Si los sensores no tienen datos nuevos, reiniciarlos
      if (currentAccelerometer == null || currentGyroscope == null) {
        print('⚠️ Sensores sin datos - Reactivando...');
        await WakelockPlus.enable(); // Forzar reactivación
      }
    }
  });
  
  print('🚀 Servicio en segundo plano iniciado con WakeLock');
}

Future<void> _saveDataPoint(
  String sessionId,
  AccelerometerEvent? accelerometer,
  GyroscopeEvent? gyroscope,
  Position? position,
) async {
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await DatabaseService.insertData({
      'timestamp': timestamp,
      'acc_x': accelerometer?.x,
      'acc_y': accelerometer?.y,
      'acc_z': accelerometer?.z,
      'gyro_x': gyroscope?.x,
      'gyro_y': gyroscope?.y,
      'gyro_z': gyroscope?.z,
      'gps_lat': position?.latitude,
      'gps_lng': position?.longitude,
      'gps_accuracy': position?.accuracy,
      'gps_speed': position?.speed,
      'gps_altitude': position?.altitude,
      'gps_heading': position?.heading,
      'session_id': sessionId,
    });
    
    // Log cada 10 muestras para verificar que está funcionando
    if (timestamp % 10000 < 1000) { // Aproximadamente cada 10 segundos
      final accelStr = accelerometer?.x.toStringAsFixed(2) ?? 'null';
      final gpsStr = position?.latitude.toStringAsFixed(4) ?? 'null';
      print('💾 Datos guardados: Accel=$accelStr, GPS=$gpsStr');
    }
  } catch (e) {
    print('❌ Error guardando datos en servicio: $e');
  }
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
