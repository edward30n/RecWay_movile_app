import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'dart:ui';
import 'screens/simple_splash_screen.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';

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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecWay Pro',
      theme: AppTheme.darkTheme,
      home: AppWidgets.gradientBackground(
        child: SimpleSplashScreen(),
      ),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Error boundary a nivel de app - versión simplificada con tema
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            backgroundColor: AppColors.primaryDark,
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: AppWidgets.gradientCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline, 
                          size: AppDimensions.iconXL + 16, 
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          'Error en la aplicación',
                          style: AppTextStyles.headline2.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        Text(
                          'Por favor, reinicia la aplicación',
                          style: AppTextStyles.body1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox();
      },
    );
  }
}