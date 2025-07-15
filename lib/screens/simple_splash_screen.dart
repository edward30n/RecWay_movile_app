import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'permission_loading_screen.dart';
import 'sensor_home_page.dart';
import '../services/database_service.dart';

class SimpleSplashScreen extends StatefulWidget {
  const SimpleSplashScreen({super.key});

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen> {
  String currentStep = 'Iniciando aplicación...';
  double progress = 0.0;
  Timer? _timeoutTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    
    // Timeout de seguridad - máximo 20 segundos
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!_isCompleted && mounted) {
        print(' de inicialización alcanzado');
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
    if (mounted && !_isCompleted) {
      setState(() {
        currentStep = step;
        progress = progressValue.clamp(0.0, 1.0);
      });
    }
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 === INICIANDO APLICACIÓN VERSIÓN SIMPLE ===');
      
      // Paso 1: Verificación básica
      _updateProgress('Verificando estado...', 0.1);
      await _basicHealthCheck();
      await Future.delayed(const Duration(milliseconds: 500));

      // Paso 2: Verificar permisos existentes
      _updateProgress('Verificando permisos...', 0.3);
      await _checkBasicPermissions();
      await Future.delayed(const Duration(milliseconds: 500));

      // Paso 3: Solicitar permisos críticos
      _updateProgress('Configurando permisos...', 0.6);
      await _requestCriticalPermissions();
      await Future.delayed(const Duration(milliseconds: 500));

      // Paso 4: Finalización
      _updateProgress('Finalizando configuración...', 0.9);
      await Future.delayed(const Duration(milliseconds: 500));

      _updateProgress('¡Listo!', 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ === INICIALIZACIÓN SIMPLE COMPLETA ===');
      _navigateToHome();

    } catch (e, stackTrace) {
      print('❌ Error durante la inicialización simple: $e');
      print('📍 Stack trace: $stackTrace');
      
      _updateProgress('Error - Continuando de forma segura...', 0.8);
      await Future.delayed(const Duration(seconds: 1));
      
      _navigateToHome();
    }
  }

  Future<void> _basicHealthCheck() async {
    try {
      // Verificar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Limpiar crash anterior si existe
      final lastCrash = prefs.getString('last_crash_time');
      if (lastCrash != null) {
        final crashTime = DateTime.tryParse(lastCrash);
        if (crashTime != null && DateTime.now().difference(crashTime).inMinutes < 5) {
          print('⚠️ Crash reciente detectado, limpiando...');
          await prefs.remove('last_crash_time');
          await prefs.remove('current_session_id');
        }
      }
      
      // Verificar base de datos básica
      await DatabaseService.isDatabaseHealthy();
      
      print('✅ Verificación básica completada');
    } catch (e) {
      print('⚠️ Error en verificación básica: $e');
      // Continuar sin fallar
    }
  }

  Future<void> _checkBasicPermissions() async {
    try {
      // Solo verificar, no solicitar aún
      final location = await Permission.locationWhenInUse.status;
      final storage = await Permission.storage.status;
      final notification = await Permission.notification.status;
      
      print('📍 Estado permisos:');
      print('  - Ubicación: ${location.name}');
      print('  - Almacenamiento: ${storage.name}');
      print('  - Notificaciones: ${notification.name}');
      
    } catch (e) {
      print('⚠️ Error verificando permisos: $e');
    }
  }

  Future<void> _requestCriticalPermissions() async {
    try {
      // Solo solicitar permisos críticos de forma segura
      final locationPermission = await Permission.locationWhenInUse.status;
      if (locationPermission.isDenied) {
        print('🔐 Solicitando permiso de ubicación...');
        await Permission.locationWhenInUse.request();
      }
      
      final storagePermission = await Permission.storage.status;
      if (storagePermission.isDenied) {
        print('🔐 Solicitando permiso de almacenamiento...');
        await Permission.storage.request();
      }
      
      print('✅ Permisos críticos procesados');
    } catch (e) {
      print('⚠️ Error solicitando permisos: $e');
      // Continuar sin fallar
    }
  }

  void _navigateToHome() {
    if (!_isCompleted && mounted) {
      _isCompleted = true;
      _timeoutTimer?.cancel();
      
      print('🏠 Navegando a la pantalla principal...');
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SensorHomePage(skipInitialization: true),
        ),
      );
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
