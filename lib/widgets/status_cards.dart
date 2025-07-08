import 'package:flutter/material.dart';

class StatusCards extends StatelessWidget {
  final int recordingTime;
  final int dataCount;
  final int samplingRate;
  final bool isRecording;

  const StatusCards({
    super.key,
    required this.recordingTime,
    required this.dataCount,
    required this.samplingRate,
    required this.isRecording,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Tiempo',
                _formatTime(recordingTime),
                Icons.timer,
                Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatusCard(
                'Muestras',
                dataCount.toString(),
                Icons.data_usage,
                Colors.green,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Frecuencia',
                '$samplingRate Hz',
                Icons.speed,
                Colors.purple,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatusCard(
                'Estado',
                isRecording ? 'Grabando' : 'Detenido',
                isRecording ? Icons.fiber_manual_record : Icons.stop,
                isRecording ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
