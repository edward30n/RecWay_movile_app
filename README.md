# RecWay Pro - Aplicación de Recolección de Datos de Sensores

## 📋 Descripción General

RecWay Pro es una aplicación profesional desarrollada en Flutter para la recolección avanzada de datos de sensores móviles. Está diseñada para capturar, almacenar y exportar información detallada de sensores como acelerómetro, giroscopio, GPS y datos del dispositivo, con capacidades de ejecución en segundo plano persistente.

## 🚀 Características Principales

- **Recolección de datos en tiempo real**: Sensores de acelerómetro, giroscopio y GPS
- **Servicio en segundo plano robusto**: Continúa la recolección incluso con pantalla bloqueada
- **Exportación CSV avanzada**: Incluye metadatos completos del dispositivo y sensores
- **Identificación única de dispositivos**: Sistema SHA-256 para generar IDs únicos
- **Información de batería en tiempo real**: Nivel y estado de carga
- **Base de datos SQLite optimizada**: Almacenamiento eficiente con índices
- **Interfaz moderna**: Diseño con gradientes y animaciones profesionales
- **Manejo robusto de errores**: Sistema completo de captura y recuperación de errores

## 🏗️ Arquitectura del Proyecto

### Estructura de Directorios

```
lib/
├── main.dart                    # Punto de entrada principal
├── screens/                     # Pantallas de la aplicación
│   ├── simple_splash_screen.dart
│   ├── permission_loading_screen.dart
│   └── sensor_home_page.dart
├── services/                    # Servicios de negocio
│   ├── background_service.dart
│   ├── database_service.dart
│   ├── device_info_service.dart
│   ├── native_sensor_service.dart
│   ├── permission_service.dart
│   └── sensor_diagnostic_service.dart
├── widgets/                     # Componentes reutilizables
│   ├── control_panel.dart
│   ├── sensor_card.dart
│   └── status_cards.dart
└── theme/                       # Configuración de temas
    └── app_theme.dart
```

## 📱 Pantallas (Screens)

### 1. SimpleSplashScreen (`simple_splash_screen.dart`)
**Propósito**: Pantalla de bienvenida con carga inicial de la aplicación

**Funcionalidades**:
- Animación de entrada con logo y gradientes
- Verificación inicial de permisos del sistema
- Transición automática a pantalla de permisos
- Manejo de errores durante inicialización

**Componentes clave**:
- Gradiente de fondo animado
- Logo centrado con efectos visuales
- Barra de progreso de carga
- Validación de servicios requeridos

### 2. PermissionLoadingScreen (`permission_loading_screen.dart`)
**Propósito**: Gestión y solicitud de permisos necesarios para sensores

**Funcionalidades**:
- Solicitud automática de permisos de ubicación
- Verificación de permisos de sensores
- Validación de disponibilidad de hardware
- Pantalla de carga durante verificaciones
- Transición a pantalla principal una vez completado

**Permisos gestionados**:
- Ubicación (GPS) precisa y aproximada
- Sensores de movimiento (acelerómetro, giroscopio)
- Ejecución en segundo plano
- Notificaciones para servicio foreground

### 3. SensorHomePage (`sensor_home_page.dart`)
**Propósito**: Pantalla principal de recolección y visualización de datos

**Funcionalidades principales**:
- **Panel de control**: Inicio/parada de recolección de datos
- **Visualización en tiempo real**: Datos de sensores actualizados constantemente
- **Tarjetas de estado**: Información del servicio en segundo plano y base de datos
- **Exportación CSV**: Generación de archivos con metadatos completos
- **Información del dispositivo**: Carga y visualización de datos del hardware

**Componentes de interfaz**:
- `ControlPanel`: Botones de control principal
- `SensorCard`: Visualización de datos de sensores individuales
- `StatusCards`: Estado de servicios y almacenamiento
- Gradientes y animaciones profesionales

**Gestión de estados**:
- Control de recolección activa/inactiva
- Actualización automática de contadores de registros
- Sincronización con servicio en segundo plano
- Manejo de errores en tiempo real

## 🔧 Servicios (Services)

### 1. BackgroundService (`background_service.dart`)
**Propósito**: Servicio foreground para recolección continua de datos

**Características técnicas**:
- **Tipo**: Servicio foreground con notificación persistente
- **Frecuencia**: Heartbeat cada 3 segundos
- **Configuración**: Android con tipo `location` para GPS
- **Persistencia**: Continúa funcionando con pantalla bloqueada

