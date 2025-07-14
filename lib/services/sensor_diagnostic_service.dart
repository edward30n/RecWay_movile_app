import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class SensorDiagnosticService {
  static Future<Map<String, dynamic>> testSensorValues() async {
    print('🔬 === INICIANDO PRUEBA DE VALORES DE SENSORES ===');
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'accelerometer': <String, dynamic>{},
      'gyroscope': <String, dynamic>{},
      'problems': <String>[],
      'isWorking': false,
    };
    
    try {
      // Test del acelerómetro
      print('📱 Probando acelerómetro...');
      final accelResults = await _testAccelerometer();
      results['accelerometer'] = accelResults;
      
      if (!(accelResults['isResponsive'] as bool)) {
        results['problems'].add('Acelerómetro no responde o valores constantes');
      }
      
      // Test del giroscopio
      print('🌀 Probando giroscopio...');
      final gyroResults = await _testGyroscope();
      results['gyroscope'] = gyroResults;
      
      if (!(gyroResults['isResponsive'] as bool)) {
        results['problems'].add('Giroscopio no responde o valores constantes (0.000)');
      }
      
      // Evaluar si los sensores están funcionando
      final accelWorking = accelResults['isResponsive'] as bool;
      final gyroWorking = gyroResults['isResponsive'] as bool;
      
      results['isWorking'] = accelWorking && gyroWorking;
      
      if (!results['isWorking']) {
        results['problems'].add('Uno o más sensores no están funcionando correctamente');
      }
      
      print('📊 Resultado del test: ${results['isWorking'] ? 'FUNCIONANDO' : 'PROBLEMAS DETECTADOS'}');
      
      return results;
      
    } catch (e) {
      print('❌ Error durante test de sensores: $e');
      results['error'] = e.toString();
      results['problems'].add('Error técnico durante el test de sensores');
      return results;
    }
  }

  static Future<Map<String, dynamic>> _testAccelerometer() async {
    final samples = <List<double>>[];
    bool hasVariation = false;
    
    try {
      // Escuchar el acelerómetro por 3 segundos
      final completer = Completer<void>();
      late StreamSubscription subscription;
      
      subscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (AccelerometerEvent event) {
          samples.add([event.x, event.y, event.z]);
          
          // Si tenemos al menos 10 muestras, verificar variación
          if (samples.length >= 10) {
            hasVariation = _hasSignificantVariation(samples);
          }
          
          // Si tenemos suficientes muestras o ya detectamos variación
          if (samples.length >= 30 || hasVariation) {
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        },
        onError: (error) {
          print('❌ Error en acelerómetro: $error');
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
      
      // Timeout de 3 segundos
      await Future.any([
        completer.future,
        Future.delayed(Duration(seconds: 3)),
      ]);
      
      subscription.cancel();
      
      return {
        'samplesCount': samples.length,
        'isResponsive': samples.isNotEmpty && hasVariation,
        'hasVariation': hasVariation,
        'lastValues': samples.isNotEmpty ? samples.last : null,
        'firstValues': samples.isNotEmpty ? samples.first : null,
      };
      
    } catch (e) {
      print('❌ Error testando acelerómetro: $e');
      return {
        'samplesCount': 0,
        'isResponsive': false,
        'hasVariation': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _testGyroscope() async {
    final samples = <List<double>>[];
    bool hasVariation = false;
    
    try {
      // Escuchar el giroscopio por 3 segundos
      final completer = Completer<void>();
      late StreamSubscription subscription;
      
      subscription = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (GyroscopeEvent event) {
          samples.add([event.x, event.y, event.z]);
          
          // Si tenemos al menos 10 muestras, verificar variación
          if (samples.length >= 10) {
            hasVariation = _hasSignificantVariation(samples);
          }
          
          // Si tenemos suficientes muestras o ya detectamos variación
          if (samples.length >= 30 || hasVariation) {
            subscription.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        },
        onError: (error) {
          print('❌ Error en giroscopio: $error');
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
      
      // Timeout de 3 segundos
      await Future.any([
        completer.future,
        Future.delayed(Duration(seconds: 3)),
      ]);
      
      subscription.cancel();
      
      return {
        'samplesCount': samples.length,
        'isResponsive': samples.isNotEmpty && hasVariation,
        'hasVariation': hasVariation,
        'lastValues': samples.isNotEmpty ? samples.last : null,
        'firstValues': samples.isNotEmpty ? samples.first : null,
        'allZeros': samples.isNotEmpty ? _areAllZeros(samples) : false,
      };
      
    } catch (e) {
      print('❌ Error testando giroscopio: $e');
      return {
        'samplesCount': 0,
        'isResponsive': false,
        'hasVariation': false,
        'allZeros': false,
        'error': e.toString(),
      };
    }
  }

  static bool _hasSignificantVariation(List<List<double>> samples) {
    if (samples.length < 5) return false;
    
    // Calcular la variación en cada eje
    for (int axis = 0; axis < 3; axis++) {
      final values = samples.map((sample) => sample[axis]).toList();
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      final range = max - min;
      
      // Si hay una variación significativa en cualquier eje (más de 0.1)
      if (range > 0.1) {
        return true;
      }
    }
    
    return false;
  }

  static bool _areAllZeros(List<List<double>> samples) {
    if (samples.isEmpty) return false;
    
    // Verificar si todos los valores están muy cerca de cero
    for (final sample in samples) {
      for (final value in sample) {
        if (value.abs() > 0.001) { // Tolerancia muy pequeña
          return false;
        }
      }
    }
    
    return true;
  }

  /// Diagnóstico específico para detectar el problema del giroscopio en 0.000
  static Future<Map<String, dynamic>> diagnoseGyroscopeZeros() async {
    print('🔍 === DIAGNÓSTICO ESPECÍFICO: GIROSCOPIO EN CEROS ===');
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'isGyroscopeStuckAtZero': false,
      'details': <String, dynamic>{},
      'recommendations': <String>[],
    };
    
    try {
      final gyroTest = await _testGyroscope();
      results['details'] = gyroTest;
      
      final allZeros = gyroTest['allZeros'] as bool? ?? false;
      final hasVariation = gyroTest['hasVariation'] as bool? ?? false;
      final samplesCount = gyroTest['samplesCount'] as int? ?? 0;
      
      // Diagnóstico específico
      if (samplesCount == 0) {
        results['isGyroscopeStuckAtZero'] = true;
        results['recommendations'].add('El giroscopio no está respondiendo - verificar permisos de sensores');
      } else if (allZeros && !hasVariation) {
        results['isGyroscopeStuckAtZero'] = true;
        results['recommendations'].add('El giroscopio está devolviendo solo ceros - posible problema de calibración');
        results['recommendations'].add('Reiniciar el dispositivo puede ayudar');
        results['recommendations'].add('Verificar que no hay otras apps usando el giroscopio');
      } else if (!hasVariation) {
        results['isGyroscopeStuckAtZero'] = true;
        results['recommendations'].add('El giroscopio no muestra variación - valores constantes detectados');
        results['recommendations'].add('Mover el dispositivo durante el test');
      } else {
        results['isGyroscopeStuckAtZero'] = false;
        results['recommendations'].add('El giroscopio está funcionando correctamente');
      }
      
      print(results['isGyroscopeStuckAtZero'] ? 
            '❌ PROBLEMA CONFIRMADO: Giroscopio en ceros' : 
            '✅ Giroscopio funcionando correctamente');
      
      return results;
      
    } catch (e) {
      print('❌ Error en diagnóstico de giroscopio: $e');
      results['error'] = e.toString();
      results['isGyroscopeStuckAtZero'] = true;
      results['recommendations'].add('Error técnico - verificar permisos y reiniciar app');
      return results;
    }
  }
}
