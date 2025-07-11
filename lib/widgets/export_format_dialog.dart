import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ExportFormat { csv, json }

class ExportFormatDialog extends StatefulWidget {
  final String sessionId;
  final int totalSamples;

  const ExportFormatDialog({
    Key? key,
    required this.sessionId,
    required this.totalSamples,
  }) : super(key: key);

  @override
  State<ExportFormatDialog> createState() => _ExportFormatDialogState();
}

class _ExportFormatDialogState extends State<ExportFormatDialog>
    with TickerProviderStateMixin {
  ExportFormat _selectedFormat = ExportFormat.csv;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                Icons.file_download,
                color: AppColors.accentBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Exportar Datos',
              style: AppTextStyles.headline3.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: AppColors.accentBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, 
                           color: AppColors.accentBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Información',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Sesión: ', style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                      Expanded(
                        child: Text(
                          widget.sessionId.substring(8, 18),
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Muestras: ', style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                      Text(
                        '${widget.totalSamples}',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              'Selecciona el formato de exportación:',
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            
            // Opción CSV
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: _selectedFormat == ExportFormat.csv 
                    ? AppColors.accentBlue 
                    : Colors.white30,
                  width: _selectedFormat == ExportFormat.csv ? 2 : 1,
                ),
                color: _selectedFormat == ExportFormat.csv
                  ? AppColors.accentBlue.withOpacity(0.15)
                  : AppColors.primaryBlue.withOpacity(0.5),
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedFormat = ExportFormat.csv),
                child: Row(
                  children: [
                    Radio<ExportFormat>(
                      value: ExportFormat.csv,
                      groupValue: _selectedFormat,
                      onChanged: (value) => setState(() => _selectedFormat = value!),
                      activeColor: AppColors.accentBlue,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        Icons.table_chart,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CSV',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Formato tabular con metadatos completos.',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingM),
            
            // Opción JSON
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: _selectedFormat == ExportFormat.json 
                    ? AppColors.accentBlue 
                    : Colors.white30,
                  width: _selectedFormat == ExportFormat.json ? 2 : 1,
                ),
                color: _selectedFormat == ExportFormat.json
                  ? AppColors.accentBlue.withOpacity(0.15)
                  : AppColors.primaryBlue.withOpacity(0.5),
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedFormat = ExportFormat.json),
                child: Row(
                  children: [
                    Radio<ExportFormat>(
                      value: ExportFormat.json,
                      groupValue: _selectedFormat,
                      onChanged: (value) => setState(() => _selectedFormat = value!),
                      activeColor: AppColors.accentBlue,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        Icons.code,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JSON',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Formato estructurado.',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: AppTextStyles.button.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(_selectedFormat),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Exportar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL, 
                vertical: AppDimensions.paddingM,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Función helper para mostrar el diálogo
Future<ExportFormat?> showExportFormatDialog(
  BuildContext context, {
  required String sessionId,
  required int totalSamples,
}) {
  return showDialog<ExportFormat>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ExportFormatDialog(
      sessionId: sessionId,
      totalSamples: totalSamples,
    ),
  );
}