**Funcionalidades**:
- Recolección automática de datos de sensores
- Inserción directa en base de datos SQLite
- Notificación de estado visible al usuario
- Manejo robusto de errores y reconexión automática
- Sistema de logs para debugging

**Configuración de notificaciones**:
- Canal: "background_service"
- Prioridad: Alta para mantener persistencia
- Icono y texto informativos
- Prevención de eliminación por sistema

### 2. DatabaseService (`database_service.dart`)
**Propósito**: Gestión completa de base de datos SQLite

**Esquema de base de datos**:
```sql
CREATE TABLE sensor_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp REAL NOT NULL,
  accel_x REAL, accel_y REAL, accel_z REAL,
  gyro_x REAL, gyro_y REAL, gyro_z REAL,
  gps_lat REAL, gps_lon REAL, gps_accuracy REAL,
  gps_altitude REAL, gps_speed REAL, gps_heading REAL
);

CREATE INDEX idx_timestamp ON sensor_data(timestamp);
CREATE INDEX idx_gps_coords ON sensor_data(gps_lat, gps_lon);
```

**Funcionalidades**:
- **Inserción optimizada**: Preparación de statements para rendimiento
- **Consultas eficientes**: Índices optimizados para exportación
- **Limpieza de datos**: Métodos para gestión de almacenamiento
- **Estadísticas**: Conteo de registros y métricas de uso
- **Transacciones**: Operaciones atómicas para consistencia

**Métodos principales**:
- `insertSensorData()`: Inserción individual de registros
- `getAllSensorData()`: Recuperación completa para exportación
- `getRecordCount()`: Estadísticas de base de datos
- `clearData()`: Limpieza de datos históricos

### 3. DeviceInfoService (`device_info_service.dart`)
**Propósito**: Recolección completa de metadatos del dispositivo y sensores

**Información del dispositivo**:
- **Identificación única**: ID generado con SHA-256
- **Hardware**: Modelo, fabricante, versión del sistema
- **Batería**: Nivel y estado de carga en tiempo real
- **Sensores**: Disponibilidad y capacidades

**Métodos principales**:
```dart
// Generación de ID único del dispositivo
Future<String> getUniqueDeviceId()

// Información completa del dispositivo
Future<Map<String, dynamic>> getDeviceInfo()

// Estado de sensores disponibles
Future<Map<String, dynamic>> getSensorInfo()

// Información de batería en tiempo real
Future<Map<String, dynamic>> getBatteryInfo()

// Metadatos para exportación CSV
Future<Map<String, dynamic>> getExportMetadata()

// Generación de headers CSV con metadatos
String generateCsvHeader()
```

**Características de exportación**:
- Headers CSV con metadatos completos sin caracteres especiales
- Información de timestamp de exportación
- Datos de identificación únicos para cada dispositivo
- Estado de sensores y batería al momento de exportación

### 4. NativeSensorService (`native_sensor_service.dart`)
**Propósito**: Interfaz de bajo nivel con sensores nativos del dispositivo

**Sensores gestionados**:
- **Acelerómetro**: Datos de aceleración en 3 ejes (X, Y, Z)
- **Giroscopio**: Datos de rotación angular en 3 ejes
- **GPS**: Coordenadas, precisión, altitud, velocidad, rumbo

**Funcionalidades**:
- Inicialización y configuración de sensores
- Streams de datos en tiempo real
- Validación de disponibilidad de hardware
- Manejo de errores específicos por sensor
- Optimización de frecuencia de muestreo

**Configuración GPS**:
- Precisión: `LocationAccuracy.bestForNavigation`
- Frecuencia: Actualización continua
- Timeout: 30 segundos para primera lectura
- Filtros: Precisión mínima configurable

### 5. PermissionService (`permission_service.dart`)
**Propósito**: Gestión centralizada de permisos del sistema

**Permisos gestionados**:
- Ubicación precisa (`ACCESS_FINE_LOCATION`)
- Ubicación aproximada (`ACCESS_COARSE_LOCATION`)
- Ejecución en segundo plano (`BACKGROUND_LOCATION`)
- Sensores de movimiento (automático en Android)
- Notificaciones para servicio foreground

**Funcionalidades**:
- Verificación de estado de permisos
- Solicitud automática con explicaciones
- Manejo de denegaciones y redirección a configuración
- Validación continua durante ejecución
- Logs detallados para debugging

