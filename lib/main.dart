import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'dart:ui';
import 'screens/splash_screen.dart';
import 'screens/emergency_error_screen.dart';
import 'services/background_service.dart';

void main() async {
  // Configurar manejo de errores globales
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Manejar errores de Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      print('🔥 Flutter Error: ${details.exception}');
      print('📍 Stack: ${details.stack}');
    };

    // Manejar errores de plataforma
    PlatformDispatcher.instance.onError = (error, stack) {
      print('🔥 Platform Error: $error');
      print('📍 Stack: $stack');
      return true;
    };
    
    print('🚀 Iniciando aplicación principal...');
    
    // Inicializar servicio en segundo plano solo una vez
    try {
      print('🔧 Verificando estado del servicio...');
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      
      if (!isRunning) {
        print('🚀 Inicializando servicio en segundo plano...');
        await initializeService();
        print('✅ Servicio en segundo plano inicializado completamente');
      } else {
        print('✅ Servicio en segundo plano ya está ejecutándose');
      }
    } catch (e) {
      print('⚠️ Error con servicio en segundo plano: $e');
      // Continuar sin el servicio si hay error
    }
    
    runApp(MyApp());
  }, (error, stack) {
    print('🔥 Zone Error: $error');
    print('📍 Stack: $stack');
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Data Collector Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Error boundary a nivel de app
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return EmergencyErrorScreen(
            errorMessage: details.exception.toString(),
            stackTrace: details.stack.toString(),
          );
        };
        return child ?? const SizedBox();
      },
    );
  }
}