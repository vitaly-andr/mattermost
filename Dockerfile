# Multi-stage Dockerfile for building Mattermost from source
# Optimized for ARM64 architecture

# Stage 1: Build webapp
FROM node:20-alpine AS webapp-builder

WORKDIR /build

# Install dependencies for native modules
RUN apk add --no-cache python3 make g++ git

# Copy webapp package files
COPY webapp/package*.json ./webapp/
COPY package*.json ./

# Install webapp dependencies
WORKDIR /build/webapp
RUN npm ci --no-optional --production=false

# Copy webapp source
COPY webapp/ ./

# Build webapp
RUN npm run build

# Stage 2: Build server
FROM golang:1.24-alpine AS server-builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache git make ca-certificates tzdata

# Copy go modules for dependency caching
COPY go.mod go.sum ./
COPY server/go.mod server/go.sum ./server/
COPY public/go.mod public/go.sum ./public/

# Download dependencies
WORKDIR /build/server
RUN go mod download

# Copy all source code
COPY . /build/

# Copy built webapp from previous stage
COPY --from=webapp-builder /build/dist /build/webapp/dist/

# Build server and tools
WORKDIR /build/server
RUN make prepackaged-binaries
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
    -ldflags '-X "github.com/mattermost/mattermost/server/public/model.BuildNumber=production" \
             -X "github.com/mattermost/mattermost/server/public/model.BuildDate='$(date -u)'" \
             -X "github.com/mattermost/mattermost/server/public/model.BuildHash='$(git rev-parse HEAD)'"' \
    -o mattermost ./cmd/mattermost

# Stage 3: Runtime
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    curl \
    jq \
    && update-ca-certificates

# Create mattermost user
RUN addgroup -g 2000 mattermost && \
    adduser -D -u 2000 -G mattermost -h /mattermost -s /bin/sh mattermost

# Create directories
RUN mkdir -p /mattermost/{data,logs,plugins,client,config,bin} && \
    chown -R mattermost:mattermost /mattermost

# Copy built binaries
COPY --from=server-builder --chown=mattermost:mattermost /build/server/mattermost /mattermost/bin/
COPY --from=server-builder --chown=mattermost:mattermost /build/server/bin/mmctl /mattermost/bin/

# Copy webapp
COPY --from=webapp-builder --chown=mattermost:mattermost /build/dist /mattermost/client/

# Copy default config
COPY --from=server-builder --chown=mattermost:mattermost /build/config /mattermost/config/

# Switch to mattermost user
USER mattermost

# Set working directory
WORKDIR /mattermost

# Expose port
EXPOSE 8065

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8065/api/v4/system/ping || exit 1

# Start Mattermost
CMD ["./bin/mattermost"]