### 6. SensorDiagnosticService (`sensor_diagnostic_service.dart`)
**Propósito**: Diagnóstico y validación de sensores del dispositivo

**Funcionalidades de diagnóstico**:
- Detección de sensores disponibles en hardware
- Pruebas de conectividad y funcionamiento
- Validación de permisos específicos por sensor
- Generación de reportes de estado
- Identificación de problemas comunes

**Información proporcionada**:
- Estado de cada sensor (disponible/no disponible)
- Razones de fallas (permisos, hardware, etc.)
- Recomendaciones para resolución de problemas
- Métricas de rendimiento y precisión

## 🎨 Widgets y Componentes

### 1. ControlPanel (`control_panel.dart`)
**Propósito**: Panel central de control para inicio/parada de recolección

**Características**:
- Botón principal con estados visuales claros
- Indicadores de estado activo/inactivo
- Animaciones de transición suaves
- Integración con servicio en segundo plano
- Feedback visual al usuario

### 2. SensorCard (`sensor_card.dart`)
**Propósito**: Tarjetas individuales para visualización de datos de sensores

**Funcionalidades**:
- Visualización en tiempo real de valores de sensores
- Formato numérico con precisión configurable
- Indicadores visuales de estado (activo/inactivo)
- Diseño responsivo y moderno
- Colores diferenciados por tipo de sensor

**Tipos de tarjetas**:
- Acelerómetro (X, Y, Z)
- Giroscopio (X, Y, Z)
- GPS (latitud, longitud, precisión)
- Información adicional (altitud, velocidad, rumbo)

### 3. StatusCards (`status_cards.dart`)
**Propósito**: Tarjetas de estado para servicios y almacenamiento

**Información mostrada**:
- Estado del servicio en segundo plano
- Contador de registros en base de datos
- Estado de permisos importantes
- Información de dispositivo básica
- Métricas de rendimiento

## 🎨 Sistema de Temas

### AppTheme (`app_theme.dart`)
**Propósito**: Configuración centralizada de diseño y estilos

**Características del tema**:
- **Modo oscuro** como tema principal
- **Gradientes profesionales** en toda la aplicación
- **Paleta de colores** coherente y moderna
- **Tipografías** optimizadas para legibilidad
- **Dimensiones** estandarizadas para consistencia

**Colores principales**:
```dart
class AppColors {
  static const primaryDark = Color(0xFF1A1A2E);
  static const secondaryDark = Color(0xFF16213E);
  static const accent = Color(0xFF0F3460);
  static const highlight = Color(0xFF53A6F7);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFF44336);
  static const warning = Color(0xFFFF9800);
}
```

**Componentes de tema**:
- Gradientes de fondo
- Estilos de tarjetas con elevación
- Botones con estados visuales
- Indicadores de progreso
- Iconografía consistente

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter: sdk
  sensors_plus: ^6.1.1              # Sensores avanzados
  geolocator: ^14.0.2               # GPS de alta precisión
  flutter_background_service: ^5.0.5 # Servicio en segundo plano
  sqflite: ^2.3.3                   # Base de datos SQLite
  path_provider: ^2.1.4             # Gestión de rutas
  permission_handler: ^11.3.1        # Manejo de permisos
  device_info_plus: ^10.1.2         # Información del dispositivo
  battery_plus: ^6.0.2              # Estado de batería
  share_plus: ^10.0.2               # Compartir archivos
  flutter_local_notifications: ^18.0.1 # Notificaciones locales
  package_info_plus: ^8.0.2         # Información de la app
  crypto: ^3.0.5                    # Funciones criptográficas
```

## 🚀 Instalación y Configuración

### Prerrequisitos
- Flutter SDK >=3.10.0
- Dart SDK >=3.4.0
- Android SDK con API level 21+
- Dispositivo físico (recomendado para sensores)

### Pasos de instalación
1. **Clonar el repositorio**:
   ```bash
   git clone [repository-url]
   cd beforeMerch
   ```

2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

3. **Configurar permisos Android** (android/app/src/main/AndroidManifest.xml):
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
   <uses-permission android:name="android.permission.WAKE_LOCK" />
   ```

4. **Compilar y ejecutar**:
   ```bash
   flutter run --release
   ```

## 📊 Formato de Datos Exportados

