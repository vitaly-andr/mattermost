# Multi-arch заглушка для Kamal
# Работает на AMD64 и ARM64
FROM alpine:3.19

# Установим базовые пакеты
RUN apk add --no-cache \
    curl \
    ca-certificates

# Создаем пользователя
RUN addgroup -g 2000 app && \
    adduser -D -u 2000 -G app -h /app -s /bin/sh app

# Создаем директории
RUN mkdir -p /app/data /app/logs && \
    chown -R app:app /app

USER app
WORKDIR /app

# Простой health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD echo "OK"

# Заглушка - просто спим
CMD ["sleep", "infinity"]
