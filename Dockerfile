# Wrapper Dockerfile - используем официальный образ как есть
FROM mattermost/mattermost-enterprise-edition:latest

# Никаких RUN команд - distroless не поддерживает shell
# Просто используем образ как есть с возможностью добавить файлы

# Можем только копировать файлы (если нужно)
# COPY config/custom-config.json /mattermost/config/
# COPY plugins/ /mattermost/plugins/

# Используем стандартную команду запуска
CMD ["/mattermost/bin/mattermost"]
