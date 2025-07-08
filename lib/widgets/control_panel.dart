import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final bool isRecording;
  final int samplingRate;
  final bool backgroundMode;
  final int dataCount;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onExportData;
  final Function(int) onSamplingRateChanged;
  final Function(bool) onBackgroundModeChanged;

  const ControlPanel({
    super.key,
    required this.isRecording,
    required this.samplingRate,
    required this.backgroundMode,
    required this.dataCount,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onExportData,
    required this.onSamplingRateChanged,
    required this.onBackgroundModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel de Control',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            
            // Botones principales
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isRecording ? onStopRecording : onStartRecording,
                    icon: Icon(isRecording ? Icons.stop : Icons.play_arrow),
                    label: Text(isRecording ? 'Detener' : 'Iniciar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecording ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: dataCount > 0 ? onExportData : null,
                    icon: Icon(Icons.download),
                    label: Text('Exportar'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Configuración de frecuencia
            Row(
              children: [
                Text('Frecuencia: '),
                Expanded(
                  child: DropdownButton<int>(
                    value: samplingRate,
                    isExpanded: true,
                    items: [1, 5, 10, 20, 50].map((rate) {
                      String label = '$rate Hz';
                      if (rate == 1) label += ' (Ahorro)';
                      if (rate == 10) label += ' (Normal)';
                      if (rate == 50) label += ' (Máximo)';
                      
                      return DropdownMenuItem(
                        value: rate,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: isRecording ? null : (value) {
                      if (value != null) onSamplingRateChanged(value);
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Modo segundo plano
            SwitchListTile(
              title: Text('Modo Segundo Plano'),
              subtitle: Text('Continuar grabando cuando la app esté en segundo plano'),
              value: backgroundMode,
              onChanged: isRecording ? null : onBackgroundModeChanged,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
