# Wrapper Dockerfile - используем официальный образ как базу
FROM mattermost/mattermost-enterprise-edition:latest

# Добавляем свои кастомизации
USER root

# Устанавливаем дополнительные пакеты (если нужно)
RUN apk add --no-cache \
    curl \
    jq \
    htop

# Копируем свои конфиги (если есть)
# COPY config/custom-config.json /mattermost/config/

# Копируем свои плагины (если есть)
# COPY plugins/ /mattermost/plugins/

# Копируем свои темы/кастомизации (если есть)
# COPY themes/ /mattermost/client/

# Возвращаемся к пользователю mattermost
USER mattermost

# Используем стандартную команду запуска
CMD ["mattermost"]
