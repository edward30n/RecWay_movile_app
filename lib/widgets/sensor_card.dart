import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

class SensorCard extends StatelessWidget {
  final AccelerometerEvent? accelerometer;
  final GyroscopeEvent? gyroscope;
  final Position? position;

  const SensorCard({
    super.key,
    this.accelerometer,
    this.gyroscope,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Acelerómetro
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smartphone, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Acelerómetro (m/s²)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildAxisValue('X', accelerometer?.x ?? 0, Colors.red)),
                    Expanded(child: _buildAxisValue('Y', accelerometer?.y ?? 0, Colors.green)),
                    Expanded(child: _buildAxisValue('Z', accelerometer?.z ?? 0, Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Giroscopio
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rotate_right, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Giroscopio (rad/s)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildAxisValue('X', gyroscope?.x ?? 0, Colors.red)),
                    Expanded(child: _buildAxisValue('Y', gyroscope?.y ?? 0, Colors.green)),
                    Expanded(child: _buildAxisValue('Z', gyroscope?.z ?? 0, Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // GPS
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'GPS de Alta Precisión',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (position != null) ...[
                  _buildGPSValue('Latitud', '${position!.latitude.toStringAsFixed(6)}°'),
                  _buildGPSValue('Longitud', '${position!.longitude.toStringAsFixed(6)}°'),
                  _buildGPSValue('Precisión', '±${position!.accuracy.toStringAsFixed(1)}m'),
                  _buildGPSValue('Velocidad', '${(position!.speed * 3.6).toStringAsFixed(1)} km/h'),
                  _buildGPSValue('Altitud', '${position!.altitude.toStringAsFixed(1)}m'),
                ] else
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 16),
                        Text('Esperando señal GPS...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAxisValue(String axis, double value, Color color) {
    return Column(
      children: [
        Text(axis, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toStringAsFixed(3),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGPSValue(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
