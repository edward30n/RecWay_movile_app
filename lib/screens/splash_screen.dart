import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'permission_loading_screen.dart';
import 'sensor_home_page.dart';
import 'emergency_error_screen.dart';
import '../services/permission_service.dart';
import '../services/database_service.dart';
import 'emergency_error_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String currentStep = 'Iniciando aplicación...';
  double progress = 0.0;
  Timer? _timeoutTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    
    // Timeout de seguridad - máximo 30 segundos
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!_isCompleted && mounted) {
        print('⏰ Timeout de inicialización alcanzado');
        _navigateToHome();
      }
    });
    
    _initializeApp();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _updateProgress(String step, double progressValue) {
    if (mounted) {
      setState(() {
        currentStep = step;
        progress = progressValue;
      });
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Paso 1: Verificar estado de la aplicación
      _updateProgress('Verificando estado de la aplicación...', 0.05);
      await _safeDatabaseCheck();
      await Future.delayed(const Duration(milliseconds: 300));

      _updateProgress('Iniciando aplicación...', 0.1);
      await Future.delayed(const Duration(milliseconds: 300));

      // Paso 2: Diagnóstico avanzado de sensores
      _updateProgress('Diagnosticando sensores...', 0.15);
      final diagnosis = await PermissionService.diagnoseSensorProblems();
      await Future.delayed(const Duration(milliseconds: 300));
      
      final problems = diagnosis['problems'] as List<String>;
      if (problems.isNotEmpty) {
        print('⚠️ Problemas detectados en sensores: ${problems.length}');
        for (final problem in problems) {
          print('   - $problem');
        }
        
        // Si hay problemas severos, intentar arreglo automático
        if (diagnosis['severity'] == 'severe' || diagnosis['severity'] == 'moderate') {
          _updateProgress('Intentando arreglo automático...', 0.2);
          final fixAttempted = await PermissionService.attemptAutomaticSensorFix();
          if (fixAttempted) {
            print('✅ Arreglo automático aplicado');
          } else {
            print('⚠️ Se requiere configuración manual');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Paso 3: Verificar si es la primera vez que se abre la app
      _updateProgress('Verificando configuración inicial...', 0.3);
      final isFirstLaunch = await _isFirstLaunch();
      await Future.delayed(const Duration(milliseconds: 300));

      if (isFirstLaunch) {
        print('🆕 Primera vez abriendo la app');
        await _markFirstLaunchComplete();
      } else {
        print('🔄 App ya inicializada previamente');
      }

      // Paso 4: Verificar estado de permisos existentes
      _updateProgress('Verificando permisos existentes...', 0.4);
      await _checkExistingPermissions();
      await Future.delayed(const Duration(milliseconds: 300));

      print('🔐 Iniciando solicitud de permisos paso a paso...');
      
      // Paso 5: Solicitar permisos de ubicación paso a paso (solo si no están concedidos)
      _updateProgress('Verificando permisos de ubicación...', 0.5);
      bool locationSuccess = await _handleLocationPermissions();
      await Future.delayed(const Duration(milliseconds: 500));

      if (locationSuccess) {
        print('✅ Permisos de ubicación obtenidos, continuando con otros permisos...');
        
        // Paso 6: Solicitar el resto de permisos (solo los faltantes)
        _updateProgress('Configurando permisos adicionales...', 0.7);
        await _handleAdditionalPermissions();
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        print('⚠️ Algunos permisos de ubicación no concedidos - continuando...');
      }

      // Paso 7: Verificar servicios de ubicación
      _updateProgress('Verificando servicios de ubicación...', 0.8);
      await _checkLocationServices();
      await Future.delayed(const Duration(milliseconds: 300));

      // Paso 8: Verificar permisos específicos después de la solicitud
      _updateProgress('Verificando configuración final...', 0.85);
      await _checkSpecificPermissions();
      await Future.delayed(const Duration(milliseconds: 300));

      // Paso 9: Configuración de energía (opcional)
      _updateProgress('Configurando optimización de energía...', 0.9);
      await _requestBatteryOptimizationPermission();
      await Future.delayed(const Duration(milliseconds: 300));

      // Paso 10: Diagnóstico final
      _updateProgress('Verificación final de sensores...', 0.95);
      final finalDiagnosis = await PermissionService.diagnoseSensorProblems();
      final finalProblems = finalDiagnosis['problems'] as List<String>;
      
      if (finalProblems.isNotEmpty) {
        print('⚠️ Problemas persistentes detectados: ${finalProblems.length}');
        // Si aún hay problemas críticos, mostrar pantalla de emergencia
        if (finalDiagnosis['severity'] == 'severe') {
          _showEmergencyScreen(finalProblems);
          return;
        }
      }

      // Log final del estado
      await PermissionService.checkAndLogAllPermissions();
      
      _updateProgress('¡Configuración completa!', 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ === INICIALIZACIÓN COMPLETA ===');

      _navigateToHome();

    } catch (e, stackTrace) {
      print('❌ Error durante la inicialización: $e');
      print('📍 Stack trace: $stackTrace');
      _updateProgress('Error en la configuración - Intentando recuperar...', 0.5);
      
      // Intentar recuperación básica
      await _performEmergencyRecovery();
      await Future.delayed(const Duration(seconds: 1));
      
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!_isCompleted && mounted) {
      _isCompleted = true;
      _timeoutTimer?.cancel();
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              const SensorHomePage(skipInitialization: true),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _showEmergencyScreen(List<String> problems) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EmergencyErrorScreen(
          errorMessage: 'Problemas críticos con sensores detectados:\n\n${problems.join('\n')}',
          onRetry: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SplashScreen()),
            );
          },
        ),
      ),
    );
  }

  // Funciones helper para manejo robusto de inicialización
  
  Future<void> _safeDatabaseCheck() async {
    try {
      print('🔍 Verificando estado de la base de datos...');
      
      // Verificar salud de la base de datos
      final isHealthy = await DatabaseService.isDatabaseHealthy();
      if (!isHealthy) {
        print('⚠️ Base de datos no saludable, intentando recuperar...');
      }
      
      // Limpiar sesiones abiertas de crashes anteriores
      await DatabaseService.cleanupOpenSessions();
      
      // Verificar si hubo un crash reciente
      final prefs = await SharedPreferences.getInstance();
      final lastCrash = prefs.getString('last_crash_time');
      
      if (lastCrash != null) {
        final crashTime = DateTime.tryParse(lastCrash);
        if (crashTime != null && DateTime.now().difference(crashTime).inMinutes < 5) {
          print('⚠️ Crash reciente detectado, limpiando estado...');
          await _clearCrashState();
        }
      }
      
      print('✅ Estado de base de datos verificado');
    } catch (e) {
      print('⚠️ Error verificando base de datos: $e');
      // No fallar por esto, continuar
    }
  }

  Future<void> _clearCrashState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_crash_time');
      await prefs.remove('current_session_id');
      print('🧹 Estado de crash limpiado');
    } catch (e) {
      print('⚠️ Error limpiando estado de crash: $e');
    }
  }

  Future<void> _checkExistingPermissions() async {
    try {
      print('🔍 Verificando permisos existentes...');
      
      // Verificar permisos básicos sin solicitar
      final locationWhenInUse = await Permission.locationWhenInUse.status;
      final locationAlways = await Permission.locationAlways.status;
      final storage = await Permission.storage.status;
      final notification = await Permission.notification.status;
      
      print('📍 Ubicación cuando en uso: ${locationWhenInUse.name}');
      print('📍 Ubicación siempre: ${locationAlways.name}');
      print('💾 Almacenamiento: ${storage.name}');
      print('🔔 Notificaciones: ${notification.name}');
      
    } catch (e) {
      print('⚠️ Error verificando permisos existentes: $e');
    }
  }

  Future<bool> _handleLocationPermissions() async {
    try {
      // Solo solicitar si no están concedidos
      final currentStatus = await Permission.locationWhenInUse.status;
      if (currentStatus.isGranted) {
        print('✅ Permisos de ubicación ya concedidos');
        return true;
      }
      
      print('🔐 Solicitando permisos de ubicación...');
      return await PermissionService.requestLocationPermissionsStepByStep();
    } catch (e) {
      print('⚠️ Error manejando permisos de ubicación: $e');
      return false;
    }
  }

  Future<void> _handleAdditionalPermissions() async {
    try {
      print('🔐 Verificando permisos adicionales...');
      
      // Solo solicitar permisos que no estén concedidos
      final permissions = [
        Permission.notification,
        Permission.storage,
      ];
      
      for (final permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          print('🔐 Solicitando permiso: ${permission.toString()}');
          await permission.request();
        } else {
          print('✅ Permiso ya concedido: ${permission.toString()}');
        }
      }
      
    } catch (e) {
      print('⚠️ Error manejando permisos adicionales: $e');
    }
  }

  Future<void> _checkLocationServices() async {
    try {
      print('🛰️ Verificando servicios de ubicación...');
      final locationServicesEnabled = await PermissionService.checkLocationServices();
      if (!locationServicesEnabled) {
        print('❌ Servicios de ubicación deshabilitados');
      } else {
        print('✅ Servicios de ubicación habilitados');
      }
    } catch (e) {
      print('⚠️ Error verificando servicios de ubicación: $e');
    }
  }

  Future<void> _performEmergencyRecovery() async {
    try {
      print('🚨 Iniciando recuperación de emergencia...');
      
      // Limpiar estado de preferencias problemático
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_crash_time', DateTime.now().toIso8601String());
      
      // Limpiar cualquier sesión activa
      await prefs.remove('current_session_id');
      await prefs.remove('recording_state');
      
      print('🔄 Recuperación de emergencia completada');
    } catch (e) {
      print('⚠️ Error en recuperación de emergencia: $e');
    }
  }

  Future<bool> _isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.containsKey('first_launch_completed');
    } catch (e) {
      print('⚠️ Error verificando primer lanzamiento: $e');
      return true; // Asumir que es primer lanzamiento si hay error
    }
  }

  Future<void> _markFirstLaunchComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_launch_completed', true);
    } catch (e) {
      print('⚠️ Error marcando primer lanzamiento: $e');
    }
  }

  Future<void> _checkSpecificPermissions() async {
    try {
      // Verificar ubicación "todo el tiempo"
      final hasLocationAlways = await PermissionService.hasLocationAlwaysPermission();
      if (!hasLocationAlways) {
        print('⚠️ Permiso de ubicación "todo el tiempo" no concedido');
      }

      // Verificar permisos de almacenamiento
      final hasStorage = await PermissionService.hasStoragePermission();
      if (!hasStorage) {
        print('⚠️ Permiso de almacenamiento no concedido');
      }
    } catch (e) {
      print('⚠️ Error verificando permisos específicos: $e');
    }
  }

  Future<void> _requestBatteryOptimizationPermission() async {
    try {
      // Solicitar deshabilitar optimización de batería de forma segura
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        print('🔋 Solicitando permiso de optimización de batería...');
        await Permission.ignoreBatteryOptimizations.request();
      } else {
        print('✅ Optimización de batería ya configurada');
      }
    } catch (e) {
      print('⚠️ Error solicitando permiso de optimización de batería: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionLoadingScreen(
      currentStep: currentStep,
      progress: progress,
    );
  }
}
