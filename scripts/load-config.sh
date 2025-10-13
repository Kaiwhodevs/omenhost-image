#!/bin/bash
# Load configuration from fleio-custom.conf

CONFIG_FILE="/opt/fleio-custom/config/fleio-custom.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Function to get config value
get_config() {
    local section=$1
    local key=$2
    local default=$3
    
    # Extract value from config file
    local value=$(awk -F' = ' -v section="$section" -v key="$key" '
        /^\[.*\]$/ { current_section = substr($0, 2, length($0)-2) }
        current_section == section && $1 == key { print $2 }
    ' "$CONFIG_FILE")
    
    if [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Load branding configuration
export FLEIO_ACCENT_COLOR=$(get_config "branding" "accent_color" "#9680fe")
export FLEIO_BACKGROUND_THEME=$(get_config "branding" "background_theme" "#1a1d21")
export FLEIO_LOGO_PATH=$(get_config "branding" "logo_path" "/opt/fleio-custom/assets/logo.png")
export FLEIO_FAVICON_PATH=$(get_config "branding" "favicon_path" "/opt/fleio-custom/assets/favicon.ico")
export FLEIO_SITE_NAME=$(get_config "branding" "site_name" "Custom Fleio Hosting")
export FLEIO_SITE_TAGLINE=$(get_config "branding" "site_tagline" "Professional Hosting Solutions")
export FLEIO_SUPPORT_EMAIL=$(get_config "branding" "support_email" "support@customfleio.com")
export FLEIO_CUSTOM_CSS_PATH=$(get_config "branding" "custom_css_path" "/opt/fleio-custom/assets/custom.css")

# Load backup configuration
export FLEIO_S3_BUCKET=$(get_config "backup" "s3_bucket" "")
export FLEIO_S3_REGION=$(get_config "backup" "s3_region" "us-east-1")
export FLEIO_S3_ACCESS_KEY=$(get_config "backup" "s3_access_key" "")
export FLEIO_S3_SECRET_KEY=$(get_config "backup" "s3_secret_key" "")
export FLEIO_BACKUP_FREQUENCY=$(get_config "backup" "backup_frequency" "daily")
export FLEIO_BACKUP_RETENTION_DAYS=$(get_config "backup" "backup_retention_days" "30")
export FLEIO_BACKUP_ENCRYPTION_KEY=$(get_config "backup" "backup_encryption_key" "")

# Load NOWPayments configuration
export FLEIO_NOWPAYMENTS_API_KEY=$(get_config "nowpayments" "api_key" "")
export FLEIO_NOWPAYMENTS_IPN_SECRET=$(get_config "nowpayments" "ipn_secret" "")
export FLEIO_NOWPAYMENTS_SANDBOX=$(get_config "nowpayments" "sandbox_mode" "false")
export FLEIO_NOWPAYMENTS_CRYPTO=$(get_config "nowpayments" "supported_crypto" "BTC,ETH,LTC,USDT,USDC")

# Load page configuration
export FLEIO_CUSTOM_PAGES_ENABLED=$(get_config "pages" "enable_custom_pages" "true")
export FLEIO_DISCORD_THEME=$(get_config "pages" "discord_theme" "true")

# Load security configuration
export FLEIO_BACKUP_ENCRYPTION_ENABLED=$(get_config "security" "backup_encryption_enabled" "true")
export FLEIO_BACKUP_ENCRYPTION_ALGORITHM=$(get_config "security" "backup_encryption_algorithm" "AES256")

echo "Configuration loaded successfully"
