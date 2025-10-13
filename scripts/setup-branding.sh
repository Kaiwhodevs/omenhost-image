#!/bin/bash
# Setup custom branding for Fleio

echo "Setting up custom branding..."

# Create custom CSS file
cat > /opt/fleio-custom/assets/custom.css << EOF
/* Custom Fleio Branding CSS */
:root {
    --accent-color: ${FLEIO_ACCENT_COLOR};
    --background-theme: ${FLEIO_BACKGROUND_THEME};
}

/* Apply accent color to various elements */
.btn-primary, .btn-accent {
    background-color: var(--accent-color) !important;
    border-color: var(--accent-color) !important;
}

.navbar-brand, .logo {
    color: var(--accent-color) !important;
}

/* Apply background theme */
body, .main-content {
    background-color: var(--background-theme) !important;
}

/* Discord-like styling for custom pages */
.discord-theme {
    background: linear-gradient(135deg, #1a1d21 0%, #2c2f33 100%);
    color: #ffffff;
    font-family: 'Whitney', 'Helvetica Neue', Helvetica, Arial, sans-serif;
}

.discord-theme .card {
    background: rgba(47, 49, 54, 0.8);
    border: 1px solid #40444b;
    border-radius: 8px;
}

.discord-theme .form-control {
    background: #40444b;
    border: 1px solid #40444b;
    color: #ffffff;
}

.discord-theme .form-control:focus {
    background: #40444b;
    border-color: var(--accent-color);
    color: #ffffff;
    box-shadow: 0 0 0 0.2rem rgba(150, 128, 254, 0.25);
}
EOF

# Copy logo and favicon if they exist
if [ -f "$FLEIO_LOGO_PATH" ]; then
    cp "$FLEIO_LOGO_PATH" /opt/fleio/static/images/logo.png
fi

if [ -f "$FLEIO_FAVICON_PATH" ]; then
    cp "$FLEIO_FAVICON_PATH" /opt/fleio/static/images/favicon.ico
fi

echo "Branding setup complete"
