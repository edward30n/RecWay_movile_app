import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';

class EmergencyErrorScreen extends StatefulWidget {
  final String errorMessage;
  final String? stackTrace;
  final VoidCallback? onRetry;

  const EmergencyErrorScreen({
    Key? key,
    required this.errorMessage,
    this.stackTrace,
    this.onRetry,
  }) : super(key: key);

  @override
  State<EmergencyErrorScreen> createState() => _EmergencyErrorScreenState();
}

class _EmergencyErrorScreenState extends State<EmergencyErrorScreen> {
  bool _isFixing = false;
  String _currentStep = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de error
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.sensors_off,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Título
                const Text(
                  '🚨 Problemas con Sensores',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje principal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Detectamos problemas con los sensores:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_isFixing) ...[
                        const CircularProgressIndicator(color: Colors.blue),
                        const SizedBox(height: 16),
                        Text(
                          _currentStep,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        _buildProblemsList(),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (!_isFixing) ...[
                  // Botón principal de arreglo
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _performSensorDiagnostic,
                      icon: const Icon(Icons.build_circle),
                      label: const Text(
                        'Arreglar Sensores Automáticamente',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botón de configuración manual
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showManualSteps,
                      icon: const Icon(Icons.settings),
                      label: const Text('Configuración Manual'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botón de reintentar
                  if (widget.onRetry != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Intentar de Nuevo'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
                
                const SizedBox(height: 32),
                
                // Información del error técnico
                if (widget.stackTrace != null) ...[
                  ExpansionTile(
                    title: Text(
                      'Detalles Técnicos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    iconColor: Colors.white.withOpacity(0.8),
                    collapsedIconColor: Colors.white.withOpacity(0.8),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.stackTrace!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProblemsList() {
    final problems = [
      '🌀 Giroscopio muestra valores constantes (0.000)',
      '💾 Permisos de almacenamiento no detectados',
      '📍 Conflictos con servicio de ubicación',
      '⚡ Posible optimización de batería activa',
    ];

    return Column(
      children: problems.map((problem) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                problem,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Future<void> _performSensorDiagnostic() async {
    setState(() {
      _isFixing = true;
      _currentStep = 'Iniciando diagnóstico de sensores...';
    });

    try {
      // Paso 1: Verificar permisos específicos de sensores
      setState(() {
        _currentStep = 'Verificando permisos de sensores...';
      });
      await Future.delayed(const Duration(seconds: 1));
      
      final sensorStatus = await Permission.sensors.status;
      if (sensorStatus != PermissionStatus.granted) {
        setState(() {
          _currentStep = 'Solicitando permisos de sensores...';
        });
        await Permission.sensors.request();
      }
      
      // Paso 2: Forzar permisos de almacenamiento
      setState(() {
        _currentStep = 'Reconfigurando almacenamiento...';
      });
      await Future.delayed(const Duration(seconds: 1));
      
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
      
      // Paso 3: Verificar y solicitar permisos de alta frecuencia
      setState(() {
        _currentStep = 'Configurando sensores de alta frecuencia...';
      });
      await Future.delayed(const Duration(seconds: 1));
      
      try {
        // En Android, verificar permisos de alta frecuencia
        final highSamplingStatus = await Permission.sensors.status;
        if (highSamplingStatus != PermissionStatus.granted) {
          await Permission.sensors.request();
        }
      } catch (e) {
        print('⚠️ No se pudo configurar alta frecuencia: $e');
      }
      
      // Paso 4: Limpiar caché de permisos y reiniciar
      setState(() {
        _currentStep = 'Limpiando configuración...';
      });
      await Future.delayed(const Duration(seconds: 1));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sensor_config_cache');
      await prefs.remove('last_sensor_error');
      
      // Paso 5: Verificar estado final
      setState(() {
        _currentStep = 'Verificando configuración final...';
      });
      await PermissionService.checkAndLogAllPermissions();
      
      setState(() {
        _isFixing = false;
      });
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Diagnóstico completado. Probando sensores...'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Intentar de nuevo después de 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (widget.onRetry != null) {
          widget.onRetry!();
        }
      }
      
    } catch (e) {
      setState(() {
        _isFixing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en diagnóstico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showManualSteps() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '📋 Configuración Manual',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sigue estos pasos para arreglar los sensores:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildManualStep(
                '1. Configuración de Android',
                'Configuración > Apps > RecWay > Permisos',
              ),
              
              _buildManualStep(
                '2. Activar TODOS los permisos',
                'Ubicación, Almacenamiento, Sensores, Notificaciones',
              ),
              
              _buildManualStep(
                '3. Optimización de Batería',
                'Configuración > Batería > Optimización > RecWay > No optimizar',
              ),
              
              _buildManualStep(
                '4. Servicios de Ubicación',
                'Configuración > Ubicación > Activar servicio de ubicación',
              ),
              
              _buildManualStep(
                '5. Reiniciar Aplicación',
                'Cerrar completamente RecWay y volver a abrir',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualStep(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
