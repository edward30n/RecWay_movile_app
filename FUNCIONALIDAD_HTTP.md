# 📤 Funcionalidad HTTP para Envío de Datos CSV

## ✅ Implementación Completada

La aplicación **RecWay** ahora incluye funcionalidad para enviar archivos CSV generados a un servidor HTTP. Esta característica está **lista para usar** pero requiere configuración del servidor destino.

## 🚀 Características Implementadas

### **HttpService** (`lib/services/http_service.dart`)
- 📡 **Envío HTTP multipart** con metadatos del dispositivo
- 🔐 **Autenticación Bearer Token** (opcional)
- ⏱️ **Timeout configurable** (5 minutos para archivos grandes)
- 🔍 **Test de conectividad** con health check
- 📊 **Logging completo** del proceso de envío

### **Interfaz de Usuario**
- 🎛️ **Diálogo de configuración** para URL y API key
- 📤 **Botón "Enviar HTTP"** en opciones de exportación
- 🔄 **Diálogo de progreso** durante envío
- ✅ **Diálogo de resultado** con detalles de respuesta
- 🔧 **Indicador de estado** (configurado/no configurado)

### **Metadatos Enviados**
Junto con el archivo CSV se envían:
```json
{
  "device_id": "dispositivo_android_id",
  "session_id": "session_timestamp",
  "platform": "android",
  "device_model": "Samsung Galaxy S21",
  "manufacturer": "Samsung",
  "app_version": "2.0.0+1",
  "record_count": 1500,
  "upload_timestamp": "2025-07-16T10:30:00.000Z"
}
```

## 🛠️ Configuración del Servidor

### **Endpoint Requerido**
```
POST /upload
Content-Type: multipart/form-data
Authorization: Bearer <api_key> (opcional)
```

### **Campos del Formulario**
- `csv_file`: Archivo CSV (multipart file)
- `device_id`: ID del dispositivo
- `session_id`: ID de la sesión de grabación
- `platform`: Plataforma (android/ios)
- `device_model`: Modelo del dispositivo
- `manufacturer`: Fabricante
- `app_version`: Versión de la app
- `record_count`: Número de registros
- `upload_timestamp`: Timestamp del envío

### **Health Check Endpoint**
```
GET /health
Authorization: Bearer <api_key> (opcional)
```
Respuesta esperada: HTTP 200-299

## 📱 Uso en la Aplicación

### **1. Configurar Servidor**
1. Exportar datos CSV como siempre
2. En el diálogo de exportación, presionar **"Enviar HTTP"**
3. Presionar **"Configurar"** para abrir configuración
4. Ingresar:
   - **URL del Servidor**: `https://api.tuservidor.com/upload`
   - **API Key**: Token de autenticación (opcional)
5. Presionar **"Probar"** para verificar conectividad
6. **"Guardar"** configuración

### **2. Envío Automático**
Una vez configurado:
1. Exportar datos normalmente
2. Presionar **"Enviar HTTP"** en opciones
3. Confirmar envío
4. Monitorear progreso y resultado

## 🔧 Configuración para Desarrollo

### **Servidor de Prueba Local**
```bash
# Ejemplo con Node.js Express
npm install express multer cors
```

```javascript
const express = require('express');
const multer = require('multer');
const cors = require('cors');

const app = express();
app.use(cors());

const upload = multer({ dest: 'uploads/' });

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/upload', upload.single('csv_file'), (req, res) => {
  console.log('Archivo recibido:', req.file);
  console.log('Metadatos:', req.body);
  
  res.json({
    success: true,
    message: 'Archivo recibido correctamente',
    filename: req.file.filename,
    metadata: req.body
  });
});

app.listen(3000, () => {
  console.log('Servidor de prueba en http://localhost:3000');
});
```

### **URLs de Ejemplo**
- **Desarrollo Local**: `http://10.0.2.2:3000/upload` (emulador Android)
- **Desarrollo Local**: `http://192.168.1.100:3000/upload` (dispositivo físico)
- **Producción**: `https://api.tuservidor.com/upload`

## 📋 Formato del Archivo CSV

El archivo enviado mantiene el mismo formato de exportación estándar:
```csv
# METADATA HEADERS...
timestamp,acc_x,acc_y,acc_z,gyro_x,gyro_y,gyro_z,gps_lat,gps_lng,gps_accuracy,gps_speed,gps_altitude,gps_heading
1673840400000,0.123456,-0.654321,9.876543,0.001234,-0.005678,0.002345,40.7128,-74.0060,5.0,0.0,10.5,180.0
...
```

## 🔒 Seguridad

- ✅ **HTTPS recomendado** para producción
- ✅ **Bearer Token** para autenticación
- ✅ **Validación de datos** en servidor
- ✅ **Timeout de conexión** para evitar bloqueos
- ✅ **Manejo de errores** robusto

## 🎯 Casos de Uso

### **Investigación Científica**
- Envío automático a servidores de investigación
- Centralización de datos de múltiples dispositivos
- Análisis en tiempo real

### **Monitoreo Industrial**
- Envío a sistemas de telemetría
- Integración con dashboards
- Alertas automáticas

### **Backup Automático**
- Respaldo en la nube
- Sincronización multi-dispositivo
- Recuperación de datos

## 🔧 Estado Actual

- ✅ **HttpService implementado y funcional**
- ✅ **Interfaz de usuario completa**
- ✅ **Manejo de errores robusto**
- ✅ **Configuración persistente preparada**
- ✅ **Metadatos completos incluidos**
- ✅ **Testing de conectividad**
- ⚠️ **Requiere configuración de servidor destino**

## 🚀 Próximos Pasos

1. **Configurar servidor de destino** según necesidades
2. **Probar con datos reales** en entorno de desarrollo
3. **Implementar configuración persistente** con SharedPreferences (opcional)
4. **Agregar envío automático post-exportación** (opcional)

La funcionalidad está **100% lista** y esperando únicamente la configuración del endpoint de destino.
