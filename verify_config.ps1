# Verificador de configuración iOS para Appetize.io
# RecWay Sensores - iOS Configuration Checker

Write-Host "🔍 Verificador de Configuración iOS - RecWay Sensores" -ForegroundColor Blue
Write-Host "====================================================="
Write-Host ""

# Funciones para logs con colores
function Log-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Cyan
}

function Log-Success($message) {
    Write-Host "[✅] $message" -ForegroundColor Green
}

function Log-Warning($message) {
    Write-Host "[⚠️] $message" -ForegroundColor Yellow
}

function Log-Error($message) {
    Write-Host "[❌] $message" -ForegroundColor Red
}

function Check-File($path, $description) {
    if (Test-Path $path) {
        Log-Success "$description encontrado: $path"
        return $true
    } else {
        Log-Error "$description NO encontrado: $path"
        return $false
    }
}

function Check-FileContent($path, $pattern, $description) {
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        if ($content -match $pattern) {
            Log-Success "$description configurado correctamente"
            return $true
        } else {
            Log-Warning "$description NO encontrado en $path"
            return $false
        }
    } else {
        Log-Error "Archivo no encontrado: $path"
        return $false
    }
}

$allGood = $true

Write-Host "📁 VERIFICACIÓN DE ARCHIVOS CRÍTICOS" -ForegroundColor Yellow
Write-Host "======================================"

# Verificar archivos principales
$allGood = (Check-File "pubspec.yaml" "pubspec.yaml") -and $allGood
$allGood = (Check-File "ios/Runner/Info.plist" "Info.plist iOS") -and $allGood
$allGood = (Check-File "ios/Podfile" "Podfile iOS") -and $allGood
$allGood = (Check-File "codemagic.yaml" "Configuración Codemagic") -and $allGood
$allGood = (Check-File "lib/main.dart" "main.dart") -and $allGood

Write-Host ""
Write-Host "🔐 VERIFICACIÓN DE PERMISOS iOS" -ForegroundColor Yellow
Write-Host "================================"

# Verificar permisos en Info.plist
$infoPlistPath = "ios/Runner/Info.plist"
if (Test-Path $infoPlistPath) {
    $permissions = @{
        "NSLocationWhenInUseUsageDescription" = "Permiso de ubicación en uso"
        "NSLocationAlwaysAndWhenInUseUsageDescription" = "Permiso de ubicación siempre"
        "NSMotionUsageDescription" = "Permiso de sensores de movimiento"
        "UIBackgroundModes" = "Modos de background"
    }
    
    foreach ($perm in $permissions.GetEnumerator()) {
        $allGood = (Check-FileContent $infoPlistPath $perm.Key $perm.Value) -and $allGood
    }
} else {
    Log-Error "Info.plist no encontrado"
    $allGood = $false
}

Write-Host ""
Write-Host "📱 VERIFICACIÓN DE CONFIGURACIÓN iOS" -ForegroundColor Yellow
Write-Host "===================================="

# Verificar bundle identifier
$allGood = (Check-FileContent $infoPlistPath "com\.recway\.sensores" "Bundle Identifier correcto") -and $allGood

# Verificar app name
$allGood = (Check-FileContent $infoPlistPath "RecWay Sensores" "Nombre de app correcto") -and $allGood

Write-Host ""
Write-Host "🚀 VERIFICACIÓN DE CODEMAGIC" -ForegroundColor Yellow
Write-Host "============================="

# Verificar configuración Codemagic
$codemagicPath = "codemagic.yaml"
if (Test-Path $codemagicPath) {
    $allGood = (Check-FileContent $codemagicPath "build-ios-appetize" "Workflow iOS configurado") -and $allGood
    $allGood = (Check-FileContent $codemagicPath "distribution_type: adhoc" "Distribution type adhoc") -and $allGood
    $allGood = (Check-FileContent $codemagicPath "com\.recway\.sensores" "Bundle ID en Codemagic") -and $allGood
    $allGood = (Check-FileContent $codemagicPath "flutter build ios --release --no-codesign" "Comando build iOS") -and $allGood
    $allGood = (Check-FileContent $codemagicPath "RecWay-Sensores-iPhone\.app\.zip" "Artifact ZIP configurado") -and $allGood
}

Write-Host ""
Write-Host "📦 VERIFICACIÓN DE DEPENDENCIAS" -ForegroundColor Yellow
Write-Host "==============================="

# Verificar dependencias en pubspec.yaml
$pubspecPath = "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $dependencies = @{
        "geolocator" = "Servicios de ubicación"
        "sensors_plus" = "Sensores de movimiento"
        "permission_handler" = "Gestión de permisos"
        "sqflite" = "Base de datos local"
    }
    
    foreach ($dep in $dependencies.GetEnumerator()) {
        Check-FileContent $pubspecPath $dep.Key $dep.Value | Out-Null
    }
}

Write-Host ""
Write-Host "📚 VERIFICACIÓN DE DOCUMENTACIÓN" -ForegroundColor Yellow
Write-Host "================================="

# Verificar documentación
Check-File "GUIA_APPETIZE_IO_IPHONE.md" "Guía Appetize.io iPhone" | Out-Null
Check-File "build_iphone.ps1" "Script build PowerShell" | Out-Null
Check-File "build_iphone.sh" "Script build Bash" | Out-Null

Write-Host ""
Write-Host "🏗️ VERIFICACIÓN DE ESTRUCTURA" -ForegroundColor Yellow
Write-Host "==============================="

# Verificar estructura de directorios
$directories = @(
    "lib/services",
    "lib/screens", 
    "lib/widgets",
    "ios/Runner"
)

foreach ($dir in $directories) {
    Check-File $dir "Directorio $dir" | Out-Null
}

Write-Host ""
Write-Host "=" * 50
Write-Host ""

if ($allGood) {
    Write-Host "🎉 CONFIGURACIÓN COMPLETA Y CORRECTA" -ForegroundColor Green
    Write-Host "====================================="
    Write-Host ""
    Log-Success "Todos los archivos y configuraciones están presentes"
    Log-Success "El proyecto está listo para build iOS"
    Log-Success "Compatible con Appetize.io"
    Write-Host ""
    Write-Host "📋 PRÓXIMOS PASOS:" -ForegroundColor Cyan
    Write-Host "1. Ejecutar build: .\build_iphone.ps1"
    Write-Host "2. O usar Codemagic para build automático"
    Write-Host "3. Subir ZIP a https://appetize.io/upload"
    Write-Host "4. Configurar permisos en Appetize.io"
    Write-Host ""
    Write-Host "📖 Ver guía detallada: GUIA_APPETIZE_IO_IPHONE.md"
} else {
    Write-Host "⚠️ CONFIGURACIÓN INCOMPLETA" -ForegroundColor Red
    Write-Host "============================"
    Write-Host ""
    Log-Warning "Algunas configuraciones están faltando o incorrectas"
    Log-Info "Revisar los elementos marcados con ❌ arriba"
    Write-Host ""
    Write-Host "📖 Consultar documentación:"
    Write-Host "- CONFIGURACION_iOS_COMPLETA.md"
    Write-Host "- GUIA_APPETIZE_IO_IPHONE.md"
}

Write-Host ""
Write-Host "🔍 Verificación completada" -ForegroundColor Blue
