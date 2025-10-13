# Custom Fleio Docker Image

A custom Docker image for the Fleio hosting platform with Discord-inspired branding, NOWPayments cryptocurrency integration, and automated backup system.

## Overview

This project provides a customized version of the official Fleio hosting platform with:
- **Discord-inspired UI**: Modern dark theme with purple accent colors
- **NOWPayments Integration**: Cryptocurrency payment processing
- **Automated Backups**: S3-compatible backup system
- **Custom Branding**: Configurable logos, colors, and styling
- **Enhanced Security**: Two-factor authentication and advanced security features

## Architecture

This is a **custom Fleio Docker image** that extends the official Fleio platform with:
- Custom Dockerfile extending `hub.fleio.com/fleio_backend-2025-06:1`
- Docker Compose override configuration
- Custom templates and static assets
- Payment processor integration
- Backup and monitoring systems

## Project Structure

```
fleio-custom-docker/
├── Dockerfile                    # Custom Fleio backend image
├── Dockerfile.frontend          # Custom Fleio frontend image
├── docker-compose.override.yml  # Docker Compose overrides
├── docker-entrypoint.sh         # Custom container entrypoint
├── config/
│   └── fleio-custom.conf        # Configuration file
├── assets/
│   └── custom.css               # Custom styling
├── templates/
│   └── client/                  # Custom page templates
│       ├── login/
│       ├── signup/
│       └── reset-password/
├── scripts/
│   ├── load-config.sh           # Configuration loader
│   ├── setup-branding.sh        # Branding setup
│   ├── setup-nowpayments.sh     # Payment integration
│   └── setup-backup.sh          # Backup system
└── README.md
```

## Features

### 🎨 Custom Branding
- Discord-inspired dark theme
- Configurable accent colors and logos
- Custom CSS styling
- Responsive design

### 💳 Payment Integration
- NOWPayments cryptocurrency support
- Multiple crypto currencies (BTC, ETH, LTC, USDT, USDC, etc.)
- Secure IPN callbacks
- Payment status tracking

### 💾 Automated Backups
- Database, settings, and uploads backup
- S3-compatible storage
- Configurable retention policies
- Encryption support

### 🔒 Enhanced Security
- Two-factor authentication
- Password strength requirements
- Session management
- Login attempt limiting

### 🖥️ Custom Pages
- Discord-themed login page
- Enhanced signup with validation
- Custom password reset flow
- Branded dashboard interface

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Access to official Fleio Docker images (`hub.fleio.com/fleio_backend-2025-06:1`)
- S3-compatible storage (for encrypted backups)
- NOWPayments API credentials (for cryptocurrency payments)

### 1. Clone and Configure

```bash
git clone <repository-url>
cd fleio-custom-docker
```

### 2. Configure Environment Variables

```bash
# Copy example environment file
cp env.example .env

# Edit with your configuration
nano .env
```

### 3. Build Custom Images

```bash
# Run the automated build script
./build.sh
```

### 4. Deploy with Docker Compose

#### Option A: Deploy to Existing Fleio Installation

```bash
# Copy override file to existing Fleio installation
cp docker-compose.override.yml /home/fleio/compose/

# Build and start custom Fleio
cd /home/fleio/compose
docker-compose build
docker-compose up -d
```

#### Option B: Deploy as Standalone

```bash
# Use the provided docker-compose.override.yml
docker-compose -f docker-compose.override.yml up -d
```

### 5. Verify Installation

- Access the Fleio admin panel
- Check that Discord-like branding is applied
- Test NOWPayments cryptocurrency integration
- Verify encrypted backup system is running
- Test custom login/signup pages

## Configuration

### Branding Configuration

```ini
[branding]
accent_color = #9680fe              # Primary accent color
background_theme = #1a1d21          # Background color
site_name = Custom Fleio Hosting    # Site name
logo_path = /path/to/logo.png       # Logo file
custom_css_path = /path/to/css      # Additional CSS
```

### NOWPayments Configuration

```ini
[nowpayments]
api_key = your_api_key              # NOWPayments API key
ipn_secret = your_ipn_secret        # IPN secret for callbacks
sandbox_mode = false                # Use sandbox mode
supported_crypto = BTC,ETH,LTC      # Supported cryptocurrencies
```

### Backup Configuration

```ini
[backup]
s3_bucket = your-backup-bucket      # S3 bucket name
s3_region = us-east-1               # AWS region OR compatible provider region
s3_endpoint_url = https://s3.wasabisys.com   # (default: Wasabi; use your provider's endpoint)
backup_frequency = daily            # Backup frequency
backup_retention_days = 30          # Retention period
```

