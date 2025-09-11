#!/bin/bash

# Export secrets from Bitwarden to .env file for testing
# This script creates .env file with all secrets for Kamal deployment

echo "🔐 Exporting secrets from Bitwarden to .env file..."

# Check if BW_SESSION is set
if [ -z "$BW_SESSION" ]; then
    echo "❌ BW_SESSION not set. Run: source scripts/bw-unlock.sh"
    exit 1
fi

# Check if Bitwarden is unlocked
STATUS=$(bw status | jq -r .status 2>/dev/null)
if [ "$STATUS" != "unlocked" ]; then
    echo "❌ Bitwarden not unlocked. Status: $STATUS"
    echo "💡 Run: source scripts/bw-unlock.sh"
    exit 1
fi

# Sync with Bitwarden server to get latest changes
echo "🔄 Syncing with Bitwarden server..."
bw sync
echo "✅ Sync complete"

# Create .env file
echo "📝 Creating .env file with secrets..."

cat > .env << EOF
# Mattermost Production Environment Variables
# Generated from Bitwarden on $(date)
# DO NOT COMMIT THIS FILE TO GIT!

# Docker Hub Registry
export KAMAL_REGISTRY_PASSWORD="$(bw get password "Docker Registry Token")"

# PostgreSQL Database
export POSTGRES_PASSWORD="$(bw get password "PostgreSQL Mattermost")"

# Redis Cache
export MM_REDISSETTINGS_PASSWORD="$(bw get password "Redis Mattermost Production")"

# Hetzner S3 Storage
export MM_FILESETTINGS_AMAZONS3ACCESSKEYID="$(bw get username "Hetzner S3 Secret sputnikgel")"
export MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY="$(bw get password "Hetzner S3 Secret sputnikgel")"

# Grafana Monitoring
export GF_SECURITY_ADMIN_PASSWORD="$(bw get password "Grafana Admin")"

# Keycloak SSO
export KEYCLOAK_ADMIN_PASSWORD="$(bw get password "Keycloak Admin")"
export KEYCLOAK_DB_PASSWORD="$(bw get password "Keycloak Database")"

# Elasticsearch Search
export ELASTICSEARCH_PASSWORD="$(bw get password "Elasticsearch Mattermost")"
EOF

# Set permissions
chmod 600 .env

echo "✅ .env file created successfully!"
echo "🔒 Permissions set to 600 (owner read/write only)"
echo ""
echo "📋 Usage:"
echo "   source .env     # Load variables"
echo "   kamal setup     # Setup with loaded variables"
echo "   kamal deploy    # Deploy with loaded variables"
echo ""
echo "⚠️  IMPORTANT: Delete .env file after testing!"
echo "   rm .env"
echo ""
echo "🔐 For production use Bitwarden: source scripts/bw-unlock.sh"
