# 📱 GUÍA PARA APPETIZE.IO - RecWay Sensores

## 🎯 **PROBLEMA SOLUCIONADO**
Tu archivo `codemagic.yaml` estaba configurado para **simulador** (`--simulator`), pero Appetize.io necesita builds para **dispositivos físicos**.

## ✅ **CONFIGURACIÓN CORREGIDA**

### **iOS para Appetize.io**
```yaml
- name: Build iOS for Device (Appetize compatible)
  script: |
    flutter build ios --release --no-codesign
```
- ✅ **Cambio clave**: `--release --no-codesign` en lugar de `--simulator`
- ✅ **Directorio**: `build/ios/iphoneos` en lugar de `iphonesimulator`
- ✅ **Bundle ID**: `com.recway.sensores` (único)

### **Android para Appetize.io**
```yaml
- name: Build Android APK
  script: |
    flutter build apk --release
```
- ✅ **APK de release** para mejor rendimiento en Appetize

## 🚀 **CÓMO USAR CON APPETIZE.IO**

### **Paso 1: Construir el proyecto**
```bash
# Opción A: Usar Codemagic (automático)
git push origin main

# Opción B: Construir localmente
flutter build ios --release --no-codesign
# o
flutter build apk --release
```

### **Paso 2: Comprimir archivo**
```bash
# Para iOS
cd build/ios/iphoneos
zip -r RecWay-Sensores.app.zip Runner.app

# Para Android (ya está listo el APK)
# Archivo: build/app/outputs/flutter-apk/app-release.apk
```

### **Paso 3: Subir a Appetize.io**
1. Ve a https://appetize.io/upload
2. Selecciona **iOS** o **Android**
3. Sube:
   - **iOS**: `RecWay-Sensores.app.zip`
   - **Android**: `app-release.apk` o `RecWay-Sensores.apk`
4. Configura los ajustes del dispositivo

## ⚙️ **CONFIGURACIÓN RECOMENDADA PARA APPETIZE**

### **iOS Settings**
- **Device**: iPhone 14 Pro
- **iOS Version**: 16.0+
- **Orientation**: Portrait
- **Scale**: 75%

### **Android Settings**
- **Device**: Pixel 6
- **Android Version**: API 31+
- **Orientation**: Portrait
- **Scale**: 75%

### **Permisos importantes**
En Appetize, asegúrate de habilitar:
- ✅ **Location Services**
- ✅ **Camera/Microphone** (si se usan)
- ✅ **Notifications**

## 🔧 **FUNCIONALIDADES QUE FUNCIONARÁN**

### ✅ **Completamente funcionales**
- Interfaz de usuario
- Navegación
- Almacenamiento local
- Exportación de datos
- Configuraciones de la app

### ⚠️ **Limitaciones en Appetize**
- **GPS**: Datos simulados (no ubicación real)
- **Sensores**: Algunos pueden estar simulados
- **Background**: Limitado en entorno virtual
- **Performance**: Puede ser más lento que dispositivo real

## 📋 **ARCHIVOS GENERADOS**

Después del build en Codemagic, obtendrás:

### **iOS**
- `build/ios/iphoneos/RecWay-Sensores.app.zip`
- Compatible con dispositivos físicos iOS
- Bundle ID: `com.recway.sensores`

### **Android**
- `build/app/outputs/flutter-apk/RecWay-Sensores.apk`
- APK de release optimizada
- Package: `com.recway.whitelabel`

## 🚀 **PRÓXIMOS PASOS**

1. **Commit y push** el `codemagic.yaml` actualizado
2. **Esperar** que Codemagic construya los artefactos
3. **Descargar** los archivos `.zip` (iOS) o `.apk` (Android)
4. **Subir** a Appetize.io
5. **Probar** la funcionalidad en el entorno virtual

## 💡 **CONSEJOS PARA APPETIZE**

### **Para mejor experiencia:**
- Usa **release builds** (más rápidas)
- Configura **timeout** más alto (10-15 minutos)
- Habilita **debug panel** para ver logs
- Prueba en **múltiples dispositivos**

### **Para demostración:**
- Prepara **datos de ejemplo** pre-cargados
- Crea **tour guiado** de funcionalidades
- Ten **screenshots** de backup por si falla

## ✅ **RESULTADO ESPERADO**
Con esta configuración, tu app funcionará correctamente en Appetize.io y los usuarios podrán:
- Ver la interfaz completa
- Probar la recolección de sensores (simulada)
- Exportar datos de ejemplo
- Cambiar configuraciones
- Navegar por todas las pantallas