By default, we use Wasabi as a popular, fully compatible S3 alternative. For other providers, set `s3_endpoint_url` accordingly (e.g., MinIO, DigitalOcean Spaces, etc).

## Customization

### Adding Custom Templates

1. Create template files in `templates/client/`
2. Update `config/fleio-custom.conf` to reference new templates
3. Rebuild the Docker image

### Modifying Styling

1. Edit `assets/custom.css`
2. Add custom assets to `assets/` directory
3. Rebuild the frontend image

### Adding Payment Methods

1. Create new payment processor in `scripts/`
2. Update configuration file
3. Add corresponding templates

## API Endpoints

### NOWPayments Integration
- `POST /billing/nowpayments/create/` - Create payment
- `POST /billing/nowpayments/callback/` - IPN callback
- `GET /billing/nowpayments/status/` - Payment status

### Backup Management
- `POST /admin/backup/create/` - Create manual backup
- `GET /admin/backup/list/` - List backups
- `POST /admin/backup/restore/` - Restore from backup

## Monitoring

### Health Checks
- Database connectivity
- Payment processor status
- Backup system health
- Disk space monitoring

### Logs
- Application logs: `/var/log/fleio/`
- Backup logs: `/var/log/fleio-backup.log`
- Payment logs: `/var/log/nowpayments.log`

## Troubleshooting

### Common Issues

1. **Custom branding not applied**
   - Check that assets are properly mounted
   - Verify CSS file is accessible
   - Clear browser cache

2. **Payment integration not working**
   - Verify API keys are correct
   - Check IPN callback URL
   - Ensure webhook endpoints are accessible

3. **Backup system not running**
   - Check S3 credentials
   - Verify backup directory permissions
   - Review cron job configuration

### Debug Mode

Enable debug mode in `config/fleio-custom.conf`:

```ini
[debug]
enable_debug = true
log_level = DEBUG
```

## Security Considerations

- Keep API keys secure
- Use HTTPS in production
- Regularly update dependencies
- Monitor backup integrity
- Implement proper access controls

## Support

For issues and questions:
- Check the troubleshooting section
- Review Fleio documentation
- Contact support at support@customfleio.com

## License

This project extends the official Fleio platform. Please refer to Fleio's licensing terms for commercial use.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## ✅ Deliverables Checklist

### 1. Custom Fleio Docker Image ✅
- **Status**: Complete
- **Details**: Extends official Fleio image (`hub.fleio.com/fleio_backend-2025-06:1`)
- **Files**: `Dockerfile`, `Dockerfile.frontend`, `docker-compose.override.yml`

### 2. Branding Configuration ✅
- **Status**: Complete
- **Accent Color**: `#9680fe` (configurable via config file and environment variables)
- **Logo & Favicon**: Configurable for both staff and client areas
- **S3 Credentials**: Configurable for encrypted backups
- **Files**: `config/fleio-custom.conf`, `scripts/load-config.sh`

### 3. Custom Pages ✅
- **Status**: Complete
- **Design**: Discord-like aesthetic with `#1a1d21` background
- **Pages**: Login, signup, forgot-password, reset-password with on-brand design
- **Files**: 
  - `templates/client/login/custom_login.html`
  - `templates/client/signup/custom_signup.html`
  - `templates/client/forgot-password/custom_forgot.html`
  - `templates/client/reset-password/custom_reset.html`

### 4. NOWPayments Integration ✅
- **Status**: Complete
- **Features**: Fully functional integration with Fleio billing
- **IPN Callbacks**: Secure signature verification and payment processing
- **Files**: `scripts/setup-nowpayments.sh`, payment processor implementation

### 5. Encrypted Database Backups to S3 ✅
- **Status**: Complete
- **Command**: Uses official `fleio backup now` command
- **Data**: Database + `/var/lib/docker/volumes/fleio_settings/` directory
- **Encryption**: AES256 encryption before S3 upload
- **Files**: `scripts/setup-backup.sh`, `scripts/backup-fleio.sh`

### 6. Documentation ✅
- **Status**: Complete
- **Build Instructions**: `build.sh` script with automated build process
- **Deployment Guide**: `DEPLOYMENT.md` with step-by-step instructions
- **Configuration**: Environment variables and config file documentation
- **Files**: `README.md`, `DEPLOYMENT.md`, `env.example`

## Changelog

### v1.0.0
- ✅ Custom Fleio Docker image extending official image
- ✅ Discord-inspired branding with configurable accent colors
- ✅ NOWPayments cryptocurrency integration with IPN callbacks
- ✅ Encrypted S3 backup system using official Fleio backup command
- ✅ Custom page templates with Discord-like aesthetic
- ✅ Comprehensive documentation and deployment guides
