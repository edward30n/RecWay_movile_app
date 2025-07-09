# RecWay Sensores (iPhone)

Una aplicación Flutter para monitoreo de sensores **optimizada exclusivamente para iPhone** y testing en **Appetize.io**.

## 🍎 Enfoque: Solo iPhone
Este proyecto está configurado específicamente para iOS. Se ha eliminado el soporte para Android para simplificar el desarrollo y enfocarse en una experiencia óptima en iPhone.

## ✨ Características principales

- 📱 **Solo iPhone**: Optimizado exclusivamente para iOS
- 🧭 **Sensores avanzados**: GPS, acelerómetro, giroscopio, magnetómetro
- 🔄 **Funcionamiento en background**: Continúa monitoreando cuando la app está en segundo plano
- 📊 **Monitoreo en tiempo real**: Visualización de datos de sensores en vivo
- 🌐 **Compatible con Appetize.io**: Listo para testing en navegador web
- 🔐 **Permisos iOS completos**: Ubicación, movimiento, background refresh
- 💾 **Persistencia de datos**: Almacenamiento local de lecturas

## 🚀 Build rápido para Appetize.io

### Opción 1: Script automatizado (Windows)
```powershell
# Ejecutar script de build
.\build_iphone.ps1
```

### Opción 2: Script automatizado (macOS/Linux)
```bash
# Dar permisos y ejecutar
chmod +x build_iphone.sh
./build_iphone.sh
```

### Opción 3: Comandos manuales
```bash
# Limpiar y preparar
flutter clean
flutter pub get

# Build iOS (requiere macOS)
flutter build ios --release --no-codesign

# Crear ZIP para Appetize.io
cd build/ios/iphoneos
zip -r RecWay-Sensores-iPhone.app.zip Runner.app
```

## 📋 Configuración iOS

### Permisos configurados:
- ✅ **Location Services** - GPS y ubicación
- ✅ **Motion & Fitness** - Acelerómetro, giroscopio
- ✅ **Background App Refresh** - Funcionamiento en background
- ✅ **Background Location** - Ubicación en background
- ✅ **Background Processing** - Tareas en background

### Configuración técnica:
- **Bundle ID**: `com.recway.sensores`
- **App Name**: "RecWay Sensores"
- **Target**: iPhone (iOS 12.0+)
- **CocoaPods**: Configurado para dependencias nativas

## 🌐 Testing en Appetize.io

1. **Subir archivo**: `RecWay-Sensores-iPhone.app.zip` a https://appetize.io/upload
2. **Configurar device**: iPhone (cualquier modelo reciente)
3. **Habilitar permisos**: Location Services, Motion & Orientation
4. **Probar sensores**: Verificar GPS, acelerómetro, background

Ver guía completa: [GUIA_APPETIZE_IO_IPHONE.md](GUIA_APPETIZE_IO_IPHONE.md)

## 🏗️ Estructura del proyecto

```
lib/
├── main.dart                    # Entry point de la aplicación
├── models/                      # Modelos de datos
├── screens/
│   └── sensor_home_page.dart    # Pantalla principal con sensores
├── services/
│   ├── background_service.dart  # Servicio para funcionamiento en background
│   ├── database_service.dart    # Persistencia de datos
│   └── permission_service.dart  # Gestión de permisos iOS
├── utils/                       # Utilidades
└── widgets/
    ├── control_panel.dart       # Panel de controles
    ├── sensor_card.dart         # Tarjetas de sensores
    └── status_cards.dart        # Tarjetas de estado

ios/
├── Runner/
│   ├── Info.plist              # Configuración y permisos iOS
│   └── ...
├── Podfile                     # Dependencias CocoaPods
└── Runner.xcodeproj/           # Proyecto Xcode
```

## 🔧 Dependencias

### Flutter packages:
- `geolocator` - Servicios de ubicación GPS
- `sensors_plus` - Acelerómetro, giroscopio, magnetómetro
- `permission_handler` - Gestión de permisos
- `sqflite` - Base de datos local
- `workmanager` - Tareas en background

### iOS nativo:
- CoreLocation framework
- CoreMotion framework
- Background processing capabilities

## 📖 Documentación

- **[GUIA_APPETIZE_IO_IPHONE.md](GUIA_APPETIZE_IO_IPHONE.md)** - Guía completa para Appetize.io
- **[CONFIGURACION_iOS_COMPLETA.md](CONFIGURACION_iOS_COMPLETA.md)** - Configuración técnica iOS

## 🚦 Workflows CI/CD

### Codemagic (Principal)
- **`build-ios-appetize`**: Build automático para Appetize.io
- **`ios-debug`**: Build manual para testing local

Configurado en: `codemagic.yaml`

## ⚠️ Requisitos

### Para build local:
- **macOS** con Xcode instalado
- **Flutter SDK** (stable channel)
- **CocoaPods** instalado
- **iOS SDK** actualizado

### Para Appetize.io:
- Archivo `.app.zip` generado para iPhone (no simulator)
- Permisos configurados en Appetize.io
- Device type: iPhone

## 🐛 Troubleshooting

### Build falló:
- Verificar que estás en macOS con Xcode
- Ejecutar `flutter doctor` para verificar setup
- Limpiar con `flutter clean` y `cd ios && pod install`

### Sensores no funcionan en Appetize.io:
- Verificar que Location Services están habilitados
- Confirmar que Motion & Orientation están activos
- Revisar permisos en Device Settings

### App crashes en Appetize.io:
- Habilitar Debug Logs en Appetize.io
- Verificar que el build es para device (no simulator)
- Confirmar que Info.plist tiene todos los permisos

## 📞 Soporte

Para problemas específicos:
1. Revisar los archivos de documentación
2. Verificar logs en Appetize.io (Debug Logs enabled)
3. Probar build local en macOS primero
4. Verificar configuración en `ios/Runner/Info.plist`

---

**Nota**: Este proyecto está optimizado exclusivamente para iPhone y Appetize.io. Android ha sido removido para simplificar el desarrollo y testing.
