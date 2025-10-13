# Custom Fleio Docker Image - Deployment Guide

This guide provides step-by-step instructions for building, configuring, and deploying the custom Fleio Docker image.

## Prerequisites

- Docker and Docker Compose installed
- Access to official Fleio Docker images
- S3-compatible storage (for backups)
- NOWPayments API credentials (optional)

## Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd fleio-custom-docker
```

### 2. Configure Environment Variables

Copy the example environment file and configure your settings:

```bash
cp env.example .env
```

Edit `.env` with your configuration:

```bash
# Branding Configuration
FLEIO_ACCENT_COLOR=#9680fe
FLEIO_BACKGROUND_THEME=#1a1d21
FLEIO_SITE_NAME="Your Hosting Company"

# NOWPayments Configuration
FLEIO_NOWPAYMENTS_API_KEY=your_api_key_here
FLEIO_NOWPAYMENTS_IPN_SECRET=your_ipn_secret_here

# S3 Backup Configuration
FLEIO_S3_BUCKET=your-backup-bucket
FLEIO_S3_ACCESS_KEY=your_access_key
FLEIO_S3_SECRET_KEY=your_secret_key
FLEIO_BACKUP_ENCRYPTION_KEY=your_encryption_key

# Database Configuration
FLEIO_DB_PASSWORD=your_secure_password
```

### 3. Build Custom Images

Run the build script:

```bash
./build.sh
```

This will:
- Build the custom Fleio backend image
- Build the custom Fleio frontend image
- Update configuration files with environment variables

### 4. Deploy with Docker Compose

#### Option A: Deploy to Existing Fleio Installation

If you have an existing Fleio installation:

```bash
# Copy the override file to your Fleio installation
cp docker-compose.override.yml /home/fleio/compose/

# Navigate to Fleio directory
cd /home/fleio/compose

# Build and start the custom Fleio
docker-compose build
docker-compose up -d
```

#### Option B: Deploy as Standalone

Create a new `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: fleio
      POSTGRES_USER: fleio
      POSTGRES_PASSWORD: ${FLEIO_DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:6-alpine
    command: redis-server --requirepass ${FLEIO_REDIS_PASSWORD}

  backend:
    build:
      context: .
      dockerfile: Dockerfile
    image: custom-fleio-backend:latest
    environment:
      - FLEIO_DB_HOST=db
      - FLEIO_DB_PASSWORD=${FLEIO_DB_PASSWORD}
      - FLEIO_REDIS_HOST=redis
      - FLEIO_REDIS_PASSWORD=${FLEIO_REDIS_PASSWORD}
    depends_on:
      - db
      - redis
    volumes:
      - fleio_data:/opt/fleio/data

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    image: custom-fleio-frontend:latest
    depends_on:
      - backend

volumes:
  postgres_data:
  fleio_data:
```

Then deploy:

```bash
docker-compose up -d
```

## Configuration

### Branding Configuration

The custom Fleio image supports extensive branding configuration through the `config/fleio-custom.conf` file:

```ini
[branding]
# Accent color for the entire system
accent_color = #9680fe

# Background theme color
background_theme = #1a1d21

# Site branding
site_name = Custom Fleio Hosting
site_tagline = Professional Hosting Solutions
support_email = support@customfleio.com

# Logo configuration
logo_path = /opt/fleio-custom/assets/logo.png
favicon_path = /opt/fleio-custom/assets/favicon.ico
```

### NOWPayments Integration

Configure cryptocurrency payments:

```ini
[nowpayments]
# NOWPayments API credentials
api_key = your_api_key
ipn_secret = your_ipn_secret
sandbox_mode = false

# Supported cryptocurrencies
supported_crypto = BTC,ETH,LTC,USDT,USDC,BNB,ADA,DOT,DOGE,SHIB
```

### Backup Configuration

Set up automated encrypted backups:

```ini
[backup]
# S3 configuration
s3_bucket = your-backup-bucket
s3_region = us-east-1
s3_access_key = your_access_key
s3_secret_key = your_secret_key

# Backup settings
backup_frequency = daily
backup_retention_days = 30
backup_encryption_key = your_encryption_key
```

## Customization

### Adding Custom Assets

1. Place your logo in `assets/logo.png`
2. Place your favicon in `assets/favicon.ico`
3. Add custom CSS to `assets/custom.css`
4. Rebuild the images: `./build.sh`

### Modifying Templates

1. Edit templates in `templates/client/`
2. Update configuration in `config/fleio-custom.conf`
3. Rebuild the images: `./build.sh`

### Adding Payment Methods

1. Create payment processor in `scripts/`
2. Update configuration file
3. Add corresponding templates
4. Rebuild the images: `./build.sh`

## Monitoring and Maintenance

### Health Checks

The custom Fleio image includes health checks for:
- Database connectivity
- Payment processor status
- Backup system health
- Disk space monitoring

### Logs

Monitor the following log files:
- Application logs: `/var/log/fleio/`
- Backup logs: `/var/log/fleio-backup.log`
- Payment logs: `/var/log/nowpayments.log`

### Backup Management

#### Manual Backup

```bash
# Create manual backup
docker exec fleio-backend /opt/fleio-custom/scripts/backup-fleio.sh
```

#### Restore from Backup

```bash
# Restore from backup
docker exec fleio-backend /opt/fleio-custom/scripts/restore-fleio.sh /path/to/backup.tar.gz
```

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

### Getting Help

For issues and questions:
- Check the troubleshooting section
- Review Fleio documentation
- Contact support at support@customfleio.com

## Security Considerations

- Keep API keys secure
- Use HTTPS in production
- Regularly update dependencies
- Monitor backup integrity
- Implement proper access controls

## License

This project extends the official Fleio platform. Please refer to Fleio's licensing terms for commercial use.
