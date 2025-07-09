# Guía Appetize.io: RecWay Sensores (iPhone únicamente)

## 🍎 ENFOQUE: Solo iPhone
Este proyecto está configurado exclusivamente para iPhone. Se ha eliminado todo el soporte para Android para simplificar el desarrollo y testing.

## ¿Qué es Appetize.io?
Appetize.io es una plataforma que permite ejecutar aplicaciones iOS en el navegador web sin necesidad de un iPhone físico. Perfecto para demos, testing y presentaciones.

## 📋 Checklist pre-build (iPhone)

### ✅ Configuración verificada:
- Bundle ID: `com.recway.sensores`
- Permisos configurados en `ios/Runner/Info.plist`
- CocoaPods configurado (`ios/Podfile`)
- Background modes habilitados para sensores
- Build target: iPhone device (NO simulator)
- App name: "RecWay Sensores"

### 📁 Archivos críticos:
- `ios/Runner/Info.plist` - Permisos iOS y configuración
- `ios/Podfile` - Dependencias nativas
- `codemagic.yaml` - Pipeline de build (solo iOS)

## 🚀 Build para Appetize.io

### Opción 1: Codemagic (Recomendado)
El workflow `build-ios-appetize` se ejecuta automáticamente al hacer push a `main` o manualmente desde el dashboard de Codemagic.

**Artifacts generados:**
- `RecWay-Sensores-iPhone.app.zip` - Listo para Appetize.io

### Opción 2: Build local
```powershell
# Limpiar proyecto
flutter clean
flutter pub get

# Instalar dependencias iOS
cd ios
pod install
cd ..

# Build iOS para iPhone (no simulator)
flutter build ios --release --no-codesign

# Crear ZIP para Appetize.io
cd build/ios/iphoneos
Compress-Archive -Path Runner.app -DestinationPath RecWay-Sensores-iPhone.app.zip
```

## 📱 Subir a Appetize.io

### 1. Acceso
Ir a: **https://appetize.io/upload**

### 2. Configurar upload
- **Plataforma**: iOS
- **Archivo**: `RecWay-Sensores-iPhone.app.zip`
- **Device**: iPhone (cualquier modelo reciente: iPhone 12, 13, 14, 15)

### 3. Configuración recomendada
```
iOS Version: 16.0+ (última estable)
Device Scale: 75% (mejor visualización)
Orientation: Portrait
Session Timeout: 30 minutes
```

### 4. Configuraciones avanzadas (IMPORTANTES para sensores)
```
✅ Debug Logs: Enabled
✅ Network Traffic: Enabled  
✅ Audio: Enabled
✅ Location Services: ENABLED (CRÍTICO)
✅ Motion & Orientation: ENABLED (CRÍTICO)
✅ Background App Refresh: ENABLED
✅ Push Notifications: Enabled
✅ Camera: Enabled (si se usa)
✅ Microphone: Enabled (si se usa)
```

## 🔧 Configuraciones específicas para sensores

### Permisos que la app solicitará:
1. **Location Services** - Para GPS y ubicación
2. **Motion & Fitness** - Para acelerómetro y giroscopio  
3. **Background App Refresh** - Para funcionamiento en background
4. **Notifications** - Para alertas de la app

### Simulación en Appetize.io:
- **GPS**: Cambiar ubicación desde Device > Location
- **Orientation**: Rotar device con controles
- **Background**: Usar Home button para simular background
- **Network**: Simular diferentes condiciones de red

## 🧪 Testing paso a paso

### 1. Primera ejecución:
1. Abrir app en Appetize.io
2. **IMPORTANTE**: Otorgar TODOS los permisos cuando aparezcan
3. Verificar que aparezcan datos de sensores
4. Probar navegación entre screens

### 2. Test de sensores:
1. **Acelerómetro**: Rotar device, verificar cambio de valores
2. **GPS**: Cambiar ubicación en Appetize.io settings
3. **Background**: Pulsar Home, volver a app, verificar que sigue funcionando

### 3. Test de permisos:
1. Ir a Settings > Privacy en Appetize.io
2. Verificar que RecWay Sensores tiene permisos
3. Probar denegar/otorgar permisos

## 🐛 Troubleshooting iPhone

### ❌ La app no inicia:
**Causa común**: Build para simulator en lugar de device
```powershell
# Solución: Re-build para device
flutter build ios --release --no-codesign
```

### ❌ Sensores no funcionan:
**Causa común**: Permisos no otorgados en Appetize.io
1. Ir a Device Settings en Appetize.io
2. Habilitar Location Services
3. Habilitar Motion & Fitness

### ❌ Background no funciona:
**Causa común**: Background modes no configurados
- Verificar `Info.plist` tiene `UIBackgroundModes`
- Confirmar que incluye `location` y `background-processing`

### ❌ App crashes:
1. Habilitar Debug Logs en Appetize.io
2. Revisar console para errores específicos
3. Verificar que todas las dependencias estén en el build

## 📊 Logs y debugging

### Habilitar logs detallados:
1. En Appetize.io: Settings > Debug Logs > Enable
2. Abrir DevTools del navegador (F12)
3. Ver console para logs de iOS

### Logs importantes a buscar:
```
[PERMISSION] Location permission granted/denied
[SENSOR] Accelerometer data received
[BACKGROUND] App entering background mode
[ERROR] Crash reports o errores específicos
```

## 🎯 URLs importantes

- **Upload**: https://appetize.io/upload
- **Dashboard**: https://appetize.io/dashboard  
- **Docs**: https://docs.appetize.io/
- **Support**: https://appetize.io/support

## ⚠️ Limitaciones conocidas

### Appetize.io limitations:
- Sesiones limitadas en plan gratuito
- Performance reducido vs iPhone real
- Algunos sensores pueden tener precisión limitada
- Background processing limitado

### iOS en web environment:
- Push notifications pueden no funcionar completamente
- Algunos permisos requieren interacción manual
- Background refresh limitado por browser

## 🏆 Best practices

### Para demos exitosos:
1. **Siempre build para device** (no simulator)
2. **Pre-configurar permisos** antes de la demo
3. **Probar primero** en privado antes de presentar
4. **Tener backup plan** (video o screenshots)

### Para testing:
1. **Usar Debug Logs** para diagnosticar problemas
2. **Probar múltiples escenarios** (permisos, orientaciones, ubicaciones)
3. **Documentar bugs** específicos de Appetize.io vs device real

## 📝 Resumen rápido

1. **Build**: `flutter build ios --release --no-codesign`
2. **Zip**: Comprimir `Runner.app` como `RecWay-Sensores-iPhone.app.zip`
3. **Upload**: Subir a https://appetize.io/upload
4. **Configure**: Habilitar Location Services y Motion & Orientation
5. **Test**: Verificar sensores y permisos
6. **Demo**: ¡Listo para presentar!

---
**Nota**: Esta guía está específicamente optimizada para iPhone. Android ha sido removido del proyecto por simplicidad.
