#!/bin/bash

# Script de inicio rápido para Jenkins + sysfoo1
# Autor: Setup automatizado
# Uso: ./start-jenkins-sysfoo1.sh

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  🚀 JENKINS + SYSFOO1 - INICIO RÁPIDO                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Verificar Docker
echo "🔍 Verificando requisitos..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    echo "Instalar desde: https://docs.docker.com/get-docker/"
    exit 1
fi
print_success "Docker instalado"

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose no está instalado"
    echo "Instalar desde: https://docs.docker.com/compose/install/"
    exit 1
fi
print_success "Docker Compose instalado"

# Verificar que Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    print_error "Docker no está corriendo"
    echo "Inicia Docker Desktop o el daemon de Docker"
    exit 1
fi
print_success "Docker está corriendo"

echo ""
echo "🔧 Preparando ambiente..."

# Crear archivo .env si no existe
if [ ! -f .env ]; then
    print_warning "Archivo .env no encontrado, creando desde .env.example..."
    
    if [ -f .env.example ]; then
        cp .env.example .env
        
        # Generar secreto aleatorio
        if command -v openssl &> /dev/null; then
            SECRET=$(openssl rand -hex 32)
            sed -i.bak "s/tu_secreto_aqui/$SECRET/" .env
            rm .env.bak 2>/dev/null || true
            print_success "Archivo .env creado con secreto generado"
        else
            print_warning "Archivo .env creado, pero debes editar JENKINS_AGENT_SECRET manualmente"
        fi
    else
        print_error "No se encontró .env.example"
        exit 1
    fi
else
    print_success "Archivo .env encontrado"
fi

# Crear directorio jenkins_config si no existe
if [ ! -d jenkins_config ]; then
    mkdir -p jenkins_config
    print_success "Directorio jenkins_config creado"
fi

echo ""
echo "🐳 Construyendo imagen Docker de Jenkins..."
docker-compose build

if [ $? -eq 0 ]; then
    print_success "Imagen construida exitosamente"
else
    print_error "Error al construir la imagen"
    exit 1
fi

echo ""
echo "🚀 Iniciando servicios..."
docker-compose up -d

if [ $? -eq 0 ]; then
    print_success "Servicios iniciados"
else
    print_error "Error al iniciar los servicios"
    exit 1
fi

echo ""
echo "⏳ Esperando a que Jenkins esté listo (esto puede tomar 1-2 minutos)..."

# Esperar a que Jenkins esté disponible
TIMEOUT=120
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if docker exec jenkins-master test -f /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; then
        print_success "Jenkins está listo"
        break
    fi
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    echo -n "."
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    print_error "Timeout esperando a Jenkins"
    echo "Revisa los logs: docker-compose logs jenkins"
    exit 1
fi

echo ""
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ JENKINS ESTÁ LISTO                                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
print_info "URL de acceso: http://localhost:8080"
echo ""
print_info "🔑 Contraseña inicial de Jenkins:"
echo ""
docker exec jenkins-master cat /var/jenkins_home/secrets/initialAdminPassword
echo ""
echo ""
print_warning "PRÓXIMOS PASOS:"
echo ""
echo "1. Abrir http://localhost:8080 en tu navegador"
echo "2. Copiar la contraseña mostrada arriba"
echo "3. En 'Customize Jenkins', seleccionar: Install suggested plugins ✅"
echo "4. Esperar a que se instalen los plugins (2-3 minutos)"
echo "5. Configurar Maven y JDK según la GUIA-CONFIGURACION-SYSFOO1.md"
echo "6. Crear el pipeline para sysfoo1"
echo ""
print_info "📦 Sobre los plugins:"
echo "  Los plugins NO están preinstalados para evitar conflictos."
echo "  Se instalarán automáticamente al seleccionar 'Install suggested plugins'."
echo "  Ver detalles en: GUIA-INSTALACION-PLUGINS.md"
echo ""
print_info "Ver logs en tiempo real:"
echo "  docker-compose logs -f jenkins"
echo ""
print_info "Detener Jenkins:"
echo "  docker-compose down"
echo ""
print_info "Reiniciar Jenkins:"
echo "  docker-compose restart jenkins"
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  📚 Consulta GUIA-CONFIGURACION-SYSFOO1.md            ║"
echo "║     para instrucciones detalladas                     ║"
echo "╚════════════════════════════════════════════════════════╝"
