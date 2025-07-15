import 'package:flutter/material.dart';

/// Paleta de colores profesional basada en la pantalla de carga
class AppColors {
  // Colores primarios del gradiente de fondo
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMedium = Color(0xFF16213E);
  static const Color primaryBlue = Color(0xFF0F3460);
  
  // Colores de acento y branding
  static const Color accentBlue = Color(0xFF4FACFE);
  static const Color accentCyan = Color(0xFF00F2FE);
  
  // Colores de superficie y contenido
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF2E2E2E);
  static const Color onSurfaceVariant = Color(0xFF6E6E6E);
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Colores específicos para sensores
  static const Color accelerometer = Color(0xFF4FACFE);
  static const Color gyroscope = Color(0xFF00F2FE);
  static const Color orientation = Color(0xFFFF6B6B);
  static const Color gps = Color(0xFF4ECDC4);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryMedium, primaryBlue],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentBlue, accentCyan],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A2A4A),
      Color(0xFF1E1E3F),
    ],
  );
}

/// Configuración de espaciado y dimensiones
class AppDimensions {
  // Padding y márgenes
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  // Bordes redondeados
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  // Elevaciones
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;
  
  // Tamaños de iconos
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
}

/// Estilos de texto personalizados
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.surface,
    letterSpacing: 1.2,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.surface,
    letterSpacing: 1.0,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );
  
  static TextStyle subtitle1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.surface.withOpacity(0.8),
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.surface,
  );
  
  static TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.surface.withOpacity(0.7),
  );
  
  static TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.surface.withOpacity(0.6),
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );
  
  // Estilos para datos de sensores
  static const TextStyle sensorValue = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: AppColors.surface,
  );
  
  static TextStyle sensorLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.surface.withOpacity(0.8),
  );
}

/// Tema principal de la aplicación
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accentBlue,
      scaffoldBackgroundColor: AppColors.primaryDark,
      
      // Esquema de colores
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentCyan,
        surface: AppColors.primaryMedium,
        onSurface: AppColors.surface,
        error: AppColors.error,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTextStyles.headline3,
        iconTheme: IconThemeData(color: AppColors.surface),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: AppDimensions.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        color: AppColors.primaryMedium.withOpacity(0.8),
      ),
      
      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.surface,
          elevation: AppDimensions.elevationM,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          textStyle: AppTextStyles.button,
        ),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primaryMedium.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: AppColors.accentBlue.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: AppColors.surface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.accentBlue),
        ),
        labelStyle: AppTextStyles.body2,
        hintStyle: AppTextStyles.body2,
      ),
      
      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentBlue,
        linearTrackColor: Colors.transparent,
      ),
    );
  }
}

/// Extensiones útiles para el tema
extension AppThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
}

/// Widgets personalizados con el tema
class AppWidgets {
  /// Widget de fondo con gradiente para toda la aplicación
  static Widget gradientBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: child,
    );
  }
  
  /// Card con gradiente personalizado
  static Widget gradientCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? elevation,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: elevation ?? AppDimensions.elevationM,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppDimensions.paddingM),
          child: child,
        ),
      ),
    );
  }
  
  /// Botón con gradiente
  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withOpacity(0.3),
            blurRadius: AppDimensions.elevationM,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: AppDimensions.iconS,
                    height: AppDimensions.iconS,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, color: AppColors.surface, size: AppDimensions.iconS),
                  const SizedBox(width: AppDimensions.paddingS),
                ],
                Text(text, style: AppTextStyles.button),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
