#!/bin/bash
set -e

# Custom Fleio Docker Entrypoint
# This script handles initialization and startup of the custom Fleio container

echo "Starting Custom Fleio Docker Container..."

# Function to load configuration
load_config() {
    if [ -f "/opt/fleio-custom/config/fleio-custom.conf" ]; then
        echo "Loading custom configuration..."
        source /opt/fleio-custom/scripts/load-config.sh
    fi
}

# Function to setup branding
setup_branding() {
    echo "Setting up custom branding..."
    if [ -f "/opt/fleio-custom/scripts/setup-branding.sh" ]; then
        /opt/fleio-custom/scripts/setup-branding.sh
    fi
}

# Function to setup NOWPayments integration
setup_nowpayments() {
    echo "Setting up NOWPayments integration..."
    if [ -f "/opt/fleio-custom/scripts/setup-nowpayments.sh" ]; then
        /opt/fleio-custom/scripts/setup-nowpayments.sh
    fi
}

# Function to setup backup system
setup_backup() {
    echo "Setting up backup system..."
    if [ -f "/opt/fleio-custom/scripts/setup-backup.sh" ]; then
        /opt/fleio-custom/scripts/setup-backup.sh
    fi
}

# Function to apply custom pages
apply_custom_pages() {
    echo "Applying custom pages..."
    if [ -f "/opt/fleio-custom/scripts/apply-custom-pages.sh" ]; then
        /opt/fleio-custom/scripts/apply-custom-pages.sh
    fi
}

# Function to setup Fleio customizations
setup_fleio_customizations() {
    echo "Setting up Fleio customizations..."
    
    # Copy custom templates to Fleio directories
    if [ -d "/opt/fleio-custom/templates" ]; then
        echo "Copying custom templates..."
        cp -r /opt/fleio-custom/templates/* /opt/fleio/templates/ 2>/dev/null || true
    fi
    
    # Copy custom static files
    if [ -d "/opt/fleio-custom/assets" ]; then
        echo "Copying custom assets..."
        cp -r /opt/fleio-custom/assets/* /opt/fleio/static/ 2>/dev/null || true
    fi
    
    # Apply custom CSS
    if [ -f "/opt/fleio-custom/assets/custom.css" ]; then
        echo "Applying custom CSS..."
        cat /opt/fleio-custom/assets/custom.css >> /opt/fleio/static/css/main.css 2>/dev/null || true
    fi
}

# Function to start cron for backups
start_backup_cron() {
    echo "Starting backup cron service..."
    service cron start
}

# Function to wait for database
wait_for_database() {
    echo "Waiting for database to be ready..."
    while ! nc -z db 5432; do
        sleep 1
    done
    echo "Database is ready!"
}

# Main initialization
main() {
    echo "Initializing Custom Fleio..."
    
    # Wait for database
    wait_for_database
    
    # Load configuration
    load_config
    
    # Setup Fleio customizations
    setup_fleio_customizations
    
    # Setup components
    setup_branding
    setup_nowpayments
    setup_backup
    apply_custom_pages
    
    # Start backup cron
    start_backup_cron
    
    echo "Custom Fleio initialization complete!"
    echo "Starting Fleio server..."
}

# Run main function
main

# Execute the main command (Fleio's original entrypoint)
exec "$@"
