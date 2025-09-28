# Официальная инструкция по сборке Mattermost для Production

## 🎯 Основано на официальной документации Mattermost

### Источники:
- `server/Makefile` - официальные команды сборки
- `webapp/Makefile` - сборка веб-приложения  
- `server/build/release.mk` - production сборка
- `server/build/Dockerfile` - официальный Docker образ

## 📋 1. Системные требования

### Зависимости:
```bash
# Go (минимум 1.15, рекомендуется 1.22+)
go version

# Node.js (для webapp)
node --version  # рекомендуется 20+
npm --version

# Make
make --version

# Docker (опционально)
docker --version
```

## 🏗️ 2. Официальная сборка из исходников

### A. Полная сборка (сервер + веб-приложение)

```bash
# Из корневой директории mattermost
cd /Users/vitaly/Development/mattermost

# 1. Настройка Go workspace (если есть enterprise)
make setup-go-work

# 2. Полная сборка (по умолчанию Linux)
make build

# Или для конкретной платформы:
make build-linux    # Linux AMD64
make build-osx      # macOS
make build-windows  # Windows
```

### B. Поэтапная сборка

#### Сборка веб-приложения:
```bash
cd webapp
make dist
# Результат: webapp/channels/dist/
```

#### Сборка сервера:
```bash
cd server
make build-linux
# Результат: server/dist/mattermost/bin/mattermost
```

### C. Production сборка с оптимизациями

```bash
cd server

# Production сборка с тегами
BUILD_TAGS="production" make build-linux

# Или с дополнительными параметрами
BUILD_NUMBER="1.0.0" \
BUILD_ENTERPRISE=true \
BUILD_TAGS="production" \
make build-linux
```

## 📦 3. Создание дистрибутива

### Официальная команда packaging:

```bash
cd server

# Подготовка пакета
make package-prep

# Создание tar.gz архива
make package-linux

# Результат: server/dist/mattermost-team-linux-amd64.tar.gz
```

### Структура пакета:
```
mattermost/
├── bin/
│   ├── mattermost          # Основной бинарник
│   └── mmctl              # CLI утилита
├── config/
│   └── config.json        # Конфигурация по умолчанию
├── fonts/                 # Шрифты
├── i18n/                  # Переводы
├── templates/             # Email шаблоны
└── client/                # Веб-приложение
    ├── static/
    └── *.html
```

## 🐳 4. Docker сборка (официальный способ)

### Использование официального Dockerfile:

```bash
# Из корневой директории
docker build -f server/build/Dockerfile -t bau-portal:latest .

# С кастомными параметрами
docker build \
  --build-arg MM_PACKAGE="https://latest.mattermost.com/mattermost-enterprise-linux" \
  --build-arg PUID=2000 \
  --build-arg PGID=2000 \
  -f server/build/Dockerfile \
  -t bau-portal:latest .
```

### Многоэтапная сборка из исходников:

```dockerfile
# Dockerfile.bau-portal
FROM node:20-alpine AS webapp-builder
WORKDIR /webapp
COPY webapp/ .
RUN make dist

FROM golang:1.22-alpine AS server-builder
WORKDIR /server
COPY server/ .
COPY --from=webapp-builder /webapp/channels/dist /webapp/channels/dist
RUN BUILD_TAGS="production" make build-linux

FROM alpine:3.19
RUN apk add --no-cache ca-certificates tzdata
COPY --from=server-builder /server/dist/mattermost /mattermost
WORKDIR /mattermost
EXPOSE 8065
CMD ["./bin/mattermost"]
```

## 🔧 5. Конфигурация для Bau-Portal

### Создание кастомной конфигурации:

```bash
cd server

# Генерация базовой конфигурации
OUTPUT_CONFIG=$(pwd)/config/bau-portal-config.json \
go run ./scripts/config_generator

# Или копирование и модификация
cp config/config.json config/bau-portal-config.json
```

### Основные настройки для Bau-Portal:
```json
{
  "ServiceSettings": {
    "SiteURL": "https://chat.bau-portal.online",
    "ListenAddress": ":8065",
    "EnableLocalMode": false
  },
  "TeamSettings": {
    "SiteName": "Bau-Portal",
    "EnableCustomBrand": true,
    "CustomBrandText": "Bau-Portal",
    "CustomDescriptionText": "Secure Communication Platform for Construction Partners"
  },
  "SqlSettings": {
    "DriverName": "postgres",
    "DataSource": "postgres://bauportal:password@postgres:5432/bauportal_db?sslmode=disable"
  },
  "EmailSettings": {
    "PushNotificationServer": "https://push.bau-portal.online"
  }
}
```

