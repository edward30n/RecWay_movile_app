import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'screens/sensor_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Iniciando aplicación principal...');
  
  // Inicializar servicio en segundo plano después de que la app esté lista
  try {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'sensor_data_collector',
        initialNotificationTitle: 'Sensor Data Collector Pro',
        initialNotificationContent: 'Servicio activo',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    print('✅ Servicio en segundo plano inicializado');
  } catch (e) {
    print('⚠️ Error inicializando servicio: $e');
  }
  
  runApp(MyApp());
}

// Importar las funciones del servicio
@pragma('vm:entry-point')
void onStart(service) async {
  // El servicio se configurará cuando sea necesario
  print('🔧 Servicio listo para comandos');
}

@pragma('vm:entry-point')
bool onIosBackground(service) {
  return true;
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
      home: SensorHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}