#!/bin/bash

# Официальная сборка Bau-Portal для Production
# Основано на официальных Makefile командах Mattermost

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} Bau-Portal Production Build${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Go
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed. Please install Go 1.22 or later."
        exit 1
    fi
    
    GO_VERSION=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | sed 's/go//')
    print_status "Go version: $GO_VERSION"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js 20 or later."
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    print_status "Node.js version: $NODE_VERSION"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed."
        exit 1
    fi
    
    # Check make
    if ! command -v make &> /dev/null; then
        print_error "make is not installed."
        exit 1
    fi
    
    print_status "✅ All prerequisites satisfied"
}

# Setup build environment
setup_environment() {
    print_status "Setting up build environment..."
    
    # Build variables
    export BUILD_NUMBER="${BUILD_NUMBER:-1.0.0-bau-portal}"
    export BUILD_ENTERPRISE="${BUILD_ENTERPRISE:-false}"
    export BUILD_TAGS="production"
    export BUILD_TYPE_NAME="bau-portal"
    
    print_status "Build Number: $BUILD_NUMBER"
    print_status "Enterprise: $BUILD_ENTERPRISE"
    print_status "Build Tags: $BUILD_TAGS"
}

# Build webapp using official Makefile
build_webapp() {
    print_status "Building webapp using official Makefile..."
    
    cd webapp
    
    # Clean previous build
    if [ -d "channels/dist" ]; then
        print_status "Cleaning previous webapp build..."
        make clean
    fi
    
    # Install dependencies and build
    print_status "Installing webapp dependencies..."
    make node_modules
    
    print_status "Building webapp for production..."
    make dist
    
    if [ ! -d "channels/dist" ]; then
        print_error "Webapp build failed - dist directory not found"
        exit 1
    fi
    
    print_status "✅ Webapp build completed"
    cd ..
}

# Build server using official Makefile
build_server() {
    print_status "Building server using official Makefile..."
    
    cd server
    
    # Setup Go workspace if enterprise exists
    if [ -d "../../enterprise" ]; then
        print_status "Setting up Go workspace for enterprise..."
        make setup-go-work
    fi
    
    # Clean previous build
    if [ -d "dist" ]; then
        print_status "Cleaning previous server build..."
        rm -rf dist
    fi
    
    # Build server
    print_status "Building server for Linux AMD64..."
    make build-linux
    
    if [ ! -f "dist/mattermost/bin/mattermost" ]; then
        print_error "Server build failed - binary not found"
        exit 1
    fi
    
    print_status "✅ Server build completed"
    cd ..
}

# Create distribution package
create_package() {
    print_status "Creating distribution package..."
    
    cd server
    
    # Prepare package using official command
    print_status "Preparing package structure..."
    make package-prep
    
    # Create tar.gz package
    print_status "Creating tar.gz package..."
    make package-linux
    
    # Check if package was created
    if [ -f "dist/mattermost-team-linux-amd64.tar.gz" ]; then
        PACKAGE_SIZE=$(du -h "dist/mattermost-team-linux-amd64.tar.gz" | cut -f1)
        print_status "✅ Package created: dist/mattermost-team-linux-amd64.tar.gz ($PACKAGE_SIZE)"
    else
        print_error "Package creation failed"
        exit 1
    fi
    
    cd ..
}

