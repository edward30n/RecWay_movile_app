import 'package:flutter/material.dart';
import 'screens/sensor_home_page.dart';
import 'screens/permission_loading_screen.dart';
import 'services/background_service.dart';
import 'services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando aplicación RecWay Sensores...');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecWay Sensor Data Collector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  String _currentStep = "Verificando permisos...";
  double _progress = 0.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Paso 1: Verificar permisos
      setState(() {
        _currentStep = "🔐 Verificando permisos...";
        _progress = 0.1;
      });
      
      print('🔐 Verificando permisos...');
      await PermissionService.checkAndLogAllPermissions();
      
      // Paso 2: Solicitar permisos de ubicación
      setState(() {
        _currentStep = "📍 Configurando ubicación...";
        _progress = 0.3;
      });
      
      print('📍 Verificando servicios de ubicación...');
      final locationServicesEnabled = await PermissionService.checkLocationServices();
      if (!locationServicesEnabled) {
        print('❌ Servicios de ubicación deshabilitados');
        // Mostrar diálogo pero continuar
      }
      
      print('📍 Solicitando permisos de ubicación...');
      bool locationSuccess = await PermissionService.requestLocationPermissionsStepByStep();
      
      // Paso 3: Otros permisos
      setState(() {
        _currentStep = "🔔 Configurando notificaciones...";
        _progress = 0.5;
      });
      
      if (locationSuccess) {
        print('✅ Permisos de ubicación obtenidos, continuando con otros permisos...');
        
        final allPermissionsGranted = await PermissionService.requestAllPermissions();
        print('📋 Resultado todos los permisos: $allPermissionsGranted');
      }
      
      // Paso 4: Inicializar servicio en segundo plano solo si es necesario
      setState(() {
        _currentStep = "🔄 Preparando servicio...";
        _progress = 0.7;
      });
      
      print('🔄 Configurando servicio en segundo plano...');
      try {
        await initializeService();
        print('✅ Servicio en segundo plano configurado correctamente');
      } catch (e) {
        print('⚠️ Error configurando servicio: $e');
        // Continuar de todas formas
      }
      
      // Paso 5: Finalizar
      setState(() {
        _currentStep = "✅ ¡Todo listo!";
        _progress = 1.0;
      });
      
      await Future.delayed(Duration(milliseconds: 500));
      
      // Verificar permisos finales
      await PermissionService.checkAndLogAllPermissions();
      
      print('✅ === INICIALIZACIÓN COMPLETA ===');
      
      setState(() {
        _isInitialized = true;
      });
      
    } catch (e) {
      print('❌ Error durante la inicialización: $e');
      setState(() {
        _currentStep = "❌ Error: $e";
        _progress = 0.0;
      });
      
      // Esperar un poco y luego continuar de todas formas
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return PermissionLoadingScreen(
        currentStep: _currentStep,
        progress: _progress,
        onCancel: () {
          // Si el usuario cancela, ir directamente a la app
          setState(() {
            _isInitialized = true;
          });
        },
      );
    }
    
    return SensorHomePage();
  }
}