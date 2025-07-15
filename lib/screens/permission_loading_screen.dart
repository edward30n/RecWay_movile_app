import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PermissionLoadingScreen extends StatefulWidget {
  final String currentStep;
  final double progress;
  final VoidCallback? onCancel;

  const PermissionLoadingScreen({
    super.key,
    required this.currentStep,
    required this.progress,
    this.onCancel,
  });

  @override
  State<PermissionLoadingScreen> createState() => _PermissionLoadingScreenState();
}

class _PermissionLoadingScreenState extends State<PermissionLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de pulso más sutil
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Evitar que el usuario salga accidentalmente
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icono animado
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sensors,
                        size: 60,
                        color: AppColors.surface,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXL + 8),

                  // Título
                  Text(
                    'RecWay',
                    style: AppTextStyles.headline1.copyWith(
                      color: AppColors.surface,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingM),

                  // Subtítulo
                  Text(
                    'Configurando aplicación...',
                    style: AppTextStyles.subtitle1.copyWith(
                      color: AppColors.surface.withOpacity(0.8),
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXL + AppDimensions.paddingL),

                  // Barra de progreso
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS / 2),
                      color: AppColors.surface.withOpacity(0.1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS / 2),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentBlue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingL - 4),

                  // Porcentaje
                  Text(
                    '${(widget.progress * 100).toInt()}%',
                    style: AppTextStyles.headline3.copyWith(
                      color: AppColors.accentBlue,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXL + 8),

                  // Paso actual
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL,
                      vertical: AppDimensions.paddingM,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      color: AppColors.surface.withOpacity(0.05),
                      border: Border.all(
                        color: AppColors.surface.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: AppColors.accentBlue,
                          size: AppDimensions.iconM,
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: Text(
                            widget.currentStep,
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
