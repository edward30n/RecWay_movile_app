import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

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

    return info;
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
    };
  }

  /// Genera el header CSV con metadatos
  static String generateCsvHeader(Map<String, dynamic> metadata) {
    final buffer = StringBuffer();
    
    buffer.writeln('# METADATA DEL DISPOSITIVO');
    buffer.writeln('# Device ID,${metadata['deviceId']}');
    buffer.writeln('# Session ID,${metadata['sessionId']}');
    buffer.writeln('# Platform,${metadata['platform']}');
    buffer.writeln('# Device Model,${metadata['deviceModel']}');
    buffer.writeln('# Manufacturer,${metadata['manufacturer']}');
    buffer.writeln('# Platform Version,${metadata['platformVersion']}');
    buffer.writeln('# Is Physical Device,${metadata['isPhysicalDevice']}');
    buffer.writeln('# App Version,${metadata['appVersion']}');
    buffer.writeln('# Total Samples,${metadata['totalSamples']}');
    buffer.writeln('# Export Timestamp,${metadata['exportTimestamp']}');
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
