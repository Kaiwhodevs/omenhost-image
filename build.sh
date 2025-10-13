#!/bin/bash
# Custom Fleio Docker Image Build Script

set -e

echo "🚀 Building Custom Fleio Docker Image..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose is not installed. Please install docker-compose and try again."
    exit 1
fi

# Load environment variables if .env file exists
if [ -f ".env" ]; then
    print_status "Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values
FLEIO_ACCENT_COLOR=${FLEIO_ACCENT_COLOR:-"#9680fe"}
FLEIO_BACKGROUND_THEME=${FLEIO_BACKGROUND_THEME:-"#1a1d21"}
FLEIO_SITE_NAME=${FLEIO_SITE_NAME:-"Custom Fleio Hosting"}

print_status "Configuration:"
echo "  - Accent Color: $FLEIO_ACCENT_COLOR"
echo "  - Background Theme: $FLEIO_BACKGROUND_THEME"
echo "  - Site Name: $FLEIO_SITE_NAME"

# Update configuration file with environment variables
print_status "Updating configuration file..."
if [ -n "$FLEIO_ACCENT_COLOR" ]; then
    sed -i "s/accent_color = .*/accent_color = $FLEIO_ACCENT_COLOR/" config/fleio-custom.conf
fi

if [ -n "$FLEIO_BACKGROUND_THEME" ]; then
    sed -i "s/background_theme = .*/background_theme = $FLEIO_BACKGROUND_THEME/" config/fleio-custom.conf
fi

if [ -n "$FLEIO_SITE_NAME" ]; then
    sed -i "s/site_name = .*/site_name = $FLEIO_SITE_NAME/" config/fleio-custom.conf
fi

# Build custom Fleio backend image
print_status "Building custom Fleio backend image..."
docker build -t custom-fleio-backend:latest -f Dockerfile .

if [ $? -eq 0 ]; then
    print_success "Backend image built successfully"
else
    print_error "Failed to build backend image"
    exit 1
fi

# Build custom Fleio frontend image
print_status "Building custom Fleio frontend image..."
docker build -t custom-fleio-frontend:latest -f Dockerfile.frontend .

if [ $? -eq 0 ]; then
    print_success "Frontend image built successfully"
else
    print_error "Failed to build frontend image"
    exit 1
fi

# Create docker-compose.override.yml if it doesn't exist
if [ ! -f "docker-compose.override.yml" ]; then
    print_warning "docker-compose.override.yml not found. Creating from template..."
    cp docker-compose.override.yml docker-compose.override.yml
fi

print_success "Custom Fleio Docker images built successfully!"
echo ""
print_status "Next steps:"
echo "1. Copy docker-compose.override.yml to your Fleio installation directory"
echo "2. Configure your environment variables in .env file"
echo "3. Run: docker-compose up -d"
echo ""
print_status "For more information, see README.md"
