# Multi-stage Dockerfile for building Mattermost from source
# For Intel/AMD64 architecture

# Stage 1: Build custom webapp
FROM node:20-alpine AS webapp-builder

WORKDIR /build

# Install dependencies for native modules
RUN apk add --no-cache python3 make g++ git

# Copy YOUR custom webapp source code
COPY webapp/ ./webapp/

# Install webapp dependencies and build
WORKDIR /build/webapp
RUN npm install

# Build YOUR custom webapp
RUN npm run build

# Stage 2: Build custom server
FROM golang:1.24-alpine AS server-builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache git make ca-certificates tzdata

# Copy go modules for dependency caching
COPY server/go.mod server/go.sum ./server/
COPY server/public/go.mod server/public/go.sum ./public/

# Download dependencies
WORKDIR /build/server
RUN go mod download

# Copy YOUR custom source code
COPY . /build/

# Copy YOUR custom built webapp from previous stage
COPY --from=webapp-builder /build/webapp/channels/dist /build/webapp/channels/dist/

# Build YOUR custom server for AMD64
WORKDIR /build/server
RUN make prepackaged-binaries
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags '-X "github.com/mattermost/mattermost/server/public/model.BuildNumber=production" \
             -X "github.com/mattermost/mattermost/server/public/model.BuildDate='$(date -u)'" \
             -X "github.com/mattermost/mattermost/server/public/model.BuildHash='$(git rev-parse HEAD)'"' \
    -o mattermost ./cmd/mattermost

# Stage 3: Runtime with YOUR custom build
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

# Copy YOUR custom built binaries
COPY --from=server-builder --chown=mattermost:mattermost /build/server/mattermost /mattermost/bin/
COPY --from=server-builder --chown=mattermost:mattermost /build/server/bin/mmctl /mattermost/bin/

# Copy YOUR custom webapp
COPY --from=webapp-builder --chown=mattermost:mattermost /build/webapp/channels/dist /mattermost/client/

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
