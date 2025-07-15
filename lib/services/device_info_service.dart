import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

class DeviceInfoService {
  static String? _cachedDeviceId;
  
  /// Genera un ID único e irrepetible para el dispositivo
  static Future<String> getUniqueDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? existingId = prefs.getString('unique_device_id');
    
    if (existingId != null) {
      _cachedDeviceId = existingId;
      return existingId;
    }

    // Generar un nuevo ID único basado en múltiples factores
    final deviceInfo = DeviceInfoPlugin();
    String uniqueString = '';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        uniqueString = '${androidInfo.id}_${androidInfo.model}_${androidInfo.manufacturer}_${androidInfo.board}_${androidInfo.hardware}_${androidInfo.fingerprint}_${androidInfo.display}_${androidInfo.device}_${androidInfo.product}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        uniqueString = '${iosInfo.identifierForVendor}_${iosInfo.model}_${iosInfo.systemName}_${iosInfo.systemVersion}_${iosInfo.name}_${iosInfo.localizedModel}';
      }
    } catch (e) {
      print('Error obteniendo info del dispositivo: $e');
    }
    
    // Agregar múltiples componentes para máxima unicidad
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final microseconds = DateTime.now().microsecondsSinceEpoch;
    final randomComponent = (timestamp * microseconds) % 999999999;
    final platformId = Platform.operatingSystem;
    
    // Incluir proceso actual y memoria disponible como factores adicionales
    final processId = Platform.resolvedExecutable.hashCode;
    
    uniqueString += '_${platformId}_${timestamp}_${microseconds}_${randomComponent}_${processId}';
    
    // Generar hash SHA-256 del string único
    final bytes = utf8.encode(uniqueString);
    final digest = sha256.convert(bytes);
    final deviceId = 'DEV_${digest.toString().substring(0, 20).toUpperCase()}';
    
    // Guardar el ID generado
    await prefs.setString('unique_device_id', deviceId);
    await prefs.setString('device_id_creation_timestamp', timestamp.toString());
    _cachedDeviceId = deviceId;
    
    print('🆔 ID único generado para dispositivo: $deviceId');
    print('🕐 Timestamp de creación: $timestamp');
    return deviceId;
  }

  /// Obtiene información completa del dispositivo
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceId = await getUniqueDeviceId();
    
    Map<String, dynamic> info = {
      'deviceId': deviceId,
      'platform': Platform.operatingSystem,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'packageName': packageInfo.packageName,
      'appName': packageInfo.appName,
    };

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info.addAll({
          'deviceModel': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'platformVersion': androidInfo.version.release,
          'buildNumber': androidInfo.version.incremental,
          'sdkInt': androidInfo.version.sdkInt,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'display': androidInfo.display,
          'fingerprint': androidInfo.fingerprint,
          'hardware': androidInfo.hardware,
          'host': androidInfo.host,
          'product': androidInfo.product,
          'tags': androidInfo.tags,
          'type': androidInfo.type,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info.addAll({
          'deviceModel': iosInfo.model,
          'manufacturer': 'Apple',
          'platformVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'identifierForVendor': iosInfo.identifierForVendor,
          'localizedModel': iosInfo.localizedModel,
          'utsname': iosInfo.utsname.toString(),
        });
      }
    } catch (e) {
      print('Error obteniendo información del dispositivo: $e');
      info.addAll({
        'deviceModel': 'Unknown',
        'manufacturer': 'Unknown',
        'platformVersion': 'Unknown',
        'isPhysicalDevice': true,
      });
    }

    // Agregar información de sensores
    final sensorInfo = await getSensorInfo();
    info.addAll(sensorInfo);

    // Agregar información de batería
    final batteryInfo = await getBatteryInfo();
    info.addAll(batteryInfo);

    return info;
  }

  /// Detecta y obtiene información de sensores disponibles
  static Future<Map<String, dynamic>> getSensorInfo() async {
    Map<String, dynamic> sensorInfo = {
      'hasAccelerometer': false,
      'accelerometerInfo': 'No disponible',
      'hasGyroscope': false,
      'gyroscopeInfo': 'No disponible',
      'hasGPS': false,
      'gpsInfo': 'No disponible',
    };

    try {
      // Verificar acelerometro
      try {
        await accelerometerEventStream().first.timeout(Duration(seconds: 3));
        sensorInfo['hasAccelerometer'] = true;
        sensorInfo['accelerometerInfo'] = 'Disponible - Frecuencia maxima: ~100Hz';
        print('✅ Acelerometro detectado: Disponible');
      } catch (e) {
        sensorInfo['hasAccelerometer'] = false;
        sensorInfo['accelerometerInfo'] = 'No disponible: ${e.toString().substring(0, 50)}...';
        print('❌ Acelerometro: No disponible - $e');
      }

      // Verificar giroscopio
      try {
        await gyroscopeEventStream().first.timeout(Duration(seconds: 3));
        sensorInfo['hasGyroscope'] = true;
        sensorInfo['gyroscopeInfo'] = 'Disponible - Frecuencia maxima: ~100Hz';
        print('✅ Giroscopio detectado: Disponible');
      } catch (e) {
        sensorInfo['hasGyroscope'] = false;
        sensorInfo['gyroscopeInfo'] = 'No disponible: ${e.toString().substring(0, 50)}...';
        print('❌ Giroscopio: No disponible - $e');
      }

      // Verificar GPS
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        LocationPermission permission = await Geolocator.checkPermission();
        
        if (serviceEnabled && (permission == LocationPermission.always || permission == LocationPermission.whileInUse)) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            )
          );
          sensorInfo['hasGPS'] = true;
          sensorInfo['gpsInfo'] = 'Disponible - Precision: ${position.accuracy.toStringAsFixed(1)}m, Provider: ${position.toString().contains('network') ? 'Network' : 'GPS'}';
          print('✅ GPS detectado: Disponible - Precision: ${position.accuracy.toStringAsFixed(1)}m');
        } else {
          sensorInfo['hasGPS'] = false;
          sensorInfo['gpsInfo'] = serviceEnabled ? 'Sin permisos de ubicacion' : 'Servicio de ubicacion deshabilitado';
          print('⚠️ GPS: ${sensorInfo['gpsInfo']}');
        }
      } catch (e) {
        sensorInfo['hasGPS'] = false;
        sensorInfo['gpsInfo'] = 'Error verificando GPS: ${e.toString().substring(0, 50)}...';
        print('❌ GPS: Error - $e');
      }
      
    } catch (e) {
      print('❌ Error general verificando sensores: $e');
    }

    return sensorInfo;
  }

  /// Obtiene información de batería del dispositivo
  static Future<Map<String, dynamic>> getBatteryInfo() async {
    Map<String, dynamic> batteryInfo = {
      'batteryInfo': 'No disponible',
    };

    try {
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      final batteryState = await battery.batteryState;
      
      String stateText = '';
      switch (batteryState) {
        case BatteryState.charging:
          stateText = 'Cargando';
          break;
        case BatteryState.discharging:
          stateText = 'Descargando';
          break;
        case BatteryState.full:
          stateText = 'Completa';
          break;
        case BatteryState.connectedNotCharging:
          stateText = 'Conectada sin cargar';
          break;
        default:
          stateText = 'Desconocido';
      }
      
      batteryInfo['batteryInfo'] = 'Nivel: ${batteryLevel}% - Estado: $stateText';
      print('🔋 Battery info: ${batteryInfo['batteryInfo']}');
    } catch (e) {
      batteryInfo['batteryInfo'] = 'Error obteniendo bateria: ${e.toString().substring(0, 30)}...';
      print('❌ Error obteniendo battery info: $e');
    }

    return batteryInfo;
  }

  /// Genera metadatos para exportación
  static Future<Map<String, dynamic>> getExportMetadata(String sessionId, int totalSamples) async {
    final deviceInfo = await getDeviceInfo();
    final exportTimestamp = DateTime.now().toIso8601String();
    
    return {
      'deviceId': deviceInfo['deviceId'],
      'sessionId': sessionId,
      'platform': deviceInfo['platform'],
      'deviceModel': deviceInfo['deviceModel'],
      'manufacturer': deviceInfo['manufacturer'],
      'platformVersion': deviceInfo['platformVersion'],
      'isPhysicalDevice': deviceInfo['isPhysicalDevice'],
      'appVersion': deviceInfo['appVersion'],
      'totalSamples': totalSamples,
      'exportTimestamp': exportTimestamp,
      'buildNumber': deviceInfo['buildNumber'],
      'packageName': deviceInfo['packageName'],
      'appName': deviceInfo['appName'],
      // Información de sensores
      'hasAccelerometer': deviceInfo['hasAccelerometer'],
      'accelerometerInfo': deviceInfo['accelerometerInfo'],
      'hasGyroscope': deviceInfo['hasGyroscope'],
      'gyroscopeInfo': deviceInfo['gyroscopeInfo'],
      'hasGPS': deviceInfo['hasGPS'],
      'gpsInfo': deviceInfo['gpsInfo'],
      // Información de batería
      'batteryInfo': deviceInfo['batteryInfo'],
    };
  }

  /// Genera el header CSV con metadatos
  static String generateCsvHeader(Map<String, dynamic> metadata) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ================================================');
    buffer.writeln('# RECWAY SENSOR DATA EXPORT - METADATA COMPLETO');
    buffer.writeln('# ================================================');
    buffer.writeln('# Device ID: ${metadata['deviceId']}');
    buffer.writeln('# Session ID: ${metadata['sessionId']}');
    buffer.writeln('# Platform: ${metadata['platform']}');
    buffer.writeln('# Device Model: ${metadata['deviceModel']}');
    buffer.writeln('# Manufacturer: ${metadata['manufacturer']}');
    buffer.writeln('# Brand: ${metadata['manufacturer']}');
    buffer.writeln('# OS Version: ${metadata['platformVersion']}');
    buffer.writeln('# App Version: ${metadata['appVersion']} (${metadata['buildNumber']})');
    buffer.writeln('# Company: RecWay');
    buffer.writeln('# Android ID: ${metadata['deviceId']}');
    buffer.writeln('# Battery Info: ${metadata['batteryInfo']}');
    buffer.writeln('#');
    buffer.writeln('# === INFORMACION DE SENSORES ===');
    buffer.writeln('# Accelerometer Available: ${metadata['hasAccelerometer']}');
    buffer.writeln('# Accelerometer Info: ${metadata['accelerometerInfo']}');
    buffer.writeln('# Gyroscope Available: ${metadata['hasGyroscope']}');
    buffer.writeln('# Gyroscope Info: ${metadata['gyroscopeInfo']}');
    buffer.writeln('# GPS Available: ${metadata['hasGPS']}');
    buffer.writeln('# GPS Info: ${metadata['gpsInfo']}');
    buffer.writeln('#');
    buffer.writeln('# === INFORMACION DE GRABACION ===');
    buffer.writeln('# Export Date: ${metadata['exportTimestamp']}');
    buffer.writeln('# Total Records: ${metadata['totalSamples']}');
    buffer.writeln('#');
    buffer.writeln('# DATOS DE SENSORES');
    buffer.writeln('timestamp,acc_x,acc_y,acc_z,gyro_x,gyro_y,gyro_z,gps_lat,gps_lng,gps_accuracy,gps_speed,gps_altitude,gps_heading,session_id');
    
    return buffer.toString();
  }

  /// Genera archivo JSON con metadatos y datos
  static Map<String, dynamic> generateJsonExport(
    Map<String, dynamic> metadata,
    List<Map<String, dynamic>> sensorData,
  ) {
    return {
      'metadata': metadata,
      'data': sensorData,
      'exportInfo': {
        'format': 'json',
        'version': '1.0',
        'generatedBy': 'RecWay Sensor Collector',
      }
    };
  }
}
