import 'dart:async';
import 'package:flutter/services.dart';

class NativeSensorService {
  static const MethodChannel _channel = MethodChannel('com.example.test1/native_sensors');
  
  static Timer? _pollingTimer;
  static bool _isListening = false;
  static Function(Map<String, dynamic>)? _onDataReceived;
  
  /// Inicia los sensores nativos con la frecuencia especificada
  static Future<bool> startNativeSensors(int samplingRate) async {
    try {
      await _channel.invokeMethod('startNativeSensors', {
        'samplingRate': samplingRate,
      });
      
      _isListening = true;
      print('🔋 Sensores nativos iniciados a ${samplingRate} Hz');
      return true;
    } catch (e) {
      print('❌ Error iniciando sensores nativos: $e');
      return false;
    }
  }
  
  /// Detiene los sensores nativos
  static Future<bool> stopNativeSensors() async {
    try {
      await _channel.invokeMethod('stopNativeSensors');
      
      _isListening = false;
      _pollingTimer?.cancel();
      _pollingTimer = null;
      
      print('⏹️ Sensores nativos detenidos');
      return true;
    } catch (e) {
      print('❌ Error deteniendo sensores nativos: $e');
      return false;
    }
  }
  
  /// Obtiene los datos actuales de los sensores nativos
  static Future<Map<String, dynamic>?> getCurrentSensorData() async {
    try {
      final result = await _channel.invokeMethod('getSensorData');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('❌ Error obteniendo datos de sensores nativos: $e');
      return null;
    }
  }
  
  /// Inicia el polling de datos de sensores nativos
  static void startPolling({
    required int intervalMs,
    required Function(Map<String, dynamic>) onDataReceived,
  }) {
    if (!_isListening) return;
    
    _onDataReceived = onDataReceived;
    
    _pollingTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      final data = await getCurrentSensorData();
      if (data != null && _onDataReceived != null) {
        _onDataReceived!(data);
      }
    });
    
    print('📊 Polling de sensores nativos iniciado cada ${intervalMs}ms');
  }
  
  /// Detiene el polling de datos
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _onDataReceived = null;
    print('⏹️ Polling de sensores nativos detenido');
  }
  
  /// Solicita ignorar optimizaciones de batería
  static Future<bool> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
      return true;
    } catch (e) {
      print('❌ Error solicitando ignorar optimizaciones de batería: $e');
      return false;
    }
  }
  
  /// Verifica si los sensores nativos están disponibles y activos
  static Future<bool> isAvailable() async {
    try {
      final data = await getCurrentSensorData();
      return data?['isActive'] == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Obtiene información de estado de los sensores
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final data = await getCurrentSensorData();
      if (data != null) {
        return {
          'isActive': data['isActive'] ?? false,
          'lastUpdate': data['timestamp'] ?? 0,
          'hasAccelerometer': data['accelerometer'] != null,
          'hasGyroscope': data['gyroscope'] != null,
        };
      }
    } catch (e) {
      print('❌ Error obteniendo estado de sensores nativos: $e');
    }
    
    return {
      'isActive': false,
      'lastUpdate': 0,
      'hasAccelerometer': false,
      'hasGyroscope': false,
    };
  }
}
