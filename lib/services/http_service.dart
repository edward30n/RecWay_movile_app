import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class HttpService {
  // URL base para el envío de datos - configurar en el futuro
  static String? _baseUrl = 'https://tu-servidor.com/upload'; // 👈 PONER TU URL AQUÍ
  static String? _apiKey;
  
  /// Configurar la URL del servidor y API key para envío de datos
  static void configure({String? baseUrl, String? apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
  }
  
  /// Verificar si el servicio está configurado
  static bool get isConfigured => _baseUrl != null && _baseUrl!.isNotEmpty;
  
  /// Enviar archivo CSV al servidor
  static Future<HttpUploadResult> uploadCSVFile({
    required File csvFile,
    required Map<String, dynamic> metadata,
    String? customUrl,
    VoidCallback? onProgress,
  }) async {
    try {
      // Usar URL personalizada o la configurada
      final url = customUrl ?? _baseUrl;
      
      if (url == null || url.isEmpty) {
        return HttpUploadResult(
          success: false,
          error: 'URL del servidor no configurada',
          statusCode: 0,
        );
      }
      
      print('📤 Iniciando envío de archivo CSV...');
      print('📍 URL: $url');
      print('📄 Archivo: ${csvFile.path}');
      print('📊 Tamaño: ${await csvFile.length()} bytes');
      
      // Crear request multipart
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      
      // Agregar headers
      request.headers['Content-Type'] = 'multipart/form-data';
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_apiKey';
      }
      request.headers['User-Agent'] = 'RecWay-Mobile-App/1.0';
      
      // Agregar archivo CSV
      final fileStream = http.ByteStream(csvFile.openRead());
      final fileLength = await csvFile.length();
      final fileName = csvFile.path.split('/').last;
      
      final multipartFile = http.MultipartFile(
        'csv_file',
        fileStream,
        fileLength,
        filename: fileName,
      );
      request.files.add(multipartFile);
      
      // Agregar metadata como campos del formulario
      request.fields['device_id'] = metadata['deviceId']?.toString() ?? 'unknown';
      request.fields['session_id'] = metadata['sessionId']?.toString() ?? 'unknown';
      request.fields['platform'] = metadata['platform']?.toString() ?? 'unknown';
      request.fields['device_model'] = metadata['deviceModel']?.toString() ?? 'unknown';
      request.fields['manufacturer'] = metadata['manufacturer']?.toString() ?? 'unknown';
      request.fields['app_version'] = metadata['appVersion']?.toString() ?? 'unknown';
      request.fields['record_count'] = metadata['recordCount']?.toString() ?? '0';
      request.fields['upload_timestamp'] = DateTime.now().toIso8601String();
      
      // Enviar request con timeout
      final response = await request.send().timeout(
        Duration(minutes: 5), // Timeout de 5 minutos para archivos grandes
      );
      
      // Procesar respuesta
      final responseBody = await response.stream.bytesToString();
      
      print('📤 Respuesta del servidor: ${response.statusCode}');
      print('📤 Cuerpo de respuesta: $responseBody');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return HttpUploadResult(
          success: true,
          statusCode: response.statusCode,
          responseBody: responseBody,
          message: 'Archivo enviado exitosamente',
        );
      } else {
        return HttpUploadResult(
          success: false,
          statusCode: response.statusCode,
          responseBody: responseBody,
          error: 'Error del servidor: ${response.statusCode}',
        );
      }
      
    } catch (e) {
      print('❌ Error enviando archivo CSV: $e');
      return HttpUploadResult(
        success: false,
        error: 'Error de conexión: $e',
        statusCode: 0,
      );
    }
  }
  
  /// Verificar conectividad con el servidor
  static Future<bool> testConnection({String? customUrl}) async {
    try {
      final url = customUrl ?? _baseUrl;
      if (url == null || url.isEmpty) return false;
      
      // Hacer ping al servidor con endpoint de health check
      final pingUrl = url.endsWith('/') ? '${url}health' : '$url/health';
      final response = await http.get(
        Uri.parse(pingUrl),
        headers: {
          'User-Agent': 'RecWay-Mobile-App/1.0',
          if (_apiKey != null && _apiKey!.isNotEmpty)
            'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ Error de conectividad: $e');
      return false;
    }
  }
  
  /// Obtener configuración actual
  static Map<String, String?> getConfiguration() {
    return {
      'baseUrl': _baseUrl,
      'apiKey': _apiKey != null ? '***${_apiKey!.substring(_apiKey!.length - 4)}' : null,
      'configured': isConfigured.toString(),
    };
  }
  
  /// Mostrar diálogo de configuración
  static Future<void> showConfigurationDialog(BuildContext context) async {
    final urlController = TextEditingController(text: _baseUrl ?? '');
    final apiKeyController = TextEditingController(text: _apiKey ?? '');
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('Configuración HTTP'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configura la URL del servidor para envío automático de datos:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'URL del Servidor',
                    hintText: 'https://api.tuservidor.com/upload',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key (Opcional)',
                    hintText: 'Token de autenticación',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El archivo CSV se enviará automáticamente después de la exportación si está configurado.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Probar conexión
                final testUrl = urlController.text.trim();
                if (testUrl.isNotEmpty) {
                  final connected = await testConnection(customUrl: testUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(connected ? 
                        '✅ Conexión exitosa' : 
                        '❌ No se pudo conectar al servidor'
                      ),
                      backgroundColor: connected ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: Text('Probar'),
            ),
            ElevatedButton(
              onPressed: () {
                configure(
                  baseUrl: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                  apiKey: apiKeyController.text.trim().isEmpty ? null : apiKeyController.text.trim(),
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Configuración guardada'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}

/// Resultado del envío HTTP
class HttpUploadResult {
  final bool success;
  final int statusCode;
  final String? responseBody;
  final String? error;
  final String? message;
  
  HttpUploadResult({
    required this.success,
    required this.statusCode,
    this.responseBody,
    this.error,
    this.message,
  });
  
  @override
  String toString() {
    if (success) {
      return 'Éxito: $message (${statusCode})';
    } else {
      return 'Error: $error (${statusCode})';
    }
  }
}
