# Script de build para iPhone únicamente (Appetize.io)
# RecWay Sensores - iOS Build Script para Windows/PowerShell

Write-Host "🍎 RecWay Sensores - iPhone Build para Appetize.io" -ForegroundColor Blue
Write-Host "=================================================="

# Funciones para logs con colores
function Log-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Cyan
}

function Log-Success($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Log-Warning($message) {
    Write-Host "[WARNING] $message" -ForegroundColor Yellow
}

function Log-Error($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

# Verificar dependencias
Log-Info "Verificando dependencias..."

# Verificar Flutter
try {
    $flutterVersion = flutter --version 2>$null
    Log-Success "Flutter encontrado"
} catch {
    Log-Error "Flutter no encontrado. Instalar Flutter primero."
    exit 1
}

# Verificar que estamos en el directorio correcto
if (!(Test-Path "pubspec.yaml")) {
    Log-Error "No se encontró pubspec.yaml. Ejecutar desde el directorio raíz del proyecto."
    exit 1
}

# Verificar que existe el directorio iOS
if (!(Test-Path "ios")) {
    Log-Error "Directorio ios/ no encontrado."
    exit 1
}

Log-Success "Dependencias verificadas"

# Paso 1: Limpiar proyecto
Log-Info "Limpiando proyecto..."
flutter clean
if ($LASTEXITCODE -ne 0) {
    Log-Error "Error al limpiar proyecto"
    exit 1
}
Log-Success "Proyecto limpiado"

# Paso 2: Obtener dependencias Flutter
Log-Info "Obteniendo dependencias Flutter..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Log-Error "Error al obtener dependencias Flutter"
    exit 1
}
Log-Success "Dependencias Flutter obtenidas"

# Paso 3: Instalar dependencias iOS (CocoaPods)
Log-Info "Instalando dependencias iOS (CocoaPods)..."
Log-Warning "Nota: CocoaPods requiere macOS. En Windows, este paso se omite."
Log-Warning "El build completo debe hacerse en macOS o usar Codemagic."

# Paso 4: Verificar configuración iOS
Log-Info "Verificando configuración iOS..."

# Verificar Info.plist
if (!(Test-Path "ios/Runner/Info.plist")) {
    Log-Error "Info.plist no encontrado"
    exit 1
}

# Verificar que tiene permisos básicos
$infoPlistContent = Get-Content "ios/Runner/Info.plist" -Raw
if ($infoPlistContent -match "NSLocationWhenInUseUsageDescription") {
    Log-Success "Permisos de ubicación configurados"
} else {
    Log-Warning "Permisos de ubicación no encontrados en Info.plist"
}

# Paso 5: Intentar build iOS (solo funcionará en macOS)
Log-Info "Intentando build iOS para iPhone..."
Log-Warning "NOTA: Este build solo funciona en macOS con Xcode instalado"

try {
    flutter build ios --release --no-codesign
    if ($LASTEXITCODE -eq 0) {
        Log-Success "Build de iOS completado"
        
        # Paso 6: Verificar que el build existe
        if (Test-Path "build/ios/iphoneos/Runner.app") {
            Log-Success "Runner.app generado correctamente"
            
            # Paso 7: Crear ZIP para Appetize.io
            Log-Info "Creando archivo ZIP para Appetize.io..."
            
            $buildPath = "build/ios/iphoneos"
            $zipPath = "$buildPath/RecWay-Sensores-iPhone.app.zip"
            
            # Eliminar ZIP anterior si existe
            if (Test-Path $zipPath) {
                Remove-Item $zipPath
                Log-Info "ZIP anterior eliminado"
            }
            
            # Crear nuevo ZIP
            Compress-Archive -Path "$buildPath/Runner.app" -DestinationPath $zipPath
            
            if (Test-Path $zipPath) {
                Log-Success "ZIP creado: $zipPath"
                
                # Mostrar tamaño del archivo
                $fileSize = (Get-Item $zipPath).Length / 1MB
                Log-Info "Tamaño del archivo: $([math]::Round($fileSize, 2)) MB"
                
                # Información final - Éxito
                Write-Host ""
                Write-Host "🎉 BUILD COMPLETADO EXITOSAMENTE" -ForegroundColor Green
                Write-Host "================================"
                Write-Host ""
                Log-Info "Archivo generado: $(Get-Location)\$zipPath"
                Write-Host ""
                Log-Info "Próximos pasos:"
                Write-Host "1. Ir a https://appetize.io/upload"
                Write-Host "2. Seleccionar iOS como plataforma"
                Write-Host "3. Subir el archivo RecWay-Sensores-iPhone.app.zip"
                Write-Host "4. Configurar device: iPhone (cualquier modelo reciente)"
                Write-Host "5. Habilitar Location Services y Motion & Orientation"
                Write-Host ""
                Log-Warning "IMPORTANTE: Configurar permisos en Appetize.io:"
                Write-Host "   ✅ Location Services: ENABLED"
                Write-Host "   ✅ Motion & Orientation: ENABLED"
                Write-Host "   ✅ Background App Refresh: ENABLED"
                Write-Host ""
                Log-Info "Para más detalles, ver: GUIA_APPETIZE_IO_IPHONE.md"
                
            } else {
                Log-Error "Error al crear ZIP"
                exit 1
            }
        } else {
            Log-Error "Runner.app no encontrado después del build"
            exit 1
        }
    } else {
        throw "Build falló"
    }
} catch {
    Log-Warning "Build de iOS falló (esperado en Windows)"
    Write-Host ""
    Write-Host "⚠️  BUILD NO COMPLETADO (Windows)" -ForegroundColor Yellow
    Write-Host "================================="
    Write-Host ""
    Log-Info "El build de iOS requiere macOS con Xcode."
    Write-Host ""
    Log-Info "Opciones disponibles:"
    Write-Host ""
    Write-Host "1. 🚀 RECOMENDADO: Usar Codemagic (automático)"
    Write-Host "   - Push código a repositorio Git"
    Write-Host "   - Codemagic ejecutará el workflow automáticamente"
    Write-Host "   - Descarga el ZIP desde Codemagic artifacts"
    Write-Host ""
    Write-Host "2. 💻 Usar macOS con Xcode:"
    Write-Host "   - Ejecutar este script en macOS"
    Write-Host "   - O ejecutar manualmente:"
    Write-Host "     flutter build ios --release --no-codesign"
    Write-Host ""
    Write-Host "3. ☁️  Usar servicios en la nube:"
    Write-Host "   - GitHub Actions con macOS runner"
    Write-Host "   - Otras plataformas CI/CD con macOS"
    Write-Host ""
    Log-Info "Configuración verificada - Lista para build en macOS o Codemagic"
    Write-Host ""
    Log-Info "Para más detalles, ver: GUIA_APPETIZE_IO_IPHONE.md"
}

Log-Success "Script completado! 🚀"
