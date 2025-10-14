# Sputnik-school Mattermost - wrapper over official Enterprise Edition
FROM mattermost/mattermost-enterprise-edition:latest

# Switch to root for customizations
USER root

# Install additional tools for debugging/management
RUN apk add --no-cache \
    curl \
    jq \
    htop \
    nano

# Copy custom configurations (if needed)
# COPY config/sputnik-school-config.json /mattermost/config/
# COPY plugins/ /mattermost/plugins/
# COPY themes/ /mattermost/client/

# Switch back to mattermost user
USER mattermost

# Use standard startup command
CMD ["/mattermost/bin/mattermost"]
