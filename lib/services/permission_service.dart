import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
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
}
