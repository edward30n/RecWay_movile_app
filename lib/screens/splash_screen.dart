import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permission_loading_screen.dart';
import 'sensor_home_page.dart';
import '../services/permission_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String currentStep = 'Iniciando aplicación...';
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
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
      _updateProgress('Iniciando aplicación...', 0.1);
      await Future.delayed(const Duration(milliseconds: 500));

      // Verificar si es la primera vez que se abre la app
      _updateProgress('Verificando configuración inicial...', 0.2);
      final isFirstLaunch = await _isFirstLaunch();
      await Future.delayed(const Duration(milliseconds: 300));

      if (isFirstLaunch) {
        print('🆕 Primera vez abriendo la app');
        await _markFirstLaunchComplete();
      }

      print('🔐 Iniciando solicitud de permisos paso a paso...');
      
      // Solicitar permisos de ubicación paso a paso
      _updateProgress('Solicitando permisos de ubicación...', 0.3);
      bool locationSuccess = await PermissionService.requestLocationPermissionsStepByStep();
      await Future.delayed(const Duration(milliseconds: 500));

      if (locationSuccess) {
        print('✅ Permisos de ubicación obtenidos, continuando con otros permisos...');
        
        // Solicitar el resto de permisos
        _updateProgress('Configurando permisos adicionales...', 0.5);
        final allPermissionsGranted = await PermissionService.requestAllPermissions();
        print('📋 Resultado todos los permisos: $allPermissionsGranted');
        await Future.delayed(const Duration(milliseconds: 500));

        if (!allPermissionsGranted) {
          print('⚠️ Algunos permisos adicionales no fueron concedidos');
        }
      } else {
        print('❌ No se pudieron obtener permisos de ubicación - funcionalidad limitada');
      }

      print('🛰️ Verificando servicios de ubicación...');
      _updateProgress('Verificando servicios de ubicación...', 0.7);
      final locationServicesEnabled = await PermissionService.checkLocationServices();
      if (!locationServicesEnabled) {
        print('❌ Servicios de ubicación deshabilitados');
      } else {
        print('✅ Servicios de ubicación habilitados');
      }
      await Future.delayed(const Duration(milliseconds: 500));

      // Verificar permisos específicos después de la solicitud
      _updateProgress('Verificando permisos específicos...', 0.8);
      await _checkSpecificPermissions();
      await Future.delayed(const Duration(milliseconds: 500));

      // Solicitar deshabilitar optimización de batería
      _updateProgress('Configurando optimización de energía...', 0.9);
      await _requestBatteryOptimizationPermission();
      await Future.delayed(const Duration(milliseconds: 500));

      // Log final del estado
      await PermissionService.checkAndLogAllPermissions();
      
      _updateProgress('¡Configuración completa!', 1.0);
      await Future.delayed(const Duration(milliseconds: 800));

      print('✅ === INICIALIZACIÓN COMPLETA ===');

      // Navegar a la pantalla principal
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SensorHomePage(skipInitialization: true),
          ),
        );
      }

    } catch (e) {
      print('❌ Error durante la inicialización: $e');
      _updateProgress('Error en la configuración', 1.0);
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SensorHomePage(skipInitialization: true),
          ),
        );
      }
    }
  }

  Future<bool> _isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey('first_launch_completed');
  }

  Future<void> _markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch_completed', true);
  }

  Future<void> _checkSpecificPermissions() async {
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
  }

  Future<void> _requestBatteryOptimizationPermission() async {
    try {
      // Solicitar deshabilitar optimización de batería
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
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