## 🚀 6. Развертывание

### A. Прямое развертывание

```bash
# Распаковка собранного пакета
tar -xzf server/dist/mattermost-team-linux-amd64.tar.gz

# Настройка конфигурации
cp config/bau-portal-config.json mattermost/config/config.json

# Запуск
cd mattermost
./bin/mattermost
```

### B. Docker Compose (официальный способ)

```yaml
# docker-compose.yml (на основе официального)
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: mattermost
      POSTGRES_USER: mmuser
      POSTGRES_PASSWORD: mmuser_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mattermost:
    image: bau-portal:latest
    depends_on:
      - postgres
    environment:
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: "postgres://mmuser:mmuser_password@postgres:5432/mattermost?sslmode=disable"
      MM_SERVICESETTINGS_SITEURL: "https://chat.bau-portal.online"
      MM_TEAMSETTINGS_SITENAME: "Bau-Portal"
    ports:
      - "8065:8065"
    volumes:
      - mattermost_data:/mattermost/data
      - mattermost_logs:/mattermost/logs
      - mattermost_config:/mattermost/config

volumes:
  postgres_data:
  mattermost_data:
  mattermost_logs:
  mattermost_config:
```

## 🔍 7. Проверка сборки

### Тестирование собранного приложения:

```bash
# Проверка версии
./bin/mattermost version

# Проверка конфигурации
./bin/mmctl config get --local

# Тест запуска
./bin/mattermost --config=config/config.json
```

### Проверка веб-приложения:
```bash
# Проверка статических файлов
ls -la client/
curl -I http://localhost:8065/static/main.*.js
```

## 📝 8. Автоматизация сборки

### Скрипт на основе официальных команд:

```bash
#!/bin/bash
# build-production.sh

set -e

echo "🏗️ Building Bau-Portal for Production..."

# Проверка зависимостей
command -v go >/dev/null 2>&1 || { echo "Go is required"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Node.js is required"; exit 1; }
command -v make >/dev/null 2>&1 || { echo "Make is required"; exit 1; }

# Настройка переменных
export BUILD_NUMBER="${BUILD_NUMBER:-1.0.0}"
export BUILD_ENTERPRISE="${BUILD_ENTERPRISE:-false}"
export BUILD_TAGS="production"

echo "📦 Building webapp..."
cd webapp
make dist
cd ..

echo "🔧 Building server..."
cd server
make build-linux
cd ..

echo "📋 Creating package..."
cd server
make package-prep
make package-linux
cd ..

echo "✅ Build completed!"
echo "📁 Package: server/dist/mattermost-team-linux-amd64.tar.gz"
```

## 🎯 9. Отличия от кастомного подхода

### ✅ Преимущества официального способа:
- **Проверенный процесс** - используется самой командой Mattermost
- **Все зависимости** включены автоматически
- **Правильная структура** директорий и файлов
- **Production оптимизации** включены по умолчанию
- **Совместимость** с официальными обновлениями

### ❌ Проблемы кастомного подхода:
- Неправильные пути к статическим файлам
- Отсутствующие зависимости
- Неоптимизированная сборка
- Проблемы с правами доступа
- Несовместимость с официальными инструментами

## 🔧 10. Кастомизация для Bau-Portal

### После официальной сборки можно:

1. **Заменить статические файлы**:
```bash
# Логотипы и иконки
cp bau-portal-logo.png mattermost/client/images/
cp bau-portal-favicon.ico mattermost/client/
```

2. **Модифицировать конфигурацию**:
```bash
# Брендинг в config.json
jq '.TeamSettings.SiteName = "Bau-Portal"' config.json > config.tmp
mv config.tmp config.json
```

3. **Добавить кастомные плагины**:
```bash
cp bau-portal-plugin.tar.gz mattermost/plugins/
```

---

## 🎯 Заключение

**Используйте ТОЛЬКО официальные команды сборки Mattermost:**

1. `make build` - для полной сборки
2. `make package-linux` - для создания дистрибутива  
3. Официальный `Dockerfile` - для Docker образов

**Не изобретайте велосипед** - официальная сборка протестирована и работает надежно!
