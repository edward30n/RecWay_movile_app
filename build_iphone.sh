#!/bin/bash

# Script de build para iPhone únicamente (Appetize.io)
# RecWay Sensores - iOS Build Script

echo "🍎 RecWay Sensores - iPhone Build para Appetize.io"
echo "=================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logs
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar dependencias
log_info "Verificando dependencias..."

if ! command -v flutter &> /dev/null; then
    log_error "Flutter no encontrado. Instalar Flutter primero."
    exit 1
fi

if ! command -v pod &> /dev/null; then
    log_warning "CocoaPods no encontrado. Instalando..."
    sudo gem install cocoapods
fi

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    log_error "No se encontró pubspec.yaml. Ejecutar desde el directorio raíz del proyecto."
    exit 1
fi

# Verificar que existe el directorio iOS
if [ ! -d "ios" ]; then
    log_error "Directorio ios/ no encontrado."
    exit 1
fi

log_success "Dependencias verificadas"

# Paso 1: Limpiar proyecto
log_info "Limpiando proyecto..."
flutter clean
log_success "Proyecto limpiado"

# Paso 2: Obtener dependencias Flutter
log_info "Obteniendo dependencias Flutter..."
flutter pub get
if [ $? -ne 0 ]; then
    log_error "Error al obtener dependencias Flutter"
    exit 1
fi
log_success "Dependencias Flutter obtenidas"

# Paso 3: Instalar dependencias iOS (CocoaPods)
log_info "Instalando dependencias iOS (CocoaPods)..."
cd ios
pod install
if [ $? -ne 0 ]; then
    log_error "Error al instalar CocoaPods"
    cd ..
    exit 1
fi
cd ..
log_success "Dependencias iOS instaladas"

# Paso 4: Verificar configuración iOS
log_info "Verificando configuración iOS..."

# Verificar Info.plist
if [ ! -f "ios/Runner/Info.plist" ]; then
    log_error "Info.plist no encontrado"
    exit 1
fi

# Verificar que tiene permisos básicos
if grep -q "NSLocationWhenInUseUsageDescription" ios/Runner/Info.plist; then
    log_success "Permisos de ubicación configurados"
else
    log_warning "Permisos de ubicación no encontrados en Info.plist"
fi

# Paso 5: Build iOS para iPhone
log_info "Construyendo iOS para iPhone (Appetize.io compatible)..."
log_warning "Esto puede tomar varios minutos..."

flutter build ios --release --no-codesign

if [ $? -ne 0 ]; then
    log_error "Error en el build de iOS"
    exit 1
fi

log_success "Build de iOS completado"

# Paso 6: Verificar que el build existe
if [ ! -d "build/ios/iphoneos/Runner.app" ]; then
    log_error "Runner.app no encontrado después del build"
    exit 1
fi

log_success "Runner.app generado correctamente"

# Paso 7: Crear ZIP para Appetize.io
log_info "Creando archivo ZIP para Appetize.io..."

cd build/ios/iphoneos

# Eliminar ZIP anterior si existe
if [ -f "RecWay-Sensores-iPhone.app.zip" ]; then
    rm RecWay-Sensores-iPhone.app.zip
    log_info "ZIP anterior eliminado"
fi

# Crear nuevo ZIP
zip -r RecWay-Sensores-iPhone.app.zip Runner.app

if [ $? -ne 0 ]; then
    log_error "Error al crear ZIP"
    cd ../../..
    exit 1
fi

cd ../../..

log_success "ZIP creado: build/ios/iphoneos/RecWay-Sensores-iPhone.app.zip"

# Paso 8: Información final
echo ""
echo "🎉 BUILD COMPLETADO EXITOSAMENTE"
echo "================================"
echo ""
log_info "Archivo generado: ${PWD}/build/ios/iphoneos/RecWay-Sensores-iPhone.app.zip"
echo ""
log_info "Próximos pasos:"
echo "1. Ir a https://appetize.io/upload"
echo "2. Seleccionar iOS como plataforma"
echo "3. Subir el archivo RecWay-Sensores-iPhone.app.zip"
echo "4. Configurar device: iPhone (cualquier modelo reciente)"
echo "5. Habilitar Location Services y Motion & Orientation"
echo ""
log_warning "IMPORTANTE: Configurar permisos en Appetize.io:"
echo "   ✅ Location Services: ENABLED"
echo "   ✅ Motion & Orientation: ENABLED"
echo "   ✅ Background App Refresh: ENABLED"
echo ""
log_info "Para más detalles, ver: GUIA_APPETIZE_IO_IPHONE.md"
echo ""

# Mostrar tamaño del archivo
if [ -f "build/ios/iphoneos/RecWay-Sensores-iPhone.app.zip" ]; then
    file_size=$(du -h "build/ios/iphoneos/RecWay-Sensores-iPhone.app.zip" | cut -f1)
    log_info "Tamaño del archivo: $file_size"
fi

log_success "Script completado exitosamente! 🚀"
