import 'package:flutter/material.dart';
import 'screens/sensor_home_page.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando aplicación principal...');
  
  // Inicializar servicio en segundo plano con la configuración completa
  try {
    await initializeService();
    print('✅ Servicio en segundo plano inicializado completamente');
  } catch (e) {
    print('⚠️ Error inicializando servicio: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecWay Sensores Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: SensorHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}