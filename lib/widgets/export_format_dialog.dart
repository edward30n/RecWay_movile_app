import 'package:flutter/material.dart';

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.file_download,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Exportar Datos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, 
                           color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Información de la sesión',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Sesión: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Expanded(
                        child: Text(
                          widget.sessionId.substring(8, 18),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Muestras: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${widget.totalSamples}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selecciona el formato de exportación:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Opción CSV
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFormat == ExportFormat.csv 
                    ? Colors.blue.shade400 
                    : Colors.grey.shade300,
                  width: _selectedFormat == ExportFormat.csv ? 2 : 1,
                ),
                color: _selectedFormat == ExportFormat.csv
                  ? Colors.blue.shade50
                  : Colors.white,
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedFormat = ExportFormat.csv),
                child: Row(
                  children: [
                    Radio<ExportFormat>(
                      value: ExportFormat.csv,
                      groupValue: _selectedFormat,
                      onChanged: (value) => setState(() => _selectedFormat = value!),
                      activeColor: Colors.blue.shade600,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.table_chart,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CSV (Recomendado)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Formato tabular con metadatos completos. Compatible con Excel, Google Sheets, Python, R.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Opción JSON
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFormat == ExportFormat.json 
                    ? Colors.blue.shade400 
                    : Colors.grey.shade300,
                  width: _selectedFormat == ExportFormat.json ? 2 : 1,
                ),
                color: _selectedFormat == ExportFormat.json
                  ? Colors.blue.shade50
                  : Colors.white,
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedFormat = ExportFormat.json),
                child: Row(
                  children: [
                    Radio<ExportFormat>(
                      value: ExportFormat.json,
                      groupValue: _selectedFormat,
                      onChanged: (value) => setState(() => _selectedFormat = value!),
                      activeColor: Colors.blue.shade600,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.code,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JSON',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Formato estructurado ideal para APIs y aplicaciones web. Incluye metadatos anidados.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
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
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(_selectedFormat),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Exportar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
