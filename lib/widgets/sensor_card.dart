import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';

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
        AppWidgets.gradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smartphone, color: AppColors.accelerometer, size: AppDimensions.iconM),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    'Acelerómetro (m/s²)',
                    style: AppTextStyles.headline3.copyWith(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Row(
                children: [
                  Expanded(child: _buildAxisValue('X', accelerometer?.x ?? 0, AppColors.error)),
                  Expanded(child: _buildAxisValue('Y', accelerometer?.y ?? 0, AppColors.success)),
                  Expanded(child: _buildAxisValue('Z', accelerometer?.z ?? 0, AppColors.info)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // Giroscopio
        AppWidgets.gradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.rotate_right, color: AppColors.gyroscope, size: AppDimensions.iconM),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    'Giroscopio (rad/s)',
                    style: AppTextStyles.headline3.copyWith(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Row(
                children: [
                  Expanded(child: _buildAxisValue('X', gyroscope?.x ?? 0, AppColors.error)),
                  Expanded(child: _buildAxisValue('Y', gyroscope?.y ?? 0, AppColors.success)),
                  Expanded(child: _buildAxisValue('Z', gyroscope?.z ?? 0, AppColors.info)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.paddingM),

        // GPS
        AppWidgets.gradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gps_fixed, color: AppColors.gps, size: AppDimensions.iconM),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    'GPS de Alta Precisión',
                    style: AppTextStyles.headline3.copyWith(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),
              if (position != null) ...[
                _buildGPSValue('Latitud', '${position!.latitude.toStringAsFixed(6)}°'),
                _buildGPSValue('Longitud', '${position!.longitude.toStringAsFixed(6)}°'),
                _buildGPSValue('Precisión', '±${position!.accuracy.toStringAsFixed(1)}m'),
                _buildGPSValue('Velocidad', '${(position!.speed * 3.6).toStringAsFixed(1)} km/h'),
                _buildGPSValue('Altitud', '${position!.altitude.toStringAsFixed(1)}m'),
              ] else
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Text(
                        'Esperando señal GPS...',
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAxisValue(String axis, double value, Color color) {
    return Column(
      children: [
        Text(
          axis,
          style: AppTextStyles.sensorLabel.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingS,
            horizontal: AppDimensions.paddingM,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value.toStringAsFixed(3),
            style: AppTextStyles.sensorValue.copyWith(
              color: AppColors.surface,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGPSValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.sensorLabel,
          ),
          Text(
            value,
            style: AppTextStyles.sensorValue.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