### Estructura CSV
Los archivos CSV exportados incluyen:

**Headers con metadatos**:
- Información del dispositivo y ID único
- Estado de sensores disponibles
- Información de batería al momento de exportación
- Timestamp de generación

**Datos por registro**:
- Timestamp (epoch en milisegundos)
- Acelerómetro: accel_x, accel_y, accel_z
- Giroscopio: gyro_x, gyro_y, gyro_z
- GPS: latitud, longitud, precisión, altitud, velocidad, rumbo

### Ejemplo de archivo generado
```
=== INFORMACION DEL DISPOSITIVO ===
ID Unico: empresa_abc123def456789...
Modelo: Samsung Galaxy S21
Fabricante: Samsung
Version Android: 13
=== INFORMACION DE SENSORES ===
Acelerometro: Disponible
Giroscopo: Disponible
GPS: Disponible
=== INFORMACION DE BATERIA ===
Nivel: 85% - Estado: Descargando
=== DATOS DE SENSORES ===
timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,gps_lat,gps_lon,gps_accuracy,gps_altitude,gps_speed,gps_heading
1703123456789,0.123,-0.456,9.789,0.001,-0.002,0.003,40.7128,-74.0060,5.0,10.5,0.0,0.0
```

## 🔧 Configuración Avanzada

### Servicio en Segundo Plano
El servicio está configurado para:
- Ejecutarse como servicio foreground
- Frecuencia de 3 segundos entre mediciones
- Notificación persistente para evitar terminación
- Reinicio automático en caso de fallas

### Base de Datos
Configuración optimizada con:
- Índices en timestamp y coordenadas GPS
- Statements preparados para inserción rápida
- Transacciones para consistencia
- Limpieza automática configurable

### Precisión GPS
Configuración para máxima precisión:
- `LocationAccuracy.bestForNavigation`
- Sin filtrado de precisión mínima
- Preservación de decimales completos
- Captura de todos los parámetros GPS disponibles

## 🐛 Manejo de Errores

### Sistema de Logs
- Logs detallados en consola durante desarrollo
- Captura de errores de Flutter y plataforma
- Manejo de fallos en servicios críticos
- Recuperación automática cuando es posible

### Errores Comunes y Soluciones

1. **Permisos denegados**:
   - Redirección automática a configuración del sistema
   - Explicaciones claras al usuario
   - Verificación continua de estado

2. **Sensores no disponibles**:
   - Detección automática de hardware
   - Funcionamiento parcial sin sensores específicos
   - Mensajes informativos al usuario

3. **Problemas de GPS**:
   - Timeout configurable para primera lectura
   - Funcionamiento sin GPS si no está disponible
   - Indicadores visuales de estado

## 📈 Rendimiento y Optimización

### Características de rendimiento:
- Base de datos optimizada con índices
- Frecuencia de muestreo configurable
- Gestión eficiente de memoria
- Prevención de memory leaks en streams
- Optimización de operaciones en segundo plano

### Métricas monitoreadas:
- Frecuencia de inserción en base de datos
- Uso de memoria durante recolección prolongada
- Precisión y estabilidad de sensores
- Duración de batería con servicio activo

## 🔒 Privacidad y Seguridad

### Manejo de datos:
- Almacenamiento local únicamente
- ID de dispositivo hasheado (SHA-256)
- Sin transmisión de datos a servidores externos
- Control total del usuario sobre exportación

### Permisos mínimos:
- Solo permisos necesarios para funcionalidad
- Explicaciones claras de uso de permisos
- Respeto de configuraciones de privacidad del usuario

## 🚀 Desarrollo y Contribución

### Estructura para desarrollo:
- Código modular y bien documentado
- Separación clara de responsabilidades
- Servicios independientes y reutilizables
- Arquitectura escalable para nuevas funcionalidades

### Posibles mejoras futuras:
- Integración de más tipos de sensores
- Configuración de frecuencias de muestreo
- Filtros y procesamiento de datos en tiempo real
- Exportación a formatos adicionales
- Sincronización con servicios en la nube (opcional)

---

## 📞 Información de Contacto

Para más información sobre la aplicación RecWay Pro o para reportar problemas, consulte la documentación adicional en el repositorio del proyecto.

**Versión**: 2.0.0+1  
**Última actualización**: Diciembre 2024  
**Plataforma**: Android (Flutter)  
**Licencia**: [Especificar licencia según sea necesario]
