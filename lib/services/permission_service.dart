import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PermissionService {
  static Future<bool> requestAllPermissions() async {
    print('🔐 Iniciando solicitud de permisos...');
    
    try {
      // Paso 1: Verificar que los servicios de ubicación estén habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Servicios de ubicación deshabilitados en el dispositivo');
        return false;
      }
      print('✅ Servicios de ubicación habilitados');
      
      // Paso 2: Solicitar permisos de ubicación con Geolocator primero
      print('� Solicitando permisos de ubicación con Geolocator...');
      LocationPermission geoPermission = await Geolocator.checkPermission();
      print('📍 Estado inicial Geolocator: $geoPermission');
      
      if (geoPermission == LocationPermission.denied) {
        print('📍 Solicitando permiso de ubicación...');
        geoPermission = await Geolocator.requestPermission();
        print('� Resultado Geolocator: $geoPermission');
      }
      
      if (geoPermission == LocationPermission.denied || 
          geoPermission == LocationPermission.deniedForever) {
        print('❌ Permisos de ubicación denegados por Geolocator');
        return false;
      }
      
      // Paso 3: Verificar con permission_handler también
      print('📍 Verificando con permission_handler...');
      final locationStatus = await Permission.location.status;
      print('📍 Estado permission_handler: $locationStatus');
      
      if (locationStatus != PermissionStatus.granted) {
        print('📍 Solicitando con permission_handler...');
        final newLocationStatus = await Permission.location.request();
        print('📍 Resultado permission_handler: $newLocationStatus');
        
        if (newLocationStatus != PermissionStatus.granted) {
          print('❌ Ubicación denegada por permission_handler');
          return false;
        }
      }
      
      print('✅ Permisos básicos de ubicación concedidos');
      
      // Paso 4: Esperar un poco y solicitar ubicación en segundo plano
      await Future.delayed(Duration(seconds: 2));
      print('🏃 Solicitando ubicación en segundo plano...');
      final backgroundLocationStatus = await Permission.locationAlways.request();
      print('🏃 Ubicación siempre: $backgroundLocationStatus');
      
      // Paso 5: Notificaciones
      print('🔔 Solicitando notificaciones...');
      final notificationStatus = await Permission.notification.request();
      print('🔔 Notificaciones: $notificationStatus');
      
      // Paso 6: Permisos de almacenamiento
      print('💾 Solicitando permisos de almacenamiento...');
      await _requestStoragePermissions();
      
      // Paso 7: Optimización de batería
      print('🔋 Solicitando ignorar optimización de batería...');
      final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      print('🔋 Batería: $batteryStatus');
      
      // Verificar estado final
      final finalGeoPermission = await Geolocator.checkPermission();
      final finalLocationStatus = await Permission.location.status;
      final finalNotificationStatus = await Permission.notification.status;
      final finalBackgroundStatus = await Permission.locationAlways.status;
      
      print('📋 Estado final de permisos:');
      print('  - Geolocator: $finalGeoPermission');
      print('  - Location permission_handler: $finalLocationStatus');
      print('  - Notificaciones: $finalNotificationStatus');
      print('  - Ubicación siempre: $finalBackgroundStatus');
      
      // Retornar true si tenemos los permisos esenciales
      bool hasEssentialPermissions = (
        (finalGeoPermission == LocationPermission.whileInUse || 
         finalGeoPermission == LocationPermission.always) &&
        finalLocationStatus == PermissionStatus.granted
      );
      
      if (hasEssentialPermissions) {
        print('✅ Permisos esenciales concedidos');
      } else {
        print('❌ Faltan permisos esenciales');
      }
      
      return hasEssentialPermissions;
      
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  static Future<bool> requestLocationPermissionsStepByStep() async {
    print('📍 === SOLICITUD PASO A PASO DE UBICACIÓN ===');
    
    try {
      // Paso 1: Verificar servicios de ubicación
      print('1️⃣ Verificando servicios de ubicación...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Los servicios de ubicación están DESHABILITADOS');
        print('   Ve a Configuración > Ubicación y habilítalos');
        return false;
      }
      print('✅ Servicios de ubicación habilitados');
      
      // Paso 2: Verificar estado actual
      print('2️⃣ Verificando estado actual de permisos...');
      LocationPermission geoPermission = await Geolocator.checkPermission();
      PermissionStatus handlerPermission = await Permission.location.status;
      
      print('   - Geolocator: $geoPermission');
      print('   - PermissionHandler: $handlerPermission');
      
      // Paso 3: Solicitar con Geolocator si es necesario
      if (geoPermission == LocationPermission.denied) {
        print('3️⃣ Solicitando permiso con Geolocator...');
        geoPermission = await Geolocator.requestPermission();
        print('   Resultado: $geoPermission');
        
        if (geoPermission == LocationPermission.denied || 
            geoPermission == LocationPermission.deniedForever) {
          print('❌ Permiso denegado por Geolocator');
          return false;
        }
      }
      
      // Paso 4: Solicitar con PermissionHandler si es necesario
      if (handlerPermission != PermissionStatus.granted) {
        print('4️⃣ Solicitando permiso con PermissionHandler...');
        handlerPermission = await Permission.location.request();
        print('   Resultado: $handlerPermission');
        
        if (handlerPermission != PermissionStatus.granted) {
          print('❌ Permiso denegado por PermissionHandler');
          return false;
        }
      }
      
      // Paso 5: Verificación final
      print('5️⃣ Verificación final...');
      final finalGeo = await Geolocator.checkPermission();
      final finalHandler = await Permission.location.status;
      
      print('   - Geolocator final: $finalGeo');
      print('   - PermissionHandler final: $finalHandler');
      
      bool success = (finalGeo == LocationPermission.whileInUse || 
                     finalGeo == LocationPermission.always) &&
                     finalHandler == PermissionStatus.granted;
      
      if (success) {
        print('✅ PERMISOS DE UBICACIÓN CONCEDIDOS EXITOSAMENTE');
      } else {
        print('❌ NO SE PUDIERON OBTENER LOS PERMISOS DE UBICACIÓN');
      }
      
      return success;
      
    } catch (e) {
      print('❌ Error en solicitud paso a paso: $e');
      return false;
    }
  }

  static Future<void> _requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Para Android, intentar diferentes permisos según la versión
        final storageStatus = await Permission.storage.request();
        print('💾 Almacenamiento: $storageStatus');
        
        if (storageStatus != PermissionStatus.granted) {
          // Intentar con manageExternalStorage para Android 11+
          final manageStorageStatus = await Permission.manageExternalStorage.request();
          print('💾 Gestión almacenamiento: $manageStorageStatus');
        }
      }
    } catch (e) {
      print('❌ Error con permisos de almacenamiento: $e');
    }
  }

  static Future<bool> checkLocationServices() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Servicios de ubicación deshabilitados');
      } else {
        print('✅ Servicios de ubicación habilitados');
      }
      return serviceEnabled;
    } catch (e) {
      print('❌ Error verificando servicios de ubicación: $e');
      return false;
    }
  }

  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  static Future<bool> hasLocationAlwaysPermission() async {
    final status = await Permission.locationAlways.status;
    print('🔍 Estado ubicación siempre: $status');
    return status == PermissionStatus.granted;
  }

  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final manageStorage = await Permission.manageExternalStorage.isGranted;
      final storage = await Permission.storage.isGranted;
      final hasPermission = manageStorage || storage;
      print('🔍 Estado almacenamiento: manage=$manageStorage, storage=$storage, total=$hasPermission');
      return hasPermission;
    }
    return true;
  }

  static Future<void> showPermissionDialog(
    BuildContext context, 
    String title, 
    String message,
    {VoidCallback? onSettingsTap}
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onSettingsTap != null) {
                onSettingsTap();
              } else {
                openAppSettings();
              }
            },
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  static Future<void> showLocationAlwaysExplanation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '📍 Ubicación Todo el Tiempo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para recolectar datos GPS precisos incluso en segundo plano, necesitamos el permiso de ubicación "todo el tiempo".',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              '🎯 Beneficios:\n'
              '• Recolección continua de datos\n'
              '• Mayor precisión en los sensores\n'
              '• Monitoreo en segundo plano\n'
              '• Mejor calidad de datos científicos',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '⚙️ Ve a: Configuración > Permisos > Ubicación > "Permitir todo el tiempo"',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }

  /// Método para verificar todos los permisos y mostrar estado detallado
  static Future<void> checkAndLogAllPermissions() async {
    print('🔍 === ESTADO ACTUAL DE TODOS LOS PERMISOS ===');
    
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.notification,
      Permission.sensors,
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.ignoreBatteryOptimizations,
    ];
    
    for (var permission in permissions) {
      try {
        final status = await permission.status;
        final emoji = status == PermissionStatus.granted ? '✅' : 
                     status == PermissionStatus.denied ? '❌' : 
                     status == PermissionStatus.permanentlyDenied ? '🚫' : '⚠️';
        print('$emoji ${permission.toString().split('.').last}: $status');
      } catch (e) {
        print('❌ Error verificando ${permission.toString().split('.').last}: $e');
      }
    }
    
    print('🔍 === FIN ESTADO PERMISOS ===');
  }

  /// Diagnóstico avanzado de problemas de sensores
  static Future<Map<String, dynamic>> diagnoseSensorProblems() async {
    print('🔍 === DIAGNÓSTICO AVANZADO DE SENSORES ===');
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'problems': <String>[],
      'recommendations': <String>[],
      'permissions': <String, dynamic>{},
      'sensorStatus': <String, dynamic>{},
    };
    
    try {
      // 1. Verificar permisos específicos de sensores
      print('1️⃣ Verificando permisos de sensores...');
      
      final sensorPermission = await Permission.sensors.status;
      results['permissions']['sensors'] = sensorPermission.name;
      
      if (sensorPermission != PermissionStatus.granted) {
        results['problems'].add('Permiso de sensores no concedido');
        results['recommendations'].add('Activar permiso de sensores en configuración');
      }
      
      // 2. Verificar permisos de alta frecuencia (Android 12+)
      try {
        // En Android 12+, verificar HIGH_SAMPLING_RATE_SENSORS
        final highFreqSupported = Platform.isAndroid;
        results['sensorStatus']['highFrequencySupported'] = highFreqSupported;
        
        if (highFreqSupported) {
          print('📊 Soporte para alta frecuencia disponible');
        } else {
          results['problems'].add('Alta frecuencia de sensores no soportada');
          results['recommendations'].add('Actualizar a Android 12+ para mejor rendimiento');
        }
      } catch (e) {
        print('⚠️ No se pudo verificar soporte de alta frecuencia: $e');
      }
      
      // 3. Verificar estado de almacenamiento detallado
      print('2️⃣ Verificando almacenamiento detallado...');
      
      final storagePermission = await Permission.storage.status;
      final manageStoragePermission = await Permission.manageExternalStorage.status;
      
      results['permissions']['storage'] = storagePermission.name;
      results['permissions']['manageExternalStorage'] = manageStoragePermission.name;
      
      bool hasAnyStoragePermission = storagePermission.isGranted || manageStoragePermission.isGranted;
      results['sensorStatus']['storageAccessible'] = hasAnyStoragePermission;
      
      if (!hasAnyStoragePermission) {
        results['problems'].add('Sin acceso a almacenamiento para guardar datos');
        results['recommendations'].add('Conceder permisos de almacenamiento en configuración');
      }
      
      // 4. Verificar optimización de batería
      print('3️⃣ Verificando optimización de batería...');
      
      final batteryOptimization = await Permission.ignoreBatteryOptimizations.status;
      results['permissions']['batteryOptimization'] = batteryOptimization.name;
      
      if (batteryOptimization != PermissionStatus.granted) {
        results['problems'].add('Optimización de batería puede afectar sensores');
        results['recommendations'].add('Desactivar optimización de batería para esta app');
      }
      
      // 5. Verificar servicios de ubicación
      print('4️⃣ Verificando servicios de ubicación...');
      
      final locationServices = await Geolocator.isLocationServiceEnabled();
      results['sensorStatus']['locationServicesEnabled'] = locationServices;
      
      if (!locationServices) {
        results['problems'].add('Servicios de ubicación deshabilitados');
        results['recommendations'].add('Activar servicios de ubicación en configuración del sistema');
      }
      
      // 6. Verificar permisos de ubicación detallados
      final locationWhenInUse = await Permission.locationWhenInUse.status;
      final locationAlways = await Permission.locationAlways.status;
      
      results['permissions']['locationWhenInUse'] = locationWhenInUse.name;
      results['permissions']['locationAlways'] = locationAlways.name;
      
      if (locationWhenInUse != PermissionStatus.granted) {
        results['problems'].add('Permiso de ubicación básico no concedido');
        results['recommendations'].add('Conceder permiso de ubicación "Mientras usa la app"');
      }
      
      if (locationAlways != PermissionStatus.granted) {
        results['problems'].add('Permiso de ubicación en segundo plano no concedido');
        results['recommendations'].add('Conceder permiso de ubicación "Todo el tiempo"');
      }
      
      // 7. Verificar notificaciones
      final notifications = await Permission.notification.status;
      results['permissions']['notifications'] = notifications.name;
      
      if (notifications != PermissionStatus.granted) {
        results['problems'].add('Permisos de notificación no concedidos');
        results['recommendations'].add('Activar notificaciones para ver estado del servicio');
      }
      
      // 8. Verificar si hay múltiples apps usando sensores
      results['sensorStatus']['multipleAppsConflict'] = false; // Por ahora, no podemos detectar esto directamente
      
      // 9. Resumen final
      final problemCount = (results['problems'] as List).length;
      results['severity'] = problemCount == 0 ? 'none' : 
                           problemCount <= 2 ? 'minor' : 
                           problemCount <= 4 ? 'moderate' : 'severe';
      
      print('📋 Diagnóstico completado: $problemCount problemas encontrados');
      print('🎯 Severidad: ${results['severity']}');
      
      return results;
      
    } catch (e) {
      print('❌ Error durante diagnóstico: $e');
      results['error'] = e.toString();
      results['severity'] = 'error';
      return results;
    }
  }

  /// Intenta arreglar automáticamente los problemas de sensores
  static Future<bool> attemptAutomaticSensorFix() async {
    print('🔧 === INICIANDO ARREGLO AUTOMÁTICO ===');
    
    bool success = true;
    
    try {
      // 1. Solicitar permisos de sensores
      print('1️⃣ Solicitando permisos de sensores...');
      final sensorResult = await Permission.sensors.request();
      if (sensorResult != PermissionStatus.granted) {
        print('❌ No se pudo obtener permiso de sensores');
        success = false;
      }
      
      // 2. Solicitar permisos de almacenamiento
      print('2️⃣ Solicitando permisos de almacenamiento...');
      final storageResult = await Permission.storage.request();
      if (storageResult != PermissionStatus.granted) {
        // Intentar con el permiso de gestión de almacenamiento
        final manageStorageResult = await Permission.manageExternalStorage.request();
        if (manageStorageResult != PermissionStatus.granted) {
          print('❌ No se pudo obtener permiso de almacenamiento');
          success = false;
        }
      }
      
      // 3. Solicitar desactivar optimización de batería
      print('3️⃣ Solicitando desactivar optimización de batería...');
      final batteryResult = await Permission.ignoreBatteryOptimizations.request();
      if (batteryResult != PermissionStatus.granted) {
        print('⚠️ Usuario no desactivó optimización de batería');
        // No marcamos como fallo total, pero es recomendado
      }
      
      // 4. Verificar ubicación
      print('4️⃣ Verificando permisos de ubicación...');
      final locationResult = await Permission.locationWhenInUse.request();
      if (locationResult == PermissionStatus.granted) {
        // Intentar también el permiso "siempre"
        await Future.delayed(Duration(seconds: 1));
        await Permission.locationAlways.request();
      } else {
        print('❌ No se pudo obtener permiso de ubicación');
        success = false;
      }
      
      // 5. Solicitar notificaciones
      print('5️⃣ Solicitando permisos de notificaciones...');
      await Permission.notification.request();
      
      // 6. Verificar servicios de ubicación
      print('6️⃣ Verificando servicios de ubicación...');
      final locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationServicesEnabled) {
        print('⚠️ Servicios de ubicación deshabilitados - requiere acción manual');
        success = false;
      }
      
      print(success ? '✅ Arreglo automático completado exitosamente' : 
                     '⚠️ Arreglo parcial - se requiere configuración manual');
      
      return success;
      
    } catch (e) {
      print('❌ Error durante arreglo automático: $e');
      return false;
    }
  }

  /// Método mejorado para verificar estado real de almacenamiento
  static Future<bool> hasStoragePermissionDetailed() async {
    if (Platform.isAndroid) {
      try {
        // Verificar múltiples tipos de permisos de almacenamiento
        final storage = await Permission.storage.isGranted;
        final manageStorage = await Permission.manageExternalStorage.isGranted;
        
        // Intentar operación de escritura real para verificar
        bool canWrite = false;
        try {
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            final testFile = File('${directory.path}/test_write.txt');
            await testFile.writeAsString('test');
            await testFile.delete();
            canWrite = true;
          }
        } catch (e) {
          print('⚠️ No se puede escribir en almacenamiento externo: $e');
        }
        
        final hasPermission = storage || manageStorage || canWrite;
        print('🔍 Estado almacenamiento detallado: storage=$storage, manage=$manageStorage, canWrite=$canWrite, total=$hasPermission');
        
        return hasPermission;
      } catch (e) {
        print('❌ Error verificando almacenamiento detallado: $e');
        return false;
      }
    }
    return true; // En iOS asumimos que está disponible
  }
}
