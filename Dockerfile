# Custom Fleio Docker Image
# Based on the official Fleio backend image

FROM hub.fleio.com/fleio_backend-2025-06:1

# Set environment variables
ENV FLEIO_CUSTOM_BRANDING=true
ENV FLEIO_NOWPAYMENTS_ENABLED=true
ENV FLEIO_CUSTOM_PAGES_ENABLED=true

# Create custom directories
RUN mkdir -p /opt/fleio-custom/{assets,config,scripts,templates}
RUN mkdir -p /var/backups/fleio/{database,settings}

# Copy custom configuration
COPY config/fleio-custom.conf /opt/fleio-custom/config/
COPY scripts/ /opt/fleio-custom/scripts/
RUN chmod +x /opt/fleio-custom/scripts/*.sh

# Copy custom assets
COPY assets/ /opt/fleio-custom/assets/

# Copy custom templates
COPY templates/ /opt/fleio-custom/templates/

# Copy custom entrypoint
COPY docker-entrypoint.sh /opt/fleio-custom/
RUN chmod +x /opt/fleio-custom/docker-entrypoint.sh

# Install additional dependencies for customizations
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    awscli \
    gpg \
    openssl \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages for S3 encryption and NOWPayments
RUN pip install --no-cache-dir \
    boto3 \
    cryptography \
    requests \
    python-gnupg

# Set proper permissions
RUN chown -R fleio:fleio /opt/fleio-custom
RUN chown -R fleio:fleio /var/backups/fleio

# Use custom entrypoint
ENTRYPOINT ["/opt/fleio-custom/docker-entrypoint.sh"]