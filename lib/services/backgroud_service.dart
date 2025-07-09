import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  
  // Configurar notificaciones para Android
  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sensor_collector_channel',
      'Sensor Data Collector',
      description: 'Canal para notificaciones del recolector de datos',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'sensor_collector_channel',
      initialNotificationTitle: 'Sensor Data Collector',
      initialNotificationContent: 'Preparando recolección de datos...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  
  print('🔧 Servicio de segundo plano configurado para ${Platform.operatingSystem}');
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print('📱 Servicio iniciado en ${Platform.operatingSystem}');
  
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  
  // Timer específico por plataforma
  if (Platform.isAndroid) {
    // En Android actualizamos la notificación cada 5 segundos
    Timer.periodic(Duration(seconds: 5), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Recolectando Datos de Sensores",
            content: "Activo desde: ${DateTime.now().toString().substring(11, 19)}",
          );
        }
      }
    });
  } else if (Platform.isIOS) {
    // En iOS mantenemos el servicio activo de manera diferente
    Timer.periodic(Duration(seconds: 30), (timer) async {
      print('📡 Servicio iOS activo: ${DateTime.now()}');
      // Aquí podrías enviar datos a la app principal si es necesario
    });
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  print('🍎 iOS Background task ejecutándose');
  
  // En iOS, las tareas en segundo plano tienen tiempo limitado
  // Normalmente entre 30 segundos y algunos minutos
  
  // Realizar tareas críticas aquí
  try {
    // Ejemplo: guardar datos pendientes, sincronizar, etc.
    await Future.delayed(Duration(seconds: 1));
    print('✅ Tarea de segundo plano iOS completada');
    return true;
  } catch (e) {
    print('❌ Error en tarea de segundo plano iOS: $e');
    return false;
  }
}