# Customize for Bau-Portal
customize_bau_portal() {
    print_status "Customizing for Bau-Portal..."
    
    cd server/dist/mattermost
    
    # Create custom config
    print_status "Creating Bau-Portal configuration..."
    
    # Backup original config
    cp config/config.json config/config.json.original
    
    # Modify config for Bau-Portal
    cat > config/bau-portal-config.json << 'EOF'
{
  "ServiceSettings": {
    "SiteURL": "https://chat.bau-portal.online",
    "ListenAddress": ":8065",
    "ConnectionSecurity": "",
    "TLSCertFile": "",
    "TLSKeyFile": "",
    "UseLetsEncrypt": false,
    "LetsEncryptCertificateCacheFile": "./config/letsencrypt.cache",
    "Forward80To443": false,
    "ReadTimeout": 300,
    "WriteTimeout": 300,
    "MaximumLoginAttempts": 10,
    "EnableLocalMode": false
  },
  "TeamSettings": {
    "SiteName": "Bau-Portal",
    "MaxUsersPerTeam": 50,
    "EnableTeamCreation": true,
    "EnableUserCreation": true,
    "EnableOpenServer": false,
    "RestrictCreationToDomains": "bau-portal.online",
    "EnableCustomBrand": true,
    "CustomBrandText": "Bau-Portal",
    "CustomDescriptionText": "Secure Communication Platform for Construction Partners",
    "RestrictDirectMessage": "any",
    "RestrictTeamInvite": "all",
    "RestrictPublicChannelManagement": "all",
    "RestrictPrivateChannelManagement": "all",
    "RestrictPublicChannelCreation": "all",
    "RestrictPrivateChannelCreation": "all",
    "RestrictPublicChannelDeletion": "all",
    "RestrictPrivateChannelDeletion": "all",
    "RestrictPrivateChannelManageMembers": "all",
    "EnableXToLeaveChannelsFromLHS": false,
    "UserStatusAwayTimeout": 300,
    "MaxChannelsPerTeam": 2000,
    "MaxNotificationsPerChannel": 1000,
    "EnableConfirmNotificationsToChannel": true,
    "TeammateNameDisplay": "username",
    "ExperimentalViewArchivedChannels": false,
    "ExperimentalEnableAutomaticReplies": false,
    "ExperimentalHideTownSquareinLHS": false,
    "ExperimentalTownSquareIsReadOnly": false,
    "LockTeammateNameDisplay": false,
    "ExperimentalPrimaryTeam": "",
    "ExperimentalDefaultChannels": []
  },
  "SqlSettings": {
    "DriverName": "postgres",
    "DataSource": "postgres://bauportal:secure_password@postgres:5432/bauportal_db?sslmode=disable&connect_timeout=10",
    "DataSourceReplicas": [],
    "DataSourceSearchReplicas": [],
    "MaxIdleConns": 20,
    "ConnMaxLifetimeMilliseconds": 3600000,
    "MaxOpenConns": 300,
    "Trace": false,
    "AtRestEncryptKey": ""
  },
  "LogSettings": {
    "EnableConsole": true,
    "ConsoleLevel": "INFO",
    "ConsoleJson": true,
    "EnableFile": true,
    "FileLevel": "INFO",
    "FileJson": true,
    "FileLocation": "",
    "EnableWebhookDebugging": true,
    "EnableDiagnostics": true
  },
  "EmailSettings": {
    "EnableSignUpWithEmail": true,
    "EnableSignInWithEmail": true,
    "EnableSignInWithUsername": true,
    "SendEmailNotifications": false,
    "UseChannelInEmailNotifications": false,
    "RequireEmailVerification": false,
    "FeedbackName": "",
    "FeedbackEmail": "",
    "ReplyToAddress": "",
    "FeedbackOrganization": "",
    "EnableSMTPAuth": false,
    "SMTPUsername": "",
    "SMTPPassword": "",
    "SMTPServer": "",
    "SMTPPort": "",
    "ConnectionSecurity": "",
    "SendPushNotifications": true,
    "PushNotificationServer": "https://push.bau-portal.online",
    "PushNotificationContents": "generic",
    "EnableEmailBatching": false,
    "EmailBatchingBufferSize": 256,
    "EmailBatchingInterval": 30,
    "EnablePreviewModeBanner": true,
    "SkipServerCertificateVerification": false,
    "EmailNotificationContentsType": "full",
    "LoginButtonColor": "",
    "LoginButtonBorderColor": "",
    "LoginButtonTextColor": ""
  },
  "FileSettings": {
    "EnableFileAttachments": true,
    "EnableMobileUpload": true,
    "EnableMobileDownload": true,
    "MaxFileSize": 52428800,
    "DriverName": "local",
    "Directory": "./data/",
    "EnablePublicLink": false,
    "PublicLinkSalt": "",
    "InitialFont": "nunito-bold.ttf",
    "AmazonS3AccessKeyId": "",
    "AmazonS3SecretAccessKey": "",
    "AmazonS3Bucket": "",
    "AmazonS3Region": "",
    "AmazonS3Endpoint": "",
    "AmazonS3SSL": true,
    "AmazonS3SignV2": false,
    "AmazonS3SSE": false,
    "AmazonS3Trace": false
  }
}
EOF
    
    # Replace default config with Bau-Portal config
    cp config/bau-portal-config.json config/config.json
    
    print_status "✅ Bau-Portal customization completed"
    
    cd ../../..
}

