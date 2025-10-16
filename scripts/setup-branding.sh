#!/bin/bash
# Generate a _branding-vars.css file with dynamic CSS variables from fleio-custom.conf
CONFIG_FILE="/opt/fleio-custom/config/fleio-custom.conf"
OUTPUT_CSS="/opt/fleio-custom/assets/_branding-vars.css"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[branding-setup] Config not found: $CONFIG_FILE"
    exit 1
fi

accent_color=$(awk -F' = ' '/\[branding\]/{a=1} a==1 && $1=="accent_color"{print $2;exit}' "$CONFIG_FILE")
background_theme=$(awk -F' = ' '/\[branding\]/{a=1} a==1 && $1=="background_theme"{print $2;exit}' "$CONFIG_FILE")
secondary_bg="#2c2f33" # fallback/default
txt_primary="#ffffff"
txt_secondary="#b9bbbe"
logo_path=$(awk -F' = ' '/\[branding\]/{a=1} a==1 && $1=="logo_path"{print $2;exit}' "$CONFIG_FILE")

cat > "$OUTPUT_CSS" <<EOF
:root {
    --accent-color: ${accent_color:-#9680fe};
    --background-theme: ${background_theme:-#1a1d21};
    --secondary-bg: ${secondary_bg};
    --text-primary: ${txt_primary};
    --text-secondary: ${txt_secondary};
    /* Optional: logo-path as CSS variable for advanced use */
    --branding-logo-path: url('${logo_path:-/opt/fleio-custom/assets/logo.png}');
}
EOF

echo "[branding-setup] Generated $OUTPUT_CSS with colors: $accent_color $background_theme from config."
