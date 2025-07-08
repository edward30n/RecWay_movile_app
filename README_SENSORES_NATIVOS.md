# Sensor Data Collector Pro - Versión con Sensores Nativos

## 🚀 Nuevas Mejoras para Grabación en Segundo Plano

### 📱 **APK Lista para Instalar**
```
Ubicación: C:\Users\NICOLAS\Desktop\RecWay\test1\test1\build\app\outputs\flutter-apk\app-debug.apk
Tamaño: 92.71 MB
Fecha: 7/07/2025 2:40:34 p.m.
```

### 🔋 **Soluciones Implementadas para el Problema de Sensores "Dormidos"**

#### **Problema Identificado**
- Los sensores (acelerómetro/giroscopio) se "congelan" cuando la app va a segundo plano
- Repiten la última muestra en lugar de entregar datos reales
- Es una limitación de seguridad de Android para ahorrar batería

#### **Soluciones Implementadas**

1. **🔧 Sensores Nativos de Android**
   - Canal de plataforma directo al SensorManager nativo
   - WakeLock a nivel nativo para mantener CPU activo
   - Polling forzado cada 100ms para evitar suspensión

2. **⚡ Configuración Agresiva de Permisos**
   ```xml
   - SCHEDULE_EXACT_ALARM (alarmas exactas)
   - DEVICE_POWER (control de energía)
   - MODIFY_PHONE_STATE (modificar estado del teléfono)
   - WRITE_SECURE_SETTINGS (configuraciones seguras)
   ```

3. **🛡️ Protecciones del Servicio**
   - `stopWithTask="false"` (no se detiene con la app)
   - Receptor de broadcast para reinicio automático
   - Servicio persistente con mayor prioridad

4. **🔋 Optimización de Batería**
   - Solicitud automática para ignorar optimizaciones
   - WakeLock dual (Flutter + Nativo)
   - Configuración `keepScreenOn` durante grabación

### 📊 **Cómo Funciona la Nueva Implementación**

#### **Flujo de Grabación**
1. **Inicio de Grabación**
   - Activa sensores de Flutter (método principal)
   - Inicia sensores nativos como respaldo
   - Adquiere WakeLock nativo y de Flutter
   - Configura polling agresivo

2. **Durante la Grabación**
   - Monitoreo dual de sensores
   - Si sensores Flutter fallan → usa datos nativos
   - Heartbeat cada 5 segundos para verificar estado
   - Logs detallados para debugging

3. **Detección de Problemas**
   - Compara timestamps de sensores
   - Detecta repetición de valores
   - Cambia automáticamente a modo nativo

### 🧪 **Instrucciones de Prueba**

#### **Instalación**
```bash
# Transferir APK al dispositivo Android
adb install C:\Users\NICOLAS\Desktop\RecWay\test1\test1\build\app\outputs\flutter-apk\app-debug.apk

# O instalar manualmente desde el explorador de archivos del teléfono
```

#### **Prueba del Problema Corregido**
1. **Abrir la aplicación**
   - Conceder todos los permisos solicitados
   - Confirmar deshabilitar optimización de batería

2. **Iniciar grabación a 10 Hz**
   - Observar valores del acelerómetro cambiando
   - Mover el teléfono para ver variaciones

3. **Bloquear pantalla / Minimizar app**
   - **ANTES**: Valores se congelaban
   - **AHORA**: Deben seguir cambiando

4. **Verificar logs**
   ```bash
   adb logcat | grep -E "(Accel|Gyro|Native|WakeLock)"
   ```

5. **Revisar datos exportados**
   - Exportar sesión después de 2-3 minutos
   - Verificar que los valores realmente cambian durante el período de bloqueo

### 🔍 **Indicadores de Funcionamiento Correcto**

#### **En la Aplicación**
- ✅ Notificación persistente: "🔴 GRABANDO - X Hz - SENSORES ACTIVOS + NATIVOS"
- ✅ Contador de tiempo sigue avanzando
- ✅ Número de muestras sigue incrementando

#### **En los Logs**
```
🔋 Native sensors started with wake lock
📱 Sensores nativos - Accel: X.XXX, Gyro: Y.YYY
💓 Heartbeat - Recording: true, Accel: true, Gyro: true
```

#### **En los Datos Exportados**
- ✅ Valores de acelerómetro/giroscopio cambian constantemente
- ✅ No hay períodos largos con valores idénticos
- ✅ Timestamps son consecutivos sin grandes gaps

### ⚠️ **Limitaciones Conocidas**

1. **Hardware Específico**
   - Algunos fabricantes (Samsung, Huawei) tienen restricciones más estrictas
   - Puede requerir configuración manual en Configuración > Batería

2. **Versiones de Android**
   - Android 12+ tiene limitaciones más severas
   - Puede necesitar permisos adicionales de usuario

3. **Modo Doze**
   - Android puede entrar en modo "Doze" después de 30+ minutos
   - La aplicación intenta combatir esto pero no es 100% garantizado

### 🛠️ **Próximos Pasos si el Problema Persiste**

Si aún experimentas congelamiento de sensores:

1. **Verificar configuración del dispositivo**
   - Configuración > Batería > Optimización de batería > Sensor Data Collector Pro > No optimizar
   - Configuración > Aplicaciones > Sensor Data Collector Pro > Batería > Sin restricciones

2. **Modo desarrollador**
   - Activar "Mantener actividades" y "No mantener actividades en segundo plano: DESACTIVAR"

3. **Reportar dispositivo específico**
   - Marca, modelo y versión de Android
   - Logs específicos del comportamiento

### 📈 **Comparación con Sensor Logger**

| Característica | Sensor Logger | Esta App (Nueva Versión) |
|---|---|---|
| Sensores en background | ✅ | ✅ |
| WakeLock nativo | ✅ | ✅ |
| Dual sensor system | ❌ | ✅ |
| Debugging detallado | ❌ | ✅ |
| Configuración automática | ❌ | ✅ |

### 🎯 **Resultado Esperado**

Con esta implementación, la aplicación debería comportarse de manera similar a Sensor Logger, manteniendo los sensores activos y obteniendo datos reales incluso cuando:

- La pantalla está bloqueada
- La aplicación está minimizada
- El dispositivo está en reposo
- Han pasado varios minutos de inactividad

**¡La nueva APK está lista para probar estas mejoras!** 🚀