# Create Docker image
create_docker_image() {
    if command -v docker &> /dev/null; then
        print_status "Creating Docker image..."
        
        # Create Dockerfile for Bau-Portal
        cat > Dockerfile.bau-portal << 'EOF'
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    curl

# Create mattermost user
RUN addgroup -g 2000 mattermost && \
    adduser -D -u 2000 -G mattermost -h /mattermost -s /bin/sh mattermost

# Copy Mattermost from build
COPY server/dist/mattermost /mattermost

# Set ownership
RUN chown -R mattermost:mattermost /mattermost

# Switch to mattermost user
USER mattermost

# Set working directory
WORKDIR /mattermost

# Health check
HEALTHCHECK --interval=30s --timeout=10s \
  CMD curl -f http://localhost:8065/api/v4/system/ping || exit 1

# Expose ports
EXPOSE 8065 8067 8074 8075

# Start Mattermost
CMD ["./bin/mattermost"]
EOF
        
        # Build Docker image
        docker build -f Dockerfile.bau-portal -t bau-portal:latest .
        
        if [ $? -eq 0 ]; then
            print_status "✅ Docker image created: bau-portal:latest"
        else
            print_warning "Docker image creation failed"
        fi
        
        # Clean up
        rm Dockerfile.bau-portal
    else
        print_warning "Docker not found, skipping image creation"
    fi
}

# Verify build
verify_build() {
    print_status "Verifying build..."
    
    cd server/dist/mattermost
    
    # Check binary
    if [ -x "bin/mattermost" ]; then
        VERSION=$(./bin/mattermost version 2>/dev/null || echo "unknown")
        print_status "✅ Mattermost binary: $VERSION"
    else
        print_error "Mattermost binary not found or not executable"
        exit 1
    fi
    
    # Check mmctl
    if [ -x "bin/mmctl" ]; then
        print_status "✅ mmctl binary found"
    else
        print_warning "mmctl binary not found"
    fi
    
    # Check webapp
    if [ -d "client" ] && [ -f "client/main.*.js" ]; then
        print_status "✅ Webapp files found"
    else
        print_error "Webapp files not found"
        exit 1
    fi
    
    # Check config
    if [ -f "config/config.json" ]; then
        print_status "✅ Configuration file found"
    else
        print_error "Configuration file not found"
        exit 1
    fi
    
    cd ../../..
}

# Main execution
main() {
    print_header
    
    # Check if we're in the right directory
    if [ ! -f "server/Makefile" ] || [ ! -f "webapp/Makefile" ]; then
        print_error "Please run this script from the mattermost root directory"
        exit 1
    fi
    
    check_prerequisites
    setup_environment
    build_webapp
    build_server
    create_package
    customize_bau_portal
    create_docker_image
    verify_build
    
    print_status ""
    print_status "🎉 Bau-Portal build completed successfully!"
    print_status ""
    print_status "📦 Package: server/dist/mattermost-team-linux-amd64.tar.gz"
    print_status "📁 Directory: server/dist/mattermost/"
    print_status "🐳 Docker: bau-portal:latest (if Docker available)"
    print_status ""
    print_status "🚀 To deploy:"
    print_status "   1. Extract: tar -xzf server/dist/mattermost-team-linux-amd64.tar.gz"
    print_status "   2. Configure: Edit config/config.json as needed"
    print_status "   3. Run: ./bin/mattermost"
    print_status ""
}

# Run main function
main "$@"
